`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module ins_mem #(
    parameter MEM_DEPTH = 256,
    parameter BYTES_PER_LINE = 4, // Line width in Bytes
    parameter INIT_FILE = "memfile.mem"
)(
    input  wire [31:0] addr_in,
    output wire [(BYTES_PER_LINE*8)-1:0] instr_out
);

    // MEM_DEPTH x (BYTES_PER_LINE*8)-bit memory
    (* rom_style = "block" *) reg [(BYTES_PER_LINE*8)-1:0] RAM [0:MEM_DEPTH-1]; 

    initial begin
        // Initialize memory with readmemh
        $readmemh(INIT_FILE, RAM);
    end

    // Read logic - word aligned
    // $clog2 calculates the number of shift bits needed based on bytes per line
    assign instr_out = RAM[addr_in >> $clog2(BYTES_PER_LINE)];

endmodule
