`timescale 1ns / 1ps

module single_cycle(
    input wire clk,
    input wire reset,
    input wire spi_clk,
    
    // SPI Physical Pins
    output wire        sclk,
    output wire        mosi,
    input  wire        miso,
    output wire        cs_n,

    // Debug Ports
    input  wire [4:0]  debug_reg_select,
    output wire [31:0] debug_reg_out,
    output wire [7:0]  reg8_out,
    output wire [7:0]  reg9_out,
    output wire [7:0]  reg10_out,
    output wire [31:0] fetchPC,
    output wire [2:0]  debug_state
);

  // Interconnect cables (Wires)
    wire [31:0] Instr;
    wire        zero_flag;
    
    wire        PCSrc;
    wire        jalr;
    wire        reg_write;
    wire [2:0]  imm_ctrl;
    wire        alu_src_a;
    wire        alu_src_b;
    wire [3:0]  alu_ctrl;
    wire [1:0]  write_mask;
    wire [1:0]  result_src;
    wire [1:0]  load_size;
    wire        load_unsigned;

    // SPI Interconnect Wires
    wire        spi_we;
    wire [3:0]  spi_write_mask;
    wire        load_from_spi;
    wire [31:0] mem_addr;

    // Datapath 
    datapath dp (
        .clk(clk),
        .reset(reset),
        .spi_clk(spi_clk),
        
        // The signals come from Controller 
        .PCSrc(PCSrc),
        .jalr(jalr),
        .reg_write(reg_write),
        .imm_ctrl(imm_ctrl),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .alu_ctrl(alu_ctrl),
        .write_mask(write_mask),
        .result_src(result_src),
        .load_size(load_size),
        .load_unsigned(load_unsigned),
        
        // SPI Control signals
        .spi_we(spi_we),
        .spi_write_mask(spi_write_mask),
        .load_from_spi(load_from_spi),
        .mem_addr(mem_addr),
        
        // SPI physical pins
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n),
        
        // The signals go to Controller 
        .Instr(Instr),
        .zero_flag(zero_flag),
        
        // Debug ports
        .debug_reg_select(debug_reg_select),
        .debug_reg_out(debug_reg_out),
        .reg8_out(reg8_out),
        .reg9_out(reg9_out),
        .reg10_out(reg10_out),
        .fetchPC(fetchPC),
        .debug_state(debug_state)
    );

    // Decoder (Kontroller unit ) 
    decoder ctrl (
        // The signals that come from Datapath 
        .Instr(Instr),
        .zero_flag(zero_flag),
        .mem_addr(mem_addr),
        
        // The signals that goes to Datapath 
        .PCSrc(PCSrc),
        .jalr(jalr),
        .reg_write(reg_write),
        .imm_ctrl(imm_ctrl),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .alu_ctrl(alu_ctrl),
        .write_mask(write_mask),
        .result_src(result_src),
        .load_size(load_size),
        .load_unsigned(load_unsigned),

        // SPI Control signals
        .spi_we(spi_we),
        .spi_write_mask(spi_write_mask),
        .load_from_spi(load_from_spi)
    );

endmodule
