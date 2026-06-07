`timescale 1ns / 1ps

module clk_divider #(
    parameter INPUT_FREQ  = 100_000_000, // Ana giriş frekansı (100 MHz)
    parameter TARGET_FREQ = 5_000_000    // Hedef çıkış frekansı (Varsayılan: 5 MHz)
)(
    input  wire clk_in,   // Giriş saati
    input  wire rst,      // Senkron aktif-yüksek reset
    output reg  clk_out   // Bölünmüş çıkış saati
);

    // Derleme anında hesaplanan sayaç limiti (Donanıma ekstra yük getirmez)
    // Örn: 100_000_000 / (2 * 5_000_000) = 10
    localparam LIMIT = INPUT_FREQ / (2 * TARGET_FREQ);

    reg [31:0] counter;

    always @(posedge clk_in) begin
        if (rst) begin
            counter <= 32'd0;
            clk_out <= 1'b0;
        end else begin
            // Hedef limite ulaşınca çıkış saatini tersle (%50 duty cycle)
            if (counter >= (LIMIT - 1)) begin
                counter <= 32'd0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
