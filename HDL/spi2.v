`timescale 1ns / 1ps

module spi2 (
    input  wire        clk,
    input  wire        spi_clk,
    input  wire        rst,
    // memory interfaces 
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    input  wire        we,
    input  wire [3:0]  write_mask,
    output  [31:0] read_data,
    // spi interfaces 
    output reg         sclk,
    output reg         mosi,
    input  wire        miso,
    output reg         cs_n,
    output reg         spi_ready,
    output wire [2:0]  debug_state
);

    // Memory-Mapped Addresses
    localparam ADDR_TX_DATA   = 32'h00000400;
    localparam ADDR_TX_LENGTH = 32'h00000404;
    localparam ADDR_RX_LENGTH = 32'h00000405;
    localparam ADDR_X_START   = 32'h00000406;
    localparam ADDR_RX_DATA   = 32'h00000408;

    // Rx and Tx registers
    reg [7:0]  rx_len_reg;
    reg [31:0] rx_data_reg;
    reg [31:0] tx_data_reg;
    reg [7:0]  tx_len_reg;
    

    // Finite state machine states 
    localparam STATE_IDLE    = 3'd0;
    localparam STATE_TX      = 3'd1;
    localparam STATE_RX      = 3'd2;
    localparam STATE_DONE    = 3'd3;

    reg [2:0] state, next_state;

    // 1 Mbps baud rate generation 
    // SCLK toggles every 50 system clocks
    reg [5:0] baud_counter, next_baud_counter;
    wire sclk_tick = (baud_counter == 2'b10);  // 6'd49
    
    // Bit and byte counters 
    reg [2:0] bit_count, next_bit_count;
    reg [7:0] byte_count, next_byte_count;
    
    // Shift registers
    reg [7:0] tx_shift, next_tx_shift;
    reg [7:0] rx_shift, next_rx_shift;
    reg [31:0] rx_buffer, next_rx_buffer;
    reg       next_sclk;

    // Asynchronous MMIO read logic 
    assign read_data = rx_data_reg;
    assign debug_state = state;
    reg data_ready;


    ////////////////////////////////////////
    reg clk_1, clk_2;
    always @(posedge spi_clk) begin
        clk_1 <= clk_2;
        clk_2 <= clk;
    end
    wire rising_edge = clk_2 & !clk_1;


    // Combinational next-state and next-value logic
    always @(*) begin
        // Defaults: keep current registered values
        next_state        = state;
        next_baud_counter = baud_counter;
        next_sclk         = sclk;
        next_bit_count    = bit_count;
        next_byte_count   = byte_count;
        next_tx_shift     = tx_shift;
        next_rx_shift     = rx_shift;
        next_rx_buffer    = rx_buffer;
        spi_ready         = 1'b1;
        data_ready        = 1'b0;
        
        case (state)
            STATE_IDLE: begin
                next_baud_counter = 6'b0;
                next_bit_count    = 3'd7;
                next_byte_count   = 8'd0;
                next_rx_buffer    = 32'b0;
                
                if (we && addr == ADDR_X_START && write_mask[0]) begin
                    spi_ready         = 1'b0;
                    if (tx_len_reg > 0) begin
                        next_state    = STATE_TX;
                        next_tx_shift = tx_data_reg[7:0];
                    end else if (rx_len_reg > 0) begin
                        next_state    = STATE_RX;
                    end else begin
                        next_state    = STATE_DONE;
                    end
                end
            end
            
            STATE_TX: begin
                spi_ready         = 1'b0;
                if (baud_counter == 2'b10) begin
                    next_baud_counter = 6'b0;
                    next_sclk         = ~sclk;
                    
                    if (sclk) begin // Falling edge of sclk
                        if (bit_count == 0) begin
                            next_bit_count  = 3'd7;
                            next_byte_count = byte_count + 1;
                            
                            if (byte_count + 1 == tx_len_reg) begin
                                if (rx_len_reg > 0) begin
                                    next_state      = STATE_RX;
                                    next_byte_count = 8'd0;
                                end else begin
                                    next_state      = STATE_DONE;
                                end
                            end else begin
                                // Load next byte
                                case (byte_count + 1)
                                    8'd1: next_tx_shift = tx_data_reg[15:8];
                                    8'd2: next_tx_shift = tx_data_reg[23:16];
                                    8'd3: next_tx_shift = tx_data_reg[31:24];
                                    default: next_tx_shift = 8'b0;
                                endcase
                            end
                        end else begin
                            next_bit_count = bit_count - 1;
                        end
                    end
                end else begin
                    next_baud_counter = baud_counter + 1;
                end
            end
            
            STATE_RX: begin
                spi_ready         = 1'b0;
                if (baud_counter == 2'b10) begin
                    next_baud_counter = 6'b0;
                    next_sclk         = ~sclk;
                    
                    if (~sclk) begin // Rising edge of sclk
                        next_rx_shift[bit_count] = miso;
                    end else begin // Falling edge
                        if (bit_count == 0) begin
                            next_bit_count = 3'd7;
                            
                            // Received byte to the buffer 
                            case (byte_count)
                                8'd0: next_rx_buffer[7:0]   = rx_shift;
                                8'd1: next_rx_buffer[15:8]  = rx_shift;
                                8'd2: next_rx_buffer[23:16] = rx_shift;
                                8'd3: next_rx_buffer[31:24] = rx_shift;
                            endcase
                            
                            next_byte_count = byte_count + 1;
                            
                            if (byte_count + 1 == rx_len_reg) begin
                                next_state = STATE_DONE;
                            end
                        end else begin
                            next_bit_count = bit_count - 1;
                        end
                    end
                end else begin
                    next_baud_counter = baud_counter + 1;
                end
            end
            
            STATE_DONE: begin
                data_ready = 1'b1;
                if (baud_counter == 2'b10) begin
                    next_state = (rising_edge) ? STATE_IDLE : STATE_DONE;
                end else begin
                    next_baud_counter = baud_counter + 1;
                end
            end
            
            default: next_state = STATE_IDLE;
        endcase
    end

    // Combinational Output Logic for purely combinational signals: cs_n and mosi
    always @(*) begin
        cs_n = 1'b1;
        mosi = 1'b0;
        
        case (state)
            STATE_IDLE: begin
                if (we && addr == ADDR_X_START && write_mask[0]) begin
                    cs_n = 1'b0;
                    if (tx_len_reg > 0) begin
                        mosi = tx_data_reg[7];
                    end
                end else begin
                    cs_n = 1'b1;
                end
            end
            
            STATE_TX: begin
                cs_n = 1'b0;
                mosi = tx_shift[bit_count];
            end
            
            STATE_RX: begin
                cs_n = 1'b0;
            end
            
            STATE_DONE: begin
                cs_n = 1'b1;

            end
            
            default: begin
                cs_n = 1'b1;
                mosi = 1'b0;
            end
        endcase
    end

    // Clocked Sequential Register Updates
    always @(posedge spi_clk) begin
        if (rst) begin
            tx_data_reg  <= 32'b0;
            tx_len_reg   <= 8'b0;
            rx_len_reg   <= 8'b0;
            rx_data_reg  <= 32'b0;
            
            state        <= STATE_IDLE;
            baud_counter <= 6'b0;
            sclk         <= 1'b0;
            bit_count    <= 3'd7;
            byte_count   <= 8'd0;
            tx_shift     <= 8'b0;
            rx_shift     <= 8'b0;
            rx_buffer    <= 32'b0;
        end else begin
            // CPU MMIO Write
            if (we) begin
                case (addr)
                    ADDR_TX_DATA:   if (write_mask[0]) tx_data_reg <= write_data;  // düzelt
                    ADDR_TX_LENGTH: if (write_mask[0]) tx_len_reg <= write_data[7:0];
                    ADDR_RX_LENGTH: if (write_mask[0]) rx_len_reg <= write_data[7:0];
                endcase
            end
            
            // Lock RX buffer to rx_data_reg when done
            if (data_ready) begin
                rx_data_reg <= rx_buffer;
            end
            
            // Sequential state and counter/shifter updates
            state        <= next_state;
            baud_counter <= next_baud_counter;
            sclk         <= next_sclk;
            bit_count    <= next_bit_count;
            byte_count   <= next_byte_count;
            tx_shift     <= next_tx_shift;
            rx_shift     <= next_rx_shift;
            rx_buffer    <= next_rx_buffer;
        end
    end
endmodule