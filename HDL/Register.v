`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Pipeline Inter-Stage Register
// Used to separate stages in a pipelined CPU or as a general-purpose register
//////////////////////////////////////////////////////////////////////////////////

module Register #(
    parameter WIDTH = 32
)(
    input  wire clk,
    input  wire rst,     
    input  wire enable,  
    input  wire [WIDTH-1:0] data_in,  
    output reg  [WIDTH-1:0] data_out  
);

    always @(posedge clk) begin
        if (rst) begin
            data_out <= {WIDTH{1'b0}}; 
        end else if (enable) begin
            data_out <= data_in; 
        end
    end

endmodule
