// (C) 2001-2025 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


`timescale 1 ps / 1 ps
module espi_fifo #(
    parameter DSIZE  = 8,
    parameter DEPTH  = 4,
    parameter WIDTHU = 4,
    parameter FAMILY = "ARRIA V"
) (
    input                    clk,
    input                    rst_n,
    input                    put,
    input                    get,
    input  [DSIZE-1:0]       wdata,
    output logic             full,
    output logic             empty,
    output logic [WIDTHU-1:0]usedw,
    output logic [DSIZE-1:0] rdata
);


logic [WIDTHU-1:0] usedw_c;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        usedw <= {WIDTHU{1'b0}};
	end
    else begin
        usedw <= usedw_c;
	end
end

    scfifo    scfifo_component (
                .clock            (clk),
                .wrreq            (put),
                .rdreq            (get),
                .aclr             (~rst_n),
                .sclr             (~rst_n),
                .data             (wdata),
                .q                (rdata),
                .usedw            (usedw_c),
                .full             (full),
                .empty            (empty)
	);
    defparam
        scfifo_component.lpm_width = DSIZE,
        scfifo_component.lpm_widthu = WIDTHU,
        scfifo_component.intended_device_family = FAMILY,
        scfifo_component.ram_block_type = "AUTO",
        scfifo_component.lpm_numwords = DEPTH,
        scfifo_component.lpm_showahead = "OFF",
        scfifo_component.add_ram_output_register = "OFF";
endmodule
