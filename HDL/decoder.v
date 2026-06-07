`timescale 1ns / 1ps

`timescale 1ns / 1ps

module decoder (
    input  wire [31:0] Instr,
    input  wire        zero_flag,
    input  wire [31:0] mem_addr,
    
    output reg        PCSrc,
    output reg        jalr,
    output reg        reg_write,
    output reg [2:0]  imm_ctrl,
    output reg        alu_src_a,
    output reg        alu_src_b,
    output reg [3:0]  alu_ctrl,
    output reg [1:0]  write_mask,
    output reg [1:0]  result_src,
    output reg [1:0]  load_size,
    output reg        load_unsigned,

    // SPI Control signals
    output reg        spi_we,
    output reg [3:0]  spi_write_mask,
    output reg        load_from_spi
);
    wire [6:0] opcode = Instr[6:0];
    wire [2:0] funct3 = Instr[14:12];
    wire [6:0] funct7 = Instr[31:25];
    wire funct7_5     = funct7[5];

    // RISC-V RV32I Opcodes
    localparam OP_R       = 7'b0110011;
    localparam OP_I_ALU   = 7'b0010011;
    localparam OP_LOAD    = 7'b0000011;
    localparam OP_STORE   = 7'b0100011;
    localparam OP_BRANCH  = 7'b1100011;
    localparam OP_JAL     = 7'b1101111;
    localparam OP_JALR    = 7'b1100111;
    localparam OP_LUI     = 7'b0110111;
    localparam OP_AUIPC   = 7'b0010111;
    
    // ALU Control Codes (from ALU.v)
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b1000;
    localparam ALU_SLL  = 4'b0001;
    localparam ALU_SLT  = 4'b0010;
    localparam ALU_SLTU = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SRL  = 4'b0101;
    localparam ALU_SRA  = 4'b1101;
    localparam ALU_OR   = 4'b0110;
    localparam ALU_AND  = 4'b0111;

    wire is_spi_addr = (mem_addr == 32'h00000400) || // ADDR_TX_DATA
                       (mem_addr == 32'h00000404) || // ADDR_TX_LENGTH
                       (mem_addr == 32'h00000405) || // ADDR_RX_LENGTH
                       (mem_addr == 32'h00000406) || // ADDR_X_START
                       (mem_addr == 32'h00000408);   // ADDR_RX_DATA

    always @(*) begin
        // Default values (to prevent latch formation)
        PCSrc      = 0;
        jalr       = 0;
        reg_write  = 0;
        imm_ctrl   = 3'b000;
        alu_src_a  = 0; 
        alu_src_b  = 0;
        alu_ctrl   = 4'b0000;
        write_mask = 2'b00;
        result_src = 2'b00;
        load_size  = 2'b00;
        load_unsigned = 1'b0;
        
        // SPI Default values
        spi_we         = 0;
        spi_write_mask = 4'b0000;
        load_from_spi  = 0;

        case (opcode)
            OP_R: begin
                reg_write  = 1;
                alu_src_a  = 0; // RegA
                alu_src_b  = 0; // RegB
                result_src = 2'b00; // ALU
                alu_ctrl   = {funct7_5, funct3};
            end
            
            OP_I_ALU: begin
                reg_write  = 1;
                imm_ctrl   = 3'b000; // IMM_I
                alu_src_a  = 0; // RegA
                alu_src_b  = 1; // Imm
                result_src = 2'b00; // ALU
                // SRAI (funct3=101, funct7[5]=1) others are assumed funct7[5]=0
                if (funct3 == 3'b101) alu_ctrl = {funct7_5, funct3};
                else                  alu_ctrl = {1'b0, funct3};
            end
            
            OP_LOAD: begin
                reg_write  = 1;
                imm_ctrl   = 3'b000; // IMM_I
                alu_src_a  = 0; // RegA
                alu_src_b  = 1; // Imm
                result_src = 2'b01; // Data Memory / SPI
                alu_ctrl   = ALU_ADD; // Address = RegA + Imm
                
                // Decode load size and unsigned properties
                if (funct3 == 3'b000)      begin load_size = 2'b01; load_unsigned = 1'b0; end // LB
                else if (funct3 == 3'b100) begin load_size = 2'b01; load_unsigned = 1'b1; end // LBU
                else if (funct3 == 3'b001) begin load_size = 2'b10; load_unsigned = 1'b0; end // LH
                else if (funct3 == 3'b101) begin load_size = 2'b10; load_unsigned = 1'b1; end // LHU
                else                       begin load_size = 2'b11; load_unsigned = 1'b0; end // LW

                // If address is in SPI region, read from SPI
                if (is_spi_addr) begin
                    load_from_spi = 1'b1;
                end
            end
            
            OP_STORE: begin
                imm_ctrl   = 3'b001; // IMM_S
                alu_src_a  = 0; // RegA
                alu_src_b  = 1; // Imm
                alu_ctrl   = ALU_ADD; // Address = RegA + Imm
                
                if (is_spi_addr) begin
                    spi_we = 1'b1;
                    if (funct3 == 3'b000)      spi_write_mask = 4'b0001;
                    else if (funct3 == 3'b001) spi_write_mask = 4'b0011;
                    else                       spi_write_mask = 4'b1111;
                    write_mask = 2'b00; // Prevent normal memory write
                end else begin
                    if (funct3 == 3'b000)      write_mask = 2'b01; // SB
                    else if (funct3 == 3'b001) write_mask = 2'b10; // SH
                    else                       write_mask = 2'b11; // SW
                end
            end
            
            OP_BRANCH: begin
                imm_ctrl   = 3'b010; // IMM_B
                alu_src_a  = 0; // RegA
                alu_src_b  = 0; // RegB
                case (funct3)
                    3'b000: begin alu_ctrl = ALU_SUB; PCSrc = zero_flag;  end // BEQ
                    3'b001: begin alu_ctrl = ALU_SUB; PCSrc = ~zero_flag; end // BNE
                    3'b100: begin alu_ctrl = ALU_SLT; PCSrc = ~zero_flag; end // BLT
                    3'b101: begin alu_ctrl = ALU_SLT; PCSrc = zero_flag;  end // BGE
                    3'b110: begin alu_ctrl = ALU_SLTU; PCSrc = ~zero_flag; end // BLTU
                    3'b111: begin alu_ctrl = ALU_SLTU; PCSrc = zero_flag;  end // BGEU
                    default: begin alu_ctrl = ALU_SUB; PCSrc = 0; end
                endcase
            end
            
            OP_JAL: begin
                reg_write  = 1;
                PCSrc      = 1;
                imm_ctrl   = 3'b100; // IMM_J
                result_src = 2'b10; // PC + 4
            end
            
            OP_JALR: begin
                reg_write  = 1;
                PCSrc      = 1;
                jalr       = 1;
                imm_ctrl   = 3'b000; // IMM_I
                alu_src_a  = 0; // RegA
                alu_src_b  = 1; // Imm
                result_src = 2'b10; // PC + 4
                alu_ctrl   = ALU_ADD; // Target = RegA + Imm
            end
            
            OP_LUI: begin
                reg_write  = 1;
                imm_ctrl   = 3'b011; // IMM_U
                result_src = 2'b11; // ImmExt
            end
            
            OP_AUIPC: begin
                reg_write  = 1;
                imm_ctrl   = 3'b011; // IMM_U
                alu_src_a  = 1; // PC
                alu_src_b  = 1; // Imm
                result_src = 2'b00; // ALU
                alu_ctrl   = ALU_ADD; // Target = PC + Imm
            end
            
            default: ; // Signals remain at 0
        endcase
    end

endmodule