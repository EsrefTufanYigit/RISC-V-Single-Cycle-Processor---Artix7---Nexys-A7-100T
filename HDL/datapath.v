`timescale 1ns / 1ps

`timescale 1ns / 1ps

module datapath(
    input wire clk,
    input wire reset,
    input wire spi_clk,
    
    // Signals from Control Unit
    input wire PCSrc,
    input wire jalr,
    input wire reg_write,
    input wire [2:0] imm_ctrl,
    input wire alu_src_a,
    input wire alu_src_b,
    input wire [3:0] alu_ctrl,
    input wire [1:0] write_mask,
    input wire [1:0] result_src,
    input wire [1:0] load_size,
    input wire load_unsigned,
    
    // Signals to Control Unit
    output wire [31:0] Instr,
    output wire zero_flag,

    // SPI Control signals
    input wire         spi_we,
    input wire [3:0]   spi_write_mask,
    input wire         load_from_spi,
    output wire [31:0] mem_addr,

    // SPI physical interfaces
    output wire        sclk,
    output wire        mosi,
    input wire         miso,
    output wire        cs_n,

    // Debug ports
    input  wire [4:0]  debug_reg_select,
    output wire [31:0] debug_reg_out,
    output wire [31:0] reg8_out,
    output wire [31:0] reg9_out,
    output wire [31:0] reg10_out,
    output wire [31:0] fetchPC,
    output wire [2:0]  debug_state
);
    // Wire definitions for all connections
    wire [31:0] PCNext, PCPlus4, PCTarget, branch_target;
    wire [31:0] SrcA, SrcB, ImmExt, ALUResult, ReadData, Result;
    wire [31:0] RD1, RD2;
    
    // Target selection for JALR: ALUResult if JALR, else PCTarget (JAL/Branch)
    Mux_2to1 #(32) target_mux (
        .select(jalr),
        .input_0(PCTarget),
        .input_1(ALUResult),
        .output_value(branch_target)
    );
    
    // PCNext = PCSrc ? branch_target : PCPlus4
    Mux_2to1 #(32) pc_next_mux (
        .select(PCSrc),
        .input_0(PCPlus4),
        .input_1(branch_target),
        .output_value(PCNext)
    );
    
    // Program Counter (PC) Register (connected directly to fetchPC port)
    Register #(32) pc_reg (
        .clk(clk),
        .rst(reset),
        .enable(spi_ready),
        .data_in(PCNext),
        .data_out(fetchPC)
    );
    
    // PC + 4 Adder
    Adder #(32) pc_plus_4_adder (
        .DATA_A(fetchPC),
        .DATA_B(32'd4),
        .OUT(PCPlus4)
    );
    
    // Instruction Memory
    ins_mem #(
        .MEM_DEPTH(256),
        .BYTES_PER_LINE(4),
        .INIT_FILE("ins_data.mem")
    ) instruction_memory (
        .addr_in(fetchPC),
        .instr_out(Instr)
    );
    
    // Register File
    reg_file register_file (
        .clk(clk),
        .rst(reset),
        .we(reg_write),
        .read_addr1(Instr[19:15]),
        .read_addr2(Instr[24:20]),
        .write_addr(Instr[11:7]),
        .write_data(Result),
        .debug_reg_select(debug_reg_select),
        .debug_reg_out(debug_reg_out),
        .reg8_out(reg8_out),
        .reg9_out(reg9_out),
        .reg10_out(reg10_out),
        .read_data1(RD1),
        .read_data2(RD2)
    );
    
    // Extender (ImmGen)
    extender imm_extender (
        .instr(Instr),
        .imm_ctrl(imm_ctrl),
        .imm_ext(ImmExt)
    );
    
    // ALU SrcA Mux (For AUIPC support: 0 -> RD1, 1 -> PC)
    Mux_2to1 #(32) alu_src_a_mux (
        .select(alu_src_a),
        .input_0(RD1),
        .input_1(fetchPC),
        .output_value(SrcA)
    );
    
    // ALU SrcB Mux (0 -> RD2, 1 -> ImmExt)
    Mux_2to1 #(32) alu_src_b_mux (
        .select(alu_src_b),
        .input_0(RD2),
        .input_1(ImmExt),
        .output_value(SrcB)
    );
    
    // ALU
    ALU alu (
        .operand_a(SrcA),
        .operand_b(SrcB),
        .alu_ctrl(alu_ctrl),
        .alu_result(ALUResult),
        .zero_flag(zero_flag)
    );
    
    // PC Target Adder (PC + ImmExt)
    Adder #(32) pc_target_adder (
        .DATA_A(fetchPC),
        .DATA_B(ImmExt),
        .OUT(PCTarget)
    );
    
    // Data Memory
    data_mem #(
        .MEM_DEPTH(256),
        .BYTES_PER_LINE(4)
    ) data_memory (
        .clk(clk),
        .rst(reset),
        .write_mask(write_mask),
        .addr_in(ALUResult),
        .data_in(RD2),
        .load_size(load_size),
        .load_unsigned(load_unsigned),
        .data_out(ReadData)
    );
    
    // Address output to decoder
    assign mem_addr = ALUResult;
    
    // SPI Read Data Wire
    wire [31:0] spi_read_data;
    wire [31:0] final_read_data;
    
    // SPI Instance
    spi2 spi_inst (
        .clk(clk),
        .spi_clk(spi_clk),
        .rst(reset),
        // memory interfaces 
        .addr(ALUResult),
        .write_data(RD2),
        .we(spi_we),
        .write_mask(spi_write_mask),
        .read_data(spi_read_data),
        // spi interfaces 
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n),
        .spi_ready(spi_ready),
        .debug_state(debug_state)
    );
    
    // Mux to select between Memory Read Data or SPI Read Data
    Mux_2to1 #(32) load_src_mux (
        .select(load_from_spi),
        .input_0(ReadData),
        .input_1(spi_read_data),
        .output_value(final_read_data)
    );
    
    // Result Mux (00: ALUResult, 01: ReadData (Mem or SPI), 10: PC+4, 11: ImmExt)
    Mux_4to1 #(32) result_mux (
        .select(result_src),
        .input_0(ALUResult),
        .input_1(final_read_data),
        .input_2(PCPlus4),
        .input_3(ImmExt),
        .output_value(Result)
    );
    
endmodule