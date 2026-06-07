# ==========================================================
# RISC-V RV32I Test Program for Memory Operations and SPI
# ==========================================================

.text
.globl _start

_start:
    # 1. SPI Base Address Initialization
    addi x17, x0, 0x400  # PC: 0x00 | SPI Base Address x17 = 0x400 (0x40000893)
    
    # 2. Transaction 1: txlength = 3, rxlength = 0, txdata = 0x00022D0A
    addi x18, x0, 3      # PC: 0x04 | x18 = 3 (0x00300913)
    sb x18, 4(x17)       # PC: 0x08 | ADDR_TX_LENGTH = 3 (0x01288223)
    sb x0, 5(x17)        # PC: 0x0C | ADDR_RX_LENGTH = 0 (0x000882A3)
    
    lui x20, 0x00023     # PC: 0x10 | Upper bits (0x00023A37)
    addi x20, x20, -758  # PC: 0x14 | Lower bits (D0AA0A13)
    sw x20, 0(x17)       # PC: 0x18 | ADDR_TX_DATA = 0x00022D0A (0x01488023)
    
    addi x19, x0, 1      # PC: 0x1C | x19 = 1 (0x00100993)
    sb x19, 6(x17)       # PC: 0x20 | ADDR_X_START = 1 (Starts transaction) (0x01388323)

    # 3. Parameter Setup (once before the loop)
    addi x18, x0, 2      # PC: 0x24 | x18 = 2 (0x00200913)
    sb x18, 4(x17)       # PC: 0x28 | ADDR_TX_LENGTH = 2 (0x01288223)
    sb x18, 5(x17)       # PC: 0x2C | ADDR_RX_LENGTH = 2 (0x012882A3)

    # 4. Endless Loop of 3 SPI Transactions (A, B, C)
loop_start:
    # --- TRANSACTION A: txdata = 0x00000e0b, result -> reg8 (x8) ---
    lui x20, 1           # PC: 0x30 | x20 = 4096 (00001A37)
    addi x20, x20, -501  # PC: 0x34 | x20 = 0x00000e0b (E0BA0A13)
    sw x20, 0(x17)       # PC: 0x38 | ADDR_TX_DATA = 0x00000e0b (01488023)
    sb x19, 6(x17)       # PC: 0x3C | ADDR_X_START = 1 (Starts transaction) (01388323)
    lw x8, 8(x17)        # PC: 0x40 | x8 = ADDR_RX_DATA (result) (0088A403)

    # --- TRANSACTION B: txdata = 0x0000100b, result -> reg9 (x9) ---
    lui x20, 1           # PC: 0x44 | x20 = 4096 (00001A37)
    addi x20, x20, 11    # PC: 0x48 | x20 = 0x0000100b (00BA0A13)
    sw x20, 0(x17)       # PC: 0x4C | ADDR_TX_DATA = 0x0000100b (01488023)
    sb x19, 6(x17)       # PC: 0x50 | ADDR_X_START = 1 (Starts transaction) (01388323)
    lw x9, 8(x17)        # PC: 0x54 | x9 = ADDR_RX_DATA (result) (0088A483)

    # --- TRANSACTION C: txdata = 0x0000120b, result -> reg10 (x10) ---
    lui x20, 1           # PC: 0x58 | x20 = 4096 (00001A37)
    addi x20, x20, 523   # PC: 0x5C | x20 = 0x0000120b (20BA0A13)
    sw x20, 0(x17)       # PC: 0x60 | ADDR_TX_DATA = 0x0000120b (01488023)
    sb x19, 6(x17)       # PC: 0x64 | ADDR_X_START = 1 (Starts transaction) (01388323)
    lw x10, 8(x17)       # PC: 0x68 | x10 = ADDR_RX_DATA (result) (0088A503)

    # Loop back infinitely to loop_start (Transaction A)
    jal x0, loop_start   # PC: 0x6C | Jump back to loop_start (fc5ff06f)
