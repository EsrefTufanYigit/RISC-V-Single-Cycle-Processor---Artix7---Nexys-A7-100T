#!/usr/bin/env python3
import random
import sys
import argparse

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

OPCODES = [OP_R, OP_I_ALU, OP_LOAD, OP_STORE, OP_BRANCH, OP_JAL, OP_JALR, OP_LUI, OP_AUIPC]

def generate_instruction(opcode: int, inst_index: int) -> int:
    """
    Generates a single valid, random 32-bit RISC-V instruction for a given opcode.
    Uses safe register indices, memory offsets, and jump targets.
    """
    # Random registers: rd (usually 1-31 to ensure state updates), rs1, rs2
    rd = random.randint(1, 31)
    rs1 = random.randint(0, 31)
    rs2 = random.randint(0, 31)
    
    if opcode == OP_R:
        # Choose a valid R-type operation
        # (funct3, funct7)
        r_ops = [
            (0x0, 0x00), # ADD
            (0x0, 0x20), # SUB
            (0x1, 0x00), # SLL
            (0x2, 0x00), # SLT
            (0x3, 0x00), # SLTU
            (0x4, 0x00), # XOR
            (0x5, 0x00), # SRL
            (0x5, 0x20), # SRA
            (0x6, 0x00), # OR
            (0x7, 0x00)  # AND
        ]
        funct3, funct7 = random.choice(r_ops)
        return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | OP_R

    elif opcode == OP_I_ALU:
        funct3 = random.choice([0, 1, 2, 3, 4, 5, 6, 7])
        if funct3 == 1:
            imm = random.randint(0, 31) # shamt
        elif funct3 == 5:
            shamt = random.randint(0, 31)
            is_sra = random.choice([True, False])
            imm = shamt | (0x20 << 5) if is_sra else shamt
        else:
            imm = random.randint(0, 4095) # 12-bit immediate
            
        return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | OP_I_ALU

    elif opcode == OP_LOAD:
        # Load types: LB (0x0), LH (0x1), LW (0x2)
        funct3 = random.choice([0, 1, 2])
        # Use rs1 = 0 (constant 0 register) to guarantee known memory base
        rs1 = 0
        
        # Alignment constraints
        if funct3 == 2:
            imm = 4 * random.randint(0, 255) # Word aligned (LW)
        elif funct3 == 1:
            imm = 2 * random.randint(0, 511) # Halfword aligned (LH)
        else:
            imm = random.randint(0, 1023)    # Byte aligned (LB)
            
        return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | OP_LOAD

    elif opcode == OP_STORE:
        # Store types: SB (0x0), SH (0x1), SW (0x2)
        funct3 = random.choice([0, 1, 2])
        # Use rs1 = 0 (constant 0 register) to guarantee known memory base
        rs1 = 0
        
        # Alignment constraints
        if funct3 == 2:
            imm = 4 * random.randint(0, 255) # Word aligned
        elif funct3 == 1:
            imm = 2 * random.randint(0, 511) # Halfword aligned
        else:
            imm = random.randint(0, 1023)    # Byte aligned
            
        imm_11_5 = (imm >> 5) & 0x7F
        imm_4_0 = imm & 0x1F
        return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | OP_STORE

    elif opcode == OP_BRANCH:
        # Comparison types: BEQ (0), BNE (1), BLT (4), BGE (5), BLTU (6), BGEU (7)
        funct3 = random.choice([0, 1, 4, 5, 6, 7])
        # Set imm = 4 to branch to the next instruction safely whether taken or not
        imm = 4
        
        imm_u13 = imm & 0x1FFF
        imm_12 = (imm_u13 >> 12) & 0x1
        imm_11 = (imm_u13 >> 11) & 0x1
        imm_10_5 = (imm_u13 >> 5) & 0x3F
        imm_4_1 = (imm_u13 >> 1) & 0xF
        return (imm_12 << 31) | (imm_10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_1 << 8) | (imm_11 << 7) | OP_BRANCH

    elif opcode == OP_JAL:
        # Set imm = 4 to jump to the next instruction safely
        imm = 4
        
        imm_u21 = imm & 0x1FFFFF
        imm_20 = (imm_u21 >> 20) & 0x1
        imm_19_12 = (imm_u21 >> 12) & 0xFF
        imm_11 = (imm_u21 >> 11) & 0x1
        imm_10_1 = (imm_u21 >> 1) & 0x3FF
        return (imm_20 << 31) | (imm_10_1 << 21) | (imm_11 << 20) | (imm_19_12 << 12) | (rd << 7) | OP_JAL

    elif opcode == OP_JALR:
        funct3 = 0
        # Use rs1 = 0 (constant 0 register)
        rs1 = 0
        # Set imm = (inst_index + 1) * 4 to always jump to the next physical instruction
        imm = (inst_index + 1) * 4
        return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | OP_JALR

    elif opcode == OP_LUI:
        imm_u20 = random.randint(0, 0xFFFFF)
        return (imm_u20 << 12) | (rd << 7) | OP_LUI

    elif opcode == OP_AUIPC:
        imm_u20 = random.randint(0, 0xFFFFF)
        return (imm_u20 << 12) | (rd << 7) | OP_AUIPC

    else:
        raise ValueError(f"Unknown Opcode: {hex(opcode)}")

def main():
    parser = argparse.ArgumentParser(description="Generate random RV32I instructions in hexadecimal format.")
    parser.add_argument("-n", "--count", type=int, default=50, help="Number of instructions to generate (default: 50)")
    parser.add_argument("-o", "--output", type=str, default="ins_data2.mem", help="Output file path (default: ins_data2.mem)")
    args = parser.parse_args()

    print(f"Generating {args.count} random RV32I instructions...")
    instructions = []
    
    for i in range(args.count):
        actual_index = i 
        # Pick random opcode (exclude OP_JALR after index 500 to avoid 12-bit signed immediate overflow)
        if actual_index >= 500:
            allowed_opcodes = [op for op in OPCODES if op != OP_JALR]
        else:
            allowed_opcodes = OPCODES
            
        opcode = random.choice(allowed_opcodes)
        inst_int = generate_instruction(opcode, actual_index)
        instructions.append(inst_int)

    # Write instructions to file line by line as 8-character hex
    with open(args.output, "w") as f:
        for idx, inst in enumerate(instructions):
            # Print hex formatted to 8 lowercase characters
            hex_str = f"{inst:08x}"
            f.write(f"{hex_str}\n")
            
    print(f"Successfully wrote {args.count} instructions to {args.output}")

if __name__ == "__main__":
    main()
