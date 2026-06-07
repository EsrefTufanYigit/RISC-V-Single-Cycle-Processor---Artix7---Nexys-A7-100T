module Nexys_A7(
    //////////// GCLK //////////
    input wire                  CLK100MHZ,
	//////////// BTN //////////
	input wire		     		BTNU, 
	                      BTNL, BTNC, BTNR,
	                            BTND,
	//////////// SW //////////
	input wire	     [15:0]		SW,
	//////////// LED //////////
	output wire		 [15:0]		LED,
    //////////// 7 SEG //////////
    output wire [7:0] AN,
    output wire CA, CB, CC, CD, CE, CF, CG, DP,
    
    //////////// SPI PMOD //////////
    output wire                 sclk,
    output wire                 mosi,
    input  wire                 miso,
    output wire                 cs_n
);

wire [7:0] reg8_out, reg9_out, reg10_out;
wire [31:0] PC;
wire [4:0] buttons;
wire [2:0] spi_debug_state;

assign LED[15:13] = spi_debug_state;
assign LED[12:0]  = PC[14:2];

wire clk_5mhz;

clk_divider #( .INPUT_FREQ(100_000_000), .TARGET_FREQ(5_000_000) ) u_clk_divider5(
    .clk_in(CLK100MHZ),
    .rst(buttons[2]),         // BTNC'yi reset olarak bağladık
    .clk_out(clk_5mhz)
);

wire clk_1mhz;

clk_divider #( .INPUT_FREQ(100_000_000), .TARGET_FREQ(1_000_000) ) u_clk_divider1(
    .clk_in(CLK100MHZ),
    .rst(buttons[2]),         // BTNC'yi reset olarak bağladık
    .clk_out(clk_1mhz)
);

wire clk_2hz;

clk_divider #( .INPUT_FREQ(100_000_000), .TARGET_FREQ(2) ) u_clk_divider_2hz(
    .clk_in(CLK100MHZ),
    .rst(buttons[2]),         // BTNC'yi reset olarak bağladık
    .clk_out(clk_2hz)
);

reg [7:0] data_x, data_y, data_z;

always @(posedge clk_2hz) begin
    data_x <= reg8_out;
    data_y <= reg9_out;
    data_z <= reg10_out;
end


MSSD mssd_0(
        .clk        (CLK100MHZ                      ),
        .value      ({debug_reg_out[7:0], data_x, data_y, data_z} ),
        .dpValue    (8'b01000000                    ),
        .display    ({CG, CF, CE, CD, CC, CB, CA}   ),
        .DP         (DP                             ),
        .AN         (AN                             )
    );

debouncer debouncer_0(
        .clk        (CLK100MHZ                      ),
        .buttons    ({BTNU, BTNL, BTNC, BTNR, BTND} ),
        .out        (buttons                        )
    );

wire [31:0] debug_reg_out;

single_cycle my_computer(
        .clk                (clk_1mhz),
        .reset              (buttons[0]),
        .spi_clk            (clk_5mhz            ),
        .debug_reg_select   (SW[4:0]),
        .debug_reg_out      (debug_reg_out),
        .reg8_out           (reg8_out               ),
        .reg9_out           (reg9_out               ),
        .reg10_out          (reg10_out              ),
        .fetchPC            (PC                     ),
        .debug_state        (spi_debug_state        ),
        // SPI physical pins
        .sclk               (sclk                   ),
        .mosi               (mosi                   ),
        .miso               (miso                   ),
        .cs_n               (cs_n                   )
);

endmodule
