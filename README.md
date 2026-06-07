# Single-Cycle RISC-V Processor with Memory-Mapped SPI

![RISC-V](https://img.shields.io/badge/RISC--V-RV32I-blue.svg)
![Verilog](https://img.shields.io/badge/Language-Verilog-green.svg)
![FPGA](https://img.shields.io/badge/FPGA-Nexys%20A7--100T-orange.svg)
![Verification](https://img.shields.io/badge/Verification-Cocotb-yellow.svg)

[cite_start]This repository contains the RTL design and verification environment for a 32-bit Single-Cycle RISC-V processor, developed as part of the METU EE446 Computer Architecture Laboratory[cite: 547]. 

[cite_start]This core implements the **RV32I Base Integer Instruction Set** [cite: 595] [cite_start]and features a custom, memory-mapped Serial Peripheral Interface (SPI) master designed to communicate with an ADXL362 accelerometer [cite: 636] on a Digilent Nexys A7-100T FPGA. All Verilog module comments have been fully translated to English for professional clarity.

## 🚀 Key Features

* [cite_start]**RV32I Architecture:** Single-cycle datapath and control unit implementing 23 core instructions[cite: 601].
* [cite_start]**Memory-Mapped SPI Controller:** Custom-built SPI Master peripheral integrated directly into the CPU's memory address space for seamless I/O operations[cite: 664].
* [cite_start]**Hardware Debugging:** Integrated multiplexed 7-segment display (MSSD) controller for real-time visualization of registers and PC state on the FPGA[cite: 719].
* [cite_start]**Golden Model Verification:** A highly robust Python-based testbench utilizing `cocotb` that co-simulates the Verilog hardware against a custom Python RISC-V ISA emulator[cite: 727], cross-referencing all 32 registers and the Program Counter on every clock edge.

### System Architecture
![RISC-V Datapath Diagram](./Images/Datapath.png)

## 📜 Supported Instruction Set

[cite_start]The processor supports the following unprivileged RISC-V instructions[cite: 601]:
* [cite_start]**Arithmetic:** `ADD`, `ADDI`, `SUB` [cite: 601]
* [cite_start]**Logic:** `AND`, `ANDI`, `OR`, `ORI`, `XOR`, `XORI` [cite: 601]
* [cite_start]**Shifts:** `SLL`, `SLLI`, `SRL`, `SRLI`, `SRA`, `SRAI` [cite: 601]
* [cite_start]**Comparison:** `SLTIU` [cite: 601]
* [cite_start]**Branching:** `BEQ`, `BNE`, `BLT`, `BLTU`, `BGE`, `BGEU` [cite: 601]
* [cite_start]**Jumps:** `JAL`, `JALR` [cite: 601]
* [cite_start]**Memory:** `LW`, `LH`, `LHU`, `LB`, `LBU`, `SW`, `SH`, `SB` [cite: 601]
* [cite_start]**Upper Immediate:** `LUI`, `AUIPC` [cite: 601]

## 🔌 Memory-Mapped SPI Interface

The processor extends its capabilities via an MMIO SPI peripheral, mapped to the data memory space. [cite_start]It operates at a 1 Mbps baud rate (Mode 0)[cite: 625]. Software interacts with the SPI module using standard `LW`, `SW`, and `SB` instructions at the following addresses:

| Address | Register | Size | Access | Description |
| :--- | :--- | :--- | :--- | :--- |
| `0x00000400` | **TX_Data** | 32-bit | Write | [cite_start]Holds data to be transmitted (Little Endian)[cite: 668, 670]. |
| `0x00000404` | **TX_Length**| 8-bit | Write | [cite_start]Number of bytes to transmit (max 4)[cite: 671, 673, 675]. |
| `0x00000405` | **RX_Length**| 8-bit | Write | [cite_start]Number of bytes to receive (max 4)[cite: 680, 682, 684]. |
| `0x00000406` | **X_Start** | 8-bit | Write | [cite_start]Writing here triggers the SPI transaction[cite: 685, 687]. |
| `0x00000408` | **RX_Data** | 32-bit | Read | [cite_start]Holds the received bytes after a transaction[cite: 676, 678]. |

### SPI Finite State Machine
![SPI State Machine](./Images/SPI_FSM.png)

## 🛠️ Hardware Implementation (FPGA)

The design is synthesized and targeted for the **Digilent Nexys A7-100T (Artix-7)**.
* **Clock Domains:** Derives 1 MHz (CPU), 5 MHz (SPI), and 2 Hz (Display) clocks from the 100 MHz board oscillator.
* **I/O Routing:** CPU debug states and ADXL362 accelerometer axes data (X, Y, Z) are routed to the on-board 7-Segment Displays and LEDs via slide switches.

### RTL Schematic
![RTL Schematic of Top Module](./Images/RTL_Schematic.png)

## 🧪 Verification Environment (Cocotb)

The verification environment avoids manual waveform checking by employing a Golden Model strategy. 

1.  **Python ISA Emulator:** `Helper_lib.py` acts as a perfect software model of the CPU.
2.  [cite_start]**Co-Simulation:** The `Single_Cycle_Test.py` script feeds machine code to both the Verilog DUT (Device Under Test) and the Python emulator[cite: 724].
3.  [cite_start]**Automated Assertion:** On the falling edge of every clock cycle, the testbench asserts that the Verilog Register File and PC perfectly match the Python model's state[cite: 725]. [cite_start]Any discrepancy instantly flags a failure[cite: 728].

### Verification Output
![Cocotb Simulation Output showing Golden Model comparison](./Images/Cocotb_Verification.png)

*Final regression summary confirming all tests passed successfully:*
![Cocotb Regression Summary](./Images/Cocotb_Regression_Pass.png)

### Running the Simulation

**Prerequisites:** * Icarus Verilog (v12.0 or higher recommended)
* Python 3 (Python 3.12 recommended for `cocotb` compatibility)
* Cocotb (`pip install cocotb`)

**Execution:**
Navigate to the testbench directory and run the Makefile:
```bash
make
