`timescale 1ns / 1ps

module ALU (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] alu_result,
    output wire        zero_flag
);

    // RISC-V RV32I ALU Control Codes
    // Parameters are mapped directly to {funct7[5], funct3}
    localparam ALU_ADD  = 4'b0000; // 000 + 0
    localparam ALU_SUB  = 4'b1000; // 000 + 1 (funct7[5] = 1)
    localparam ALU_SLL  = 4'b0001; // 001 + 0
    localparam ALU_SLT  = 4'b0010; // 010 + 0
    localparam ALU_SLTU = 4'b0011; // 011 + 0
    localparam ALU_XOR  = 4'b0100; // 100 + 0
    localparam ALU_SRL  = 4'b0101; // 101 + 0
    localparam ALU_SRA  = 4'b1101; // 101 + 1 (funct7[5] = 1)
    localparam ALU_OR   = 4'b0110; // 110 + 0
    localparam ALU_AND  = 4'b0111; // 111 + 0

    // Branch (BEQ, BNE) instructions use zero flag
    assign zero_flag = (alu_result == 32'b0);

    always @(*) begin
        case (alu_ctrl)
            ALU_ADD:  alu_result = operand_a + operand_b;
            ALU_SUB:  alu_result = operand_a - operand_b;
            ALU_SLL:  alu_result = operand_a << operand_b[4:0];
            ALU_SLT:  alu_result = ($signed(operand_a) < $signed(operand_b)) ? 32'b1 : 32'b0;
            ALU_SLTU: alu_result = (operand_a < operand_b) ? 32'b1 : 32'b0;
            ALU_XOR:  alu_result = operand_a ^ operand_b;
            ALU_SRL:  alu_result = operand_a >> operand_b[4:0];
            ALU_SRA:  alu_result = $signed(operand_a) >>> operand_b[4:0];
            ALU_OR:   alu_result = operand_a | operand_b;
            ALU_AND:  alu_result = operand_a & operand_b;
            default:  alu_result = 32'b0;
        endcase
    end

endmodule
