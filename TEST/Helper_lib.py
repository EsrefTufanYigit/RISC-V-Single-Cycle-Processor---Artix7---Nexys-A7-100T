import logging
from tabulate import tabulate
from cocotb.types import LogicArray

def read_file_to_list(filename):
    with open(filename, 'r') as file:
        lines = [line.strip() for line in file.readlines()]
    return lines

def sign_extend(val, bits):
    if (val & (1 << (bits - 1))) != 0:
        val = val - (1 << bits)
    return val

class Instruction:
    def __init__(self, inst_int: int):
        self.inst_int = inst_int
        
        # Base fields
        self.opcode = inst_int & 0x7F
        self.rd     = (inst_int >> 7) & 0x1F
        self.funct3 = (inst_int >> 12) & 0x7
        self.rs1    = (inst_int >> 15) & 0x1F
        self.rs2    = (inst_int >> 20) & 0x1F
        self.funct7 = (inst_int >> 25) & 0x7F
        
        # Immediate decodings
        self.imm_I = sign_extend((inst_int >> 20) & 0xFFF, 12)
        self.imm_S = sign_extend(((inst_int >> 25) << 5) | ((inst_int >> 7) & 0x1F), 12)
        
        imm_b_12 = (inst_int >> 31) & 0x1
        imm_b_11 = (inst_int >> 7) & 0x1
        imm_b_10_5 = (inst_int >> 25) & 0x3F
        imm_b_4_1 = (inst_int >> 8) & 0xF
        self.imm_B = sign_extend((imm_b_12 << 12) | (imm_b_11 << 11) | (imm_b_10_5 << 5) | (imm_b_4_1 << 1), 13)
        
        self.imm_U = inst_int & 0xFFFFF000
        
        imm_j_20 = (inst_int >> 31) & 0x1
        imm_j_19_12 = (inst_int >> 12) & 0xFF
        imm_j_11 = (inst_int >> 20) & 0x1
        imm_j_10_1 = (inst_int >> 21) & 0x3FF
        self.imm_J = sign_extend((imm_j_20 << 20) | (imm_j_19_12 << 12) | (imm_j_11 << 11) | (imm_j_10_1 << 1), 21)

class ByteAddressableMemory:
    def __init__(self, size):
        self.size = size
        self.memory = bytearray(size)

    def read_word(self, address):
        if address < 0 or address + 4 > self.size:
            return 0 
        return int.from_bytes(self.memory[address:address+4], byteorder='little')

    def write_word(self, address, data):
        if address < 0 or address + 4 > self.size:
            return 
        self.memory[address:address+4] = data.to_bytes(4, byteorder='little', signed=(data < 0))
        
    def write_half(self, address, data):
        if address < 0 or address + 2 > self.size:
            return
        self.memory[address:address+2] = (data & 0xFFFF).to_bytes(2, byteorder='little')
        
    def write_byte(self, address, data):
        if address < 0 or address + 1 > self.size:
            return
        self.memory[address:address+1] = (data & 0xFF).to_bytes(1, byteorder='little')