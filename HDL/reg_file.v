`timescale 1ns / 1ps

module reg_file (
    input  wire clk,
    input  wire rst, // Synchronous active-high reset
    input  wire we,  // Write Enable
    input  wire [4:0] read_addr1,
    input  wire [4:0] read_addr2,
    input  wire [4:0] write_addr,
    input  wire [31:0] write_data,
    
    // Debug portları
    input  wire [4:0]  debug_reg_select,
    output wire [31:0] debug_reg_out,
    output wire [7:0]  reg8_out,
    output wire [7:0]  reg9_out,
    output wire [7:0]  reg10_out,
    
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    // 32 x 32-bit register array
    reg [31:0] registers [0:31];
    
    // Initialize all registers to 0 (optional but good for simulation)
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'b0;
        end
    end

    // Write operation and Reset (Synchronous to negative edge)
    always @(posedge clk) begin
        if (rst) begin
            // Reset all registers to 0
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else begin
            // RISC-V requires x0 to be hardwired to zero.
            // Therefore, we only write if the address is not 0.
            if (we && write_addr != 5'd0) begin
                registers[write_addr] <= write_data;
            end
        end
    end

    // Read operation (Asynchronous)
    assign read_data1 = registers[read_addr1];
    assign read_data2 = registers[read_addr2];
    
    assign reg8_out   = registers[8][7:0];
    assign reg9_out   = registers[9][7:0];
    assign reg10_out  = registers[10][7:0];
    
    assign debug_reg_out = registers[debug_reg_select];

endmodule
