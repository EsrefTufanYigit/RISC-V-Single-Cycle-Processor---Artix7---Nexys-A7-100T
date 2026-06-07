`timescale 1ns / 1ps

module data_mem #(
    parameter MEM_DEPTH = 256,
    parameter BYTES_PER_LINE = 4, // Line width in Bytes
    parameter INIT_FILE = "datafile.mem"
)(
    input  wire clk,
    input  wire rst,
    input  wire [1:0] write_mask, // Byte write mask (1 bit per byte)
    input  wire [31:0] addr_in,
    input  wire [(BYTES_PER_LINE*8)-1:0] data_in,
    input  wire [1:0] load_size,
    input  wire load_unsigned,
    output wire [(BYTES_PER_LINE*8)-1:0] data_out
);

    // MEM_DEPTH x (BYTES_PER_LINE*8)-bit memory
    reg [(BYTES_PER_LINE*8)-1:0] RAM [0:MEM_DEPTH-1]; 

    integer k;
    initial begin
        for (k = 0; k < MEM_DEPTH; k = k + 1) begin
            RAM[k] = 32'b0;
        end
    end

    reg [3:0] wm;
    reg [31:0] temp_val;

    always@(*) begin
        case (write_mask)
            2'b01:begin wm = 4'b0001 << addr_in[1:0]; temp_val = {4{data_in[7:0]}}; end
            2'b10:begin wm = addr_in[1] ? 4'b1100 : 4'b0011; temp_val = {2{data_in[15:0]}}; end
            2'b11:begin wm = 4'b1111; temp_val = data_in; end
            default:begin wm = 4'b0000; temp_val = 32'b0; end
        endcase
    end
    // Write operation and Reset (synchronous)
    integer i, j;
    always @(posedge clk) begin
        for (i = 0; i < BYTES_PER_LINE; i = i + 1) begin
            if (wm[i]) begin
                RAM[addr_in >> $clog2(BYTES_PER_LINE)][i*8 +: 8] <= temp_val[i*8 +: 8];
            end
        end
    end

    // Read operation (asynchronous)
    wire [31:0] full_word = RAM[addr_in >> $clog2(BYTES_PER_LINE)];
    reg [31:0] data_out_reg;
    always @(*) begin
        case (load_size)
            2'b01: begin // Byte Load
                case (addr_in[1:0])
                    2'b00: data_out_reg = load_unsigned ? {24'd0, full_word[7:0]}   : {{24{full_word[7]}},   full_word[7:0]};
                    2'b01: data_out_reg = load_unsigned ? {24'd0, full_word[15:8]}  : {{24{full_word[15]}},  full_word[15:8]};
                    2'b10: data_out_reg = load_unsigned ? {24'd0, full_word[23:16]} : {{24{full_word[23]}},  full_word[23:16]};
                    2'b11: data_out_reg = load_unsigned ? {24'd0, full_word[31:24]} : {{24{full_word[31]}},  full_word[31:24]};
                endcase
            end
            2'b10: begin // Halfword Load
                if (addr_in[1]) begin
                    data_out_reg = load_unsigned ? {16'd0, full_word[31:16]} : {{16{full_word[31]}}, full_word[31:16]};
                end else begin
                    data_out_reg = load_unsigned ? {16'd0, full_word[15:0]}  : {{16{full_word[15]}}, full_word[15:0]};
                end
            end
            2'b11: begin // Word Load
                data_out_reg = full_word;
            end
            default: begin
                data_out_reg = full_word;
            end
        endcase
    end
    assign data_out = data_out_reg;

endmodule
