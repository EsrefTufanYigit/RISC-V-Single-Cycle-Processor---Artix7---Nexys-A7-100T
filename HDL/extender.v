`timescale 1ns / 1ps

module extender (
    input  wire [31:0] instr,
    input  wire [2:0]  imm_ctrl,
    output reg  [31:0] imm_ext
);

    // Immediate Source Control Codes (ImmCtrl)
    localparam IMM_I = 3'b000; // I-Type (Load, I-Type ALU)
    localparam IMM_S = 3'b001; // S-Type (Store)
    localparam IMM_B = 3'b010; // B-Type (Branch)
    localparam IMM_U = 3'b011; // U-Type (LUI, AUIPC)
    localparam IMM_J = 3'b100; // J-Type (JAL)

    always @(*) begin
        case (imm_ctrl)
            // I-Type: 12-bit immediate from [31:20], sign-extended
            IMM_I: imm_ext = {{20{instr[31]}}, instr[31:20]};
            
            // S-Type: 12-bit immediate from [31:25] and [11:7], sign-extended
            IMM_S: imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            
            // B-Type: 13-bit immediate (LSB is 0), sign-extended
            // instr[31], instr[7], instr[30:25], instr[11:8]
            IMM_B: imm_ext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            
            // U-Type: 20-bit immediate in upper bits [31:12], lower 12 bits are 0
            IMM_U: imm_ext = {instr[31:12], 12'b0};
            
            // J-Type: 21-bit immediate (LSB is 0), sign-extended
            // instr[31], instr[19:12], instr[20], instr[30:21]
            IMM_J: imm_ext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            
            default: imm_ext = 32'b0;
        endcase
    end

endmodule
