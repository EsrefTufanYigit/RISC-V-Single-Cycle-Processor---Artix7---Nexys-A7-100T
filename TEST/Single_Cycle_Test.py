import logging
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from tabulate import tabulate
from Helper_lib import read_file_to_list, Instruction, ByteAddressableMemory

# RISC-V RV32I Opcodes
OP_R       = 0x33
OP_I_ALU   = 0x13
OP_LOAD    = 0x03
OP_STORE   = 0x23
OP_BRANCH  = 0x63
OP_JAL     = 0x6F
OP_JALR    = 0x67
OP_LUI     = 0x37
OP_AUIPC   = 0x17

# Helper for cleaner table outputs
def ToHex(obj):
    try:
        val = int(obj)
        return hex(val)
    except:
        return str(obj)

class RISCV_TB:
    def __init__(self, instruction_list, dut):
        self.dut = dut
        self.instruction_list = instruction_list
        
        self.logger = logging.getLogger("Performance Model")
        self.logger.setLevel(logging.DEBUG)
        
        self.PC = 0
        self.Register_File = [0] * 32
        self.memory = ByteAddressableMemory(4096)
        self.clock_cycle_count = 0

    def write_register(self, reg_num, value):
        if reg_num != 0:
            self.Register_File[reg_num] = value & 0xFFFFFFFF

    def read_register(self, reg_num):
        return self.Register_File[reg_num]

    def log_controller(self):
        """Replicates the 'DUT Controller Signals' table from the screenshot."""
        ctrl = self.dut.ctrl
        try:
            data = [
                ["Instr",      ToHex(ctrl.Instr.value)],
                ["zero_flag",  str(ctrl.zero_flag.value)],
                ["PCSrc",      str(ctrl.PCSrc.value)],
                ["jalr",       str(ctrl.jalr.value)],
                ["reg_write",  str(ctrl.reg_write.value)],
                ["imm_ctrl",   ToHex(ctrl.imm_ctrl.value)],
                ["alu_src_a",  str(ctrl.alu_src_a.value)],
                ["alu_src_b",  str(ctrl.alu_src_b.value)],
                ["alu_ctrl",   ToHex(ctrl.alu_ctrl.value)],
                ["write_mask", ToHex(ctrl.write_mask.value)],
                ["result_src", ToHex(ctrl.result_src.value)]
            ]
            self.logger.debug(f"\n*********** DUT Controller Signals (Cycle {self.clock_cycle_count}) ***********")
            self.logger.debug("\n" + tabulate(data, headers=["Signal", "Current Val"], tablefmt="github"))
        except Exception:
            pass # Skips on Cycle 0 before signals settle

    def compare_result(self):
        """Replicates the 'Performance Model / DUT Data' table from the screenshot."""
        table_data = []
        all_match = True
        dut_pc = int(self.dut.fetchPC.value)
        table_data.append(["PC", self.PC, dut_pc])
        if self.PC != dut_pc:
            all_match = False
            
        for i in range(32): # Shows all 32 RISC-V registers
            dut_reg_val = int(self.dut.dp.register_file.registers[i].value)
            model_reg_val = self.Register_File[i]
            table_data.append([f"Register {i}:", model_reg_val, dut_reg_val])
            
            if model_reg_val != dut_reg_val:
                all_match = False

        self.logger.debug(f"\n*********** Performance Model / DUT Data ***********")
        self.logger.debug("\n" + tabulate(table_data, headers=["Signal", "Expected Val", "Dut Val"], tablefmt="github") + "\n")

        assert all_match, f"Simulation Failed! Discrepancy found on Cycle {self.clock_cycle_count}."

    def performance_model(self):
        """Executes the golden Python model."""
        line_idx = self.PC // 4
        if line_idx >= len(self.instruction_list):
            return False

        inst_hex = self.instruction_list[line_idx].replace(" ", "")
        inst_int = int(inst_hex, 16)
        
        if inst_int == 0:
            return False

        inst = Instruction(inst_int)
        next_pc = self.PC + 4

        if inst.opcode == OP_R:
            val1 = self.read_register(inst.rs1)
            val2 = self.read_register(inst.rs2)
            funct7_5 = (inst.funct7 >> 5) & 0x1
            
            if inst.funct3 == 0x0 and funct7_5 == 0: res = val1 + val2
            elif inst.funct3 == 0x0 and funct7_5 == 1: res = val1 - val2
            elif inst.funct3 == 0x1: res = val1 << (val2 & 0x1F)
            elif inst.funct3 == 0x2: res = 1 if ((val1 ^ 0x80000000) - 0x80000000) < ((val2 ^ 0x80000000) - 0x80000000) else 0
            elif inst.funct3 == 0x4: res = val1 ^ val2
            elif inst.funct3 == 0x5 and funct7_5 == 0: res = val1 >> (val2 & 0x1F)
            elif inst.funct3 == 0x5 and funct7_5 == 1: res = (val1 ^ 0x80000000) - 0x80000000 >> (val2 & 0x1F)
            elif inst.funct3 == 0x6: res = val1 | val2
            elif inst.funct3 == 0x7: res = val1 & val2
            elif inst.funct3 == 0x3: res = 1 if val1 < val2 else 0 
            else: res = 0
            self.write_register(inst.rd, res)

        elif inst.opcode == OP_I_ALU:
            val1 = self.read_register(inst.rs1)
            funct7_5 = (inst.imm_I >> 10) & 0x1
            
            if inst.funct3 == 0x0: res = val1 + inst.imm_I
            elif inst.funct3 == 0x4: res = val1 ^ inst.imm_I
            elif inst.funct3 == 0x6: res = val1 | inst.imm_I
            elif inst.funct3 == 0x7: res = val1 & inst.imm_I
            elif inst.funct3 == 0x1: res = val1 << (inst.imm_I & 0x1F)
            elif inst.funct3 == 0x5 and funct7_5 == 0: res = val1 >> (inst.imm_I & 0x1F)
            elif inst.funct3 == 0x5 and funct7_5 == 1: res = (val1 ^ 0x80000000) - 0x80000000 >> (inst.imm_I & 0x1F)
            elif inst.funct3 == 0x2: res = 1 if ((val1 ^ 0x80000000) - 0x80000000) < inst.imm_I else 0
            elif inst.funct3 == 0x3: res = 1 if val1 < (inst.imm_I & 0xFFFFFFFF) else 0 
            else: res = 0
            self.write_register(inst.rd, res)

        elif inst.opcode == OP_LOAD:
            addr = (self.read_register(inst.rs1) + inst.imm_I) & 0xFFFFFFFF
            if inst.funct3 == 0x2:    # LW (Load Word)
                res = self.memory.read_word(addr)
            elif inst.funct3 == 0x0:  # LB (Load Byte Signed)
                if addr < 0 or addr >= self.memory.size: res_byte = 0
                else: res_byte = self.memory.memory[addr]
                res = (res_byte ^ 0x80) - 0x80
            elif inst.funct3 == 0x1:  # LH (Load Halfword Signed)
                if addr < 0 or addr + 1 >= self.memory.size: res_half = 0
                else: res_half = self.memory.memory[addr] | (self.memory.memory[addr+1] << 8)
                res = (res_half ^ 0x8000) - 0x8000
            elif inst.funct3 == 0x4:  # LBU (Load Byte Unsigned)
                if addr < 0 or addr >= self.memory.size: res = 0
                else: res = self.memory.memory[addr]
            elif inst.funct3 == 0x5:  # LHU (Load Halfword Unsigned)
                if addr < 0 or addr + 1 >= self.memory.size: res = 0
                else: res = self.memory.memory[addr] | (self.memory.memory[addr+1] << 8)
            else:
                res = 0
            self.write_register(inst.rd, res)

        elif inst.opcode == OP_STORE:
            addr = (self.read_register(inst.rs1) + inst.imm_S) & 0xFFFFFFFF
            val2 = self.read_register(inst.rs2)
            if inst.funct3 == 0x2: self.memory.write_word(addr, val2)
            elif inst.funct3 == 0x1: self.memory.write_half(addr, val2)
            elif inst.funct3 == 0x0: self.memory.write_byte(addr, val2)

        elif inst.opcode == OP_BRANCH:
            val1 = self.read_register(inst.rs1)
            val2 = self.read_register(inst.rs2)
            take = False
            
            if inst.funct3 == 0x0: take = (val1 == val2)
            elif inst.funct3 == 0x1: take = (val1 != val2)
            elif inst.funct3 == 0x4: take = ((val1 ^ 0x80000000) - 0x80000000) < ((val2 ^ 0x80000000) - 0x80000000)
            elif inst.funct3 == 0x5: take = ((val1 ^ 0x80000000) - 0x80000000) >= ((val2 ^ 0x80000000) - 0x80000000)
            elif inst.funct3 == 0x6: take = val1 < val2
            elif inst.funct3 == 0x7: take = val1 >= val2
            
            if take: next_pc = self.PC + inst.imm_B

        elif inst.opcode == OP_JAL:
            self.write_register(inst.rd, next_pc)
            next_pc = self.PC + inst.imm_J

        elif inst.opcode == OP_JALR:
            self.write_register(inst.rd, next_pc)
            next_pc = (self.read_register(inst.rs1) + inst.imm_I) & ~1

        elif inst.opcode == OP_LUI:
            self.write_register(inst.rd, inst.imm_U)

        elif inst.opcode == OP_AUIPC:
            self.write_register(inst.rd, self.PC + inst.imm_U)

        # Trap infinite loops (e.g. JAL x0, 0 at the end of the file)
        if self.PC == next_pc:
            self.logger.info(f"[PROGRAM HALT] Infinite loop detected at PC {hex(self.PC)}. Ending gracefully.")
            return False

        self.PC = next_pc & 0xFFFFFFFF
        self.clock_cycle_count += 1
        return True

    async def run_test(self):
        await Timer(1, unit="us")
        
        while True:
            execute_ok = self.performance_model()
            if not execute_ok:
                break
                
            await RisingEdge(self.dut.clk)
            self.log_controller()  # Logs internal signals just before clock falls
            
            await FallingEdge(self.dut.clk)
            self.compare_result()  # Compares registers after clock falls

@cocotb.test()
async def Single_cycle_test(dut):
    Clock(dut.clk, 10, unit="us").start()
    
    dut.reset.value = 1
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await FallingEdge(dut.clk)
    
    instruction_lines = read_file_to_list('ins_data2.mem')
    tb = RISCV_TB(instruction_lines, dut)
    await tb.run_test()