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



`include "espi_header.iv"

`timescale 1 ps / 1 ps
module espi_pc_channel #(
    parameter PC_PORT00_EN       = 0,
    parameter PC_PORT10_EN       = 0,
    parameter PC_PORT20_EN       = 0,
    parameter PC_PORT30_EN       = 0,
    parameter PC_PORT40_EN       = 0,
    parameter PC_PORT50_EN       = 0,
    parameter PC_PORT60_EN       = 0,
    parameter PC_PORT70_EN       = 0,
    parameter PC_PORT80_EN       = 1,
    parameter PC_PORT90_EN       = 0,
    parameter PC_PORTA0_EN       = 0,
    parameter PC_PORT00_OUTPUT   = 0,
    parameter PC_PORT10_OUTPUT   = 0,
    parameter PC_PORT20_OUTPUT   = 0,
    parameter PC_PORT30_OUTPUT   = 0,
    parameter PC_PORT40_OUTPUT   = 0,
    parameter PC_PORT50_OUTPUT   = 0,
    parameter PC_PORT60_OUTPUT   = 0,
    parameter PC_PORT70_OUTPUT   = 0,
    parameter PC_PORT80_OUTPUT   = 1,
    parameter PC_PORT90_OUTPUT   = 0,
    parameter PC_PORTA0_OUTPUT   = 0,	
    parameter PORT00_DWIDTH      = 8,
    parameter PORT10_DWIDTH      = 8,
    parameter PORT20_DWIDTH      = 8,
    parameter PORT30_DWIDTH      = 8,
    parameter PORT40_DWIDTH      = 8,
    parameter PORT50_DWIDTH      = 8,
    parameter PORT60_DWIDTH      = 8,
    parameter PORT70_DWIDTH      = 8,
    parameter PORT80_DWIDTH      = 8,
    parameter PORT90_DWIDTH      = 8,
    parameter PORTA0_DWIDTH      = 8,
    parameter DEVICE_FAMILY      = "MAX 10 FPGA",
    parameter PC_TXFIFO_SIZE     = 2048,
    parameter PC_TXFIFO_WIDTHU   = 11,
    parameter PC_RXFIFO_SIZE     = 2048,
    parameter PC_RXFIFO_WIDTHU   = 11,
    parameter HDRBYTE_ARR        = 3,
    parameter DATABYTE_ARR       = 2
)(
    input                             clk,
    input                             reset_n,
    input                             pltrst_n,
    input                             pec_mismatch,
    input                             pc_error_condition,
    input                             flush_pc_fifo,
    input                             pc_channel_reset,
    input                             stop_det,
    input                             pc_channel_en,
    input                             read_pc_rxfifo,
    input                             read_np_rxfifo,
    input [7:0]                       txfifo_wdata,
    input [1:0]                       rx_hdr_array_cnt,
    input [2:0]                       rx_data_array_cnt,
    input [7:0]                       header_byte[HDRBYTE_ARR],
    input [7:0]                       data_byte[DATABYTE_ARR],
    input [7:0]                       command_byte,
    input                             rx_detect_data,
    input                             rx_detect_header,
    input                             rx_detect_header_end,
    input                             rx_detect_data_end,
    input                             rx_detect_crc_end,
    input                             rx_detect_command,
    input                             tx_gen_command,
    input                             tx_gen_header,
    input                             tx_gen_data,
    input                             spiclk_cnt_done_hl,
    input                             spiclk_cnt_done_lh,
    input                             detect_put_np_rxfifo,
    input                             detect_put_pc_rxfifo,
    input                             detect_get_np_txfifo,
    input                             detect_get_pc_txfifo,
    input                             detect_iord_short,
    input                             detect_iowr_short,
    input                             write_pc_txfifo,
    input                             write_np_txfifo,
    output logic                      pc_free,
    output logic                      np_free,
    output logic                      pc_rxfifo_avail,
    output logic                      np_rxfifo_avail,
    output logic                      pc_channel_ready,
    output logic [7:0]                pc_rxfifo_rdata,
    output logic [7:0]                np_rxfifo_rdata,
    output logic [7:0]                txfifo_rdata,
    output logic                      invalid_ioport_addr,
    output logic                      get_pc_txfifo,
    output logic                      get_np_txfifo,
	//----------------- configurable ports ------------------------------
    input [PORT00_DWIDTH-1:0]         pc_port00_in,
    input [PORT10_DWIDTH-1:0]         pc_port10_in,
    input [PORT20_DWIDTH-1:0]         pc_port20_in,
    input [PORT30_DWIDTH-1:0]         pc_port30_in,
    input [PORT40_DWIDTH-1:0]         pc_port40_in,
    input [PORT50_DWIDTH-1:0]         pc_port50_in,
    input [PORT60_DWIDTH-1:0]         pc_port60_in,
    input [PORT70_DWIDTH-1:0]         pc_port70_in,
    input [PORT80_DWIDTH-1:0]         pc_port80_in,
    input [PORT90_DWIDTH-1:0]         pc_port90_in,
    input [PORTA0_DWIDTH-1:0]         pc_portA0_in,
    output logic [31:0]               pc_port_data,
    output logic [PORT00_DWIDTH-1:0]  pc_port00_out,
    output logic [PORT10_DWIDTH-1:0]  pc_port10_out,
    output logic [PORT20_DWIDTH-1:0]  pc_port20_out,
    output logic [PORT30_DWIDTH-1:0]  pc_port30_out,
    output logic [PORT40_DWIDTH-1:0]  pc_port40_out,
    output logic [PORT50_DWIDTH-1:0]  pc_port50_out,
    output logic [PORT60_DWIDTH-1:0]  pc_port60_out,
    output logic [PORT70_DWIDTH-1:0]  pc_port70_out,
    output logic [PORT80_DWIDTH-1:0]  pc_port80_out,
    output logic [PORT90_DWIDTH-1:0]  pc_port90_out,
    output logic [PORTA0_DWIDTH-1:0]  pc_portA0_out
);

logic channel_reset_n, put_pc_rxfifo, get_pc_rxfifo, put_np_rxfifo, get_np_rxfifo, pc_txfifo_empty, np_txfifo_empty;
logic pc_rxfifo_full, pc_rxfifo_empty, pc_txfifo_full, np_rxfifo_full, np_rxfifo_empty, np_txfifo_full;
logic [7:0] pc_rxfifo_wdata, np_rxfifo_wdata, pc_txfifo_rdata, np_txfifo_rdata;
logic [PORT00_DWIDTH-1:0] pc_port_data_00;
logic [PORT10_DWIDTH-1:0] pc_port_data_10; 
logic [PORT20_DWIDTH-1:0] pc_port_data_20; 
logic [PORT30_DWIDTH-1:0] pc_port_data_30; 
logic [PORT40_DWIDTH-1:0] pc_port_data_40; 
logic [PORT50_DWIDTH-1:0] pc_port_data_50; 
logic [PORT60_DWIDTH-1:0] pc_port_data_60; 
logic [PORT70_DWIDTH-1:0] pc_port_data_70; 
logic [PORT80_DWIDTH-1:0] pc_port_data_80; 
logic [PORT90_DWIDTH-1:0] pc_port_data_90;
logic [PORTA0_DWIDTH-1:0] pc_port_data_A0;

assign txfifo_rdata = detect_get_pc_txfifo ? pc_txfifo_rdata :
                        detect_get_np_txfifo ? np_txfifo_rdata : {8{1'b0}};
assign channel_reset_n = reset_n && pltrst_n && ~pc_channel_reset;
assign put_pc_rxfifo = (detect_put_pc_rxfifo && spiclk_cnt_done_hl && (rx_detect_command || rx_detect_header || rx_detect_data));
assign pc_rxfifo_wdata = (rx_detect_command && spiclk_cnt_done_hl) ? command_byte :
                           (rx_detect_header && spiclk_cnt_done_hl) ? header_byte[rx_hdr_array_cnt] :
                             (rx_detect_data && spiclk_cnt_done_hl) ? data_byte[rx_data_array_cnt] : {8{1'b0}};
assign put_np_rxfifo = (detect_put_np_rxfifo && spiclk_cnt_done_hl && (rx_detect_command || rx_detect_header));
assign np_rxfifo_wdata = (rx_detect_command && spiclk_cnt_done_hl) ? command_byte :
                           (rx_detect_header && spiclk_cnt_done_hl) ? header_byte[rx_hdr_array_cnt] : {8{1'b0}};
assign pc_port_data = {{32-PORT00_DWIDTH{1'b0}}, pc_port_data_00} | {{32-PORT10_DWIDTH{1'b0}}, pc_port_data_10} | {{32-PORT20_DWIDTH{1'b0}}, pc_port_data_20} | 
                        {{32-PORT30_DWIDTH{1'b0}}, pc_port_data_30} | {{32-PORT40_DWIDTH{1'b0}}, pc_port_data_40} | {{32-PORT50_DWIDTH{1'b0}}, pc_port_data_50} |
                          {{32-PORT60_DWIDTH{1'b0}}, pc_port_data_60} | {{32-PORT70_DWIDTH{1'b0}}, pc_port_data_70} | {{32-PORT80_DWIDTH{1'b0}}, pc_port_data_80} | 
                            {{32-PORT90_DWIDTH{1'b0}}, pc_port_data_90} | {{32-PORTA0_DWIDTH{1'b0}}, pc_port_data_A0};

always @(posedge clk or negedge channel_reset_n) begin
    if (!channel_reset_n) begin
        np_free  <= 1'b1;			// during reset, empty is high, hence np_free is 1
    end
    else begin
        if (np_rxfifo_empty) begin
            np_free <= 1'b1;
        end
        else if (np_rxfifo_avail) begin
            np_free <= 1'b0;
        end
    end
end

always @(posedge clk or negedge channel_reset_n) begin
    if (!channel_reset_n) begin
        pc_free  <= 1'b1;           // during reset, empty is high, hence pc_free is 1
    end
    else begin
        if (pc_rxfifo_empty) begin
            pc_free <= 1'b1;
        end
        else if (pc_rxfifo_avail) begin
            pc_free <= 1'b0;
        end
    end
end

always @(posedge clk or negedge channel_reset_n) begin
    if (!channel_reset_n) begin
        np_rxfifo_avail  <= 1'b0;
    end
    else begin
        if (detect_put_np_rxfifo && rx_detect_crc_end && ~pc_error_condition && ~pec_mismatch) begin
            np_rxfifo_avail <= 1'b1;
        end
        else if (np_rxfifo_empty) begin
            np_rxfifo_avail <= 1'b0;
        end
    end
end

always @(posedge clk or negedge channel_reset_n) begin
    if (!channel_reset_n) begin
        pc_rxfifo_avail  <= 1'b0;
    end
    else begin
        if (detect_put_pc_rxfifo && rx_detect_crc_end && ~pc_error_condition && ~pec_mismatch) begin
            pc_rxfifo_avail <= 1'b1;
        end
        else if (pc_rxfifo_empty) begin
            pc_rxfifo_avail <= 1'b0;
        end
    end
end

always @(posedge clk or negedge channel_reset_n) begin
    if (!channel_reset_n) begin
        pc_channel_ready  <= 1'b0;
    end
    else begin
        pc_channel_ready <= pc_channel_en;
    end
end
							
always @(posedge clk or negedge channel_reset_n) begin
    if (!channel_reset_n) begin
        invalid_ioport_addr  <= 1'b0;
    end
    else begin
        if ((detect_iowr_short || detect_iord_short) && (rx_detect_header && spiclk_cnt_done_hl && 
		       ((header_byte[1] > `IOPORT_ADDR_AOH) || (header_byte[0] != 8'b00000000) || (header_byte[1][3:0] != 4'b0000)))) begin
            invalid_ioport_addr  <= 1'b1;  
        end
        else if (stop_det) begin
            invalid_ioport_addr  <= 1'b0;
        end
    end
end

always @(posedge clk or negedge channel_reset_n) begin
    if (!channel_reset_n) begin
        get_pc_rxfifo  <= 1'b0;
    end
    else begin
        if (read_pc_rxfifo) begin
            get_pc_rxfifo  <= 1'b1;  
        end
        else begin
            get_pc_rxfifo  <= 1'b0;
        end
    end
end

always @(posedge clk or negedge channel_reset_n) begin
    if (!channel_reset_n) begin
        get_np_rxfifo  <= 1'b0;
    end
    else begin
        if (read_np_rxfifo) begin
            get_np_rxfifo  <= 1'b1;  
        end
        else begin
            get_np_rxfifo  <= 1'b0;
        end
    end
end

assign get_pc_txfifo = (detect_get_pc_txfifo && spiclk_cnt_done_lh && (tx_gen_command || tx_gen_header || tx_gen_data) && ~pc_txfifo_empty);
assign get_np_txfifo = (detect_get_np_txfifo && spiclk_cnt_done_lh && (tx_gen_command || tx_gen_header || tx_gen_data) && ~np_txfifo_empty);

espi_fifo #(
    .DSIZE  (8),
    .DEPTH  (PC_RXFIFO_SIZE),			
    .WIDTHU (PC_RXFIFO_WIDTHU),
    .FAMILY (DEVICE_FAMILY)
) pc_rxfifo_inst (
    .clk          (clk),
    .rst_n        (channel_reset_n && ~flush_pc_fifo),
    .put          (put_pc_rxfifo),
    .get          (get_pc_rxfifo),
    .wdata        (pc_rxfifo_wdata),
    .full         (pc_rxfifo_full),                  
    .empty        (pc_rxfifo_empty),
    .rdata        (pc_rxfifo_rdata),
    .usedw        ()
);

espi_fifo #(
    .DSIZE  (8),
    .DEPTH  (PC_RXFIFO_SIZE),			
    .WIDTHU (PC_RXFIFO_WIDTHU),
    .FAMILY (DEVICE_FAMILY)
) np_rxfifo_inst (
    .clk          (clk),
    .rst_n        (channel_reset_n && ~flush_pc_fifo),
    .put          (put_np_rxfifo),
    .get          (get_np_rxfifo),
    .wdata        (np_rxfifo_wdata),
    .full         (np_rxfifo_full),                  
    .empty        (np_rxfifo_empty),
    .rdata        (np_rxfifo_rdata),
    .usedw        ()
);

espi_fifo #(
    .DSIZE  (8),
    .DEPTH  (PC_TXFIFO_SIZE),			
    .WIDTHU (PC_TXFIFO_WIDTHU),
    .FAMILY (DEVICE_FAMILY)
) pc_txfifo_inst (
    .clk          (clk),
    .rst_n        (channel_reset_n),
    .put          (write_pc_txfifo),
    .get          (get_pc_txfifo),
    .wdata        (txfifo_wdata),
    .full         (pc_txfifo_full),                 
    .empty        (pc_txfifo_empty),
    .rdata        (pc_txfifo_rdata),
    .usedw        ()
);

espi_fifo #(
    .DSIZE  (8),
    .DEPTH  (PC_TXFIFO_SIZE),			
    .WIDTHU (PC_TXFIFO_WIDTHU),
    .FAMILY (DEVICE_FAMILY)
) np_txfifo_inst (
    .clk          (clk),
    .rst_n        (channel_reset_n),
    .put          (write_np_txfifo),
    .get          (get_np_txfifo),
    .wdata        (txfifo_wdata),
    .full         (np_txfifo_full),                 
    .empty        (np_txfifo_empty),
    .rdata        (np_txfifo_rdata),
    .usedw        ()
);

generate if (PC_PORT00_EN) begin : blk0
    if (PC_PORT00_OUTPUT) begin : blk0_0
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port00_out  <= {PORT00_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iowr_short && (rx_detect_data && spiclk_cnt_done_hl && (header_byte[1] == `IOPORT_ADDR_OOH))) begin  // check the header (address) during rx_detect_data phase and push data to the port
                    if (PORT00_DWIDTH == 8)
                        pc_port00_out  <= data_byte[0];
                    else if (PORT00_DWIDTH ==16)
                        pc_port00_out  <= {data_byte[1], data_byte[0]};
                    else if (PORT00_DWIDTH ==32)
                        pc_port00_out  <= {data_byte[3], data_byte[2], data_byte[1], data_byte[0]};
                end
            end
        end
        assign pc_port_data_00 = {PORT00_DWIDTH{1'b0}};
    end
    else begin		// INPUT PORT
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port_data_00   <= {PORT00_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iord_short && (rx_detect_header && spiclk_cnt_done_hl && (rx_hdr_array_cnt == 1) && (header_byte[1] == `IOPORT_ADDR_OOH))) begin
                    pc_port_data_00   <= pc_port00_in;
                end
                else if (stop_det) begin
                    pc_port_data_00   <= {PORT00_DWIDTH{1'b0}};
                end
            end
        end
        assign pc_port00_out = {PORT00_DWIDTH{1'b0}};
    end
end
else begin
    assign pc_port00_out = {PORT00_DWIDTH{1'b0}};
    assign pc_port_data_00 = {PORT00_DWIDTH{1'b0}};
end
			
if (PC_PORT10_EN) begin : blk1
    if (PC_PORT10_OUTPUT) begin : blk1_0
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port10_out  <= {PORT10_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iowr_short && (rx_detect_data && spiclk_cnt_done_hl && (header_byte[1] == `IOPORT_ADDR_1OH))) begin // check the header (address) during rx_detect_data phase and push data to the port
                    if (PORT10_DWIDTH == 8)
                        pc_port10_out  <= data_byte[0];
                    else if (PORT10_DWIDTH ==16)
                        pc_port10_out  <= {data_byte[1], data_byte[0]};
                    else if (PORT10_DWIDTH ==32)
                        pc_port10_out  <= {data_byte[3], data_byte[2], data_byte[1], data_byte[0]};
                end
            end
        end
        assign pc_port_data_10 = {PORT10_DWIDTH{1'b0}};
    end
    else begin
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port_data_10   <= {PORT10_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iord_short && (rx_detect_header && spiclk_cnt_done_hl && (rx_hdr_array_cnt == 1) && (header_byte[1] == `IOPORT_ADDR_1OH))) begin
                    pc_port_data_10   <= pc_port10_in;
                end
                else if (stop_det) begin
                    pc_port_data_10   <= {PORT10_DWIDTH{1'b0}};
                end
            end
        end
        assign pc_port10_out = {PORT10_DWIDTH{1'b0}};
    end
end
else begin
    assign pc_port10_out = {PORT10_DWIDTH{1'b0}};
    assign pc_port_data_10 = {PORT10_DWIDTH{1'b0}};
end

if (PC_PORT20_EN) begin : blk2
    if (PC_PORT20_OUTPUT) begin : blk2_0
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port20_out  <= {PORT20_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iowr_short && (rx_detect_data && spiclk_cnt_done_hl && (header_byte[1] == `IOPORT_ADDR_2OH))) begin // check the header (address) during rx_detect_data phase and push data to the port
                    if (PORT20_DWIDTH == 8)
                        pc_port20_out  <= data_byte[0];
                    else if (PORT20_DWIDTH ==16)
                        pc_port20_out  <= {data_byte[1], data_byte[0]};
                    else if (PORT20_DWIDTH ==32)
                        pc_port20_out  <= {data_byte[3], data_byte[2], data_byte[1], data_byte[0]};
                end
            end
        end
        assign pc_port_data_20 = {PORT20_DWIDTH{1'b0}};
    end
    else begin
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port_data_20   <= {PORT20_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iord_short && (rx_detect_header && spiclk_cnt_done_hl && (rx_hdr_array_cnt == 1) && (header_byte[1] == `IOPORT_ADDR_2OH))) begin
                    pc_port_data_20   <= pc_port20_in;
                end
                else if (stop_det) begin
                    pc_port_data_20   <= {PORT20_DWIDTH{1'b0}};
                end
            end
        end
        assign pc_port20_out = {PORT20_DWIDTH{1'b0}};
    end
end
else begin
    assign pc_port20_out = {PORT20_DWIDTH{1'b0}};
    assign pc_port_data_20 = {PORT20_DWIDTH{1'b0}};
end

if (PC_PORT30_EN) begin : blk3
    if (PC_PORT30_OUTPUT) begin : blk3_0
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port30_out  <= {PORT30_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iowr_short && (rx_detect_data && spiclk_cnt_done_hl && (header_byte[1] == `IOPORT_ADDR_3OH))) begin // check the header (address) during rx_detect_data phase and push data to the port
                    if (PORT30_DWIDTH == 8)
                        pc_port30_out  <= data_byte[0];
                    else if (PORT30_DWIDTH ==16)
                        pc_port30_out  <= {data_byte[1], data_byte[0]};
                    else if (PORT30_DWIDTH ==32)
                        pc_port30_out  <= {data_byte[3], data_byte[2], data_byte[1], data_byte[0]};
                end
            end
        end
        assign pc_port_data_30 = {PORT30_DWIDTH{1'b0}};
    end
    else begin
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port_data_30   <= {PORT30_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iord_short && (rx_detect_header && spiclk_cnt_done_hl && (rx_hdr_array_cnt == 1) && (header_byte[1] == `IOPORT_ADDR_3OH))) begin
                    pc_port_data_30   <= pc_port30_in;
                end
                else if (stop_det) begin
                    pc_port_data_30   <= {PORT30_DWIDTH{1'b0}};
                end
            end
        end
        assign pc_port30_out = {PORT30_DWIDTH{1'b0}};
    end
end
else begin
    assign pc_port30_out = {PORT30_DWIDTH{1'b0}};
    assign pc_port_data_30 = {PORT30_DWIDTH{1'b0}};
end

if (PC_PORT40_EN) begin : blk4
    if (PC_PORT40_OUTPUT) begin : blk4_0
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port40_out  <= {PORT40_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iowr_short && (rx_detect_data && spiclk_cnt_done_hl && (header_byte[1] == `IOPORT_ADDR_4OH))) begin // check the header (address) during rx_detect_data phase and push data to the port
                    if (PORT40_DWIDTH == 8)
                        pc_port40_out  <= data_byte[0];
                    else if (PORT40_DWIDTH ==16)
                        pc_port40_out  <= {data_byte[1], data_byte[0]};
                    else if (PORT40_DWIDTH ==32)
                        pc_port40_out  <= {data_byte[3], data_byte[2], data_byte[1], data_byte[0]};
                end
            end
        end
        assign pc_port_data_40 = {PORT40_DWIDTH{1'b0}};
    end
    else begin
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port_data_40   <= {PORT40_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iord_short && (rx_detect_header && spiclk_cnt_done_hl && (rx_hdr_array_cnt == 1) && (header_byte[1] == `IOPORT_ADDR_4OH))) begin
                    pc_port_data_40   <= pc_port40_in;
                end
                else if (stop_det) begin
                    pc_port_data_40   <= {PORT40_DWIDTH{1'b0}};
                end
            end
        end
        assign pc_port40_out = {PORT40_DWIDTH{1'b0}};
    end
end
else begin
    assign pc_port40_out = {PORT40_DWIDTH{1'b0}};
    assign pc_port_data_40 = {PORT40_DWIDTH{1'b0}};
end
			
if (PC_PORT50_EN) begin : blk5
    if (PC_PORT50_OUTPUT) begin : blk5_0
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port50_out  <= {PORT50_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iowr_short && (rx_detect_data && spiclk_cnt_done_hl && (header_byte[1] == `IOPORT_ADDR_5OH))) begin // check the header (address) during rx_detect_data phase and push data to the port
                    if (PORT50_DWIDTH == 8)
                        pc_port50_out  <= data_byte[0];
                    else if (PORT50_DWIDTH ==16)
                        pc_port50_out  <= {data_byte[1], data_byte[0]};
                    else if (PORT50_DWIDTH ==32)
                        pc_port50_out  <= {data_byte[3], data_byte[2], data_byte[1], data_byte[0]};
                end
            end
        end
        assign pc_port_data_50 = {PORT50_DWIDTH{1'b0}};
    end
    else begin
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port_data_50   <= {PORT50_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iord_short && (rx_detect_header && spiclk_cnt_done_hl && (rx_hdr_array_cnt == 1) && (header_byte[1] == `IOPORT_ADDR_5OH))) begin
                    pc_port_data_50   <= pc_port50_in;
                end
                else if (stop_det) begin
                    pc_port_data_50   <= {PORT50_DWIDTH{1'b0}};
                end
            end
        end
        assign pc_port50_out = {PORT50_DWIDTH{1'b0}};
    end
end
else begin
    assign pc_port50_out = {PORT50_DWIDTH{1'b0}};
    assign pc_port_data_50 = {PORT50_DWIDTH{1'b0}};
end
			
if (PC_PORT60_EN) begin : blk6
    if (PC_PORT60_OUTPUT) begin : blk6_0
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port60_out  <= {PORT60_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iowr_short && (rx_detect_data && spiclk_cnt_done_hl && (header_byte[1] == `IOPORT_ADDR_6OH))) begin // check the header (address) during rx_detect_data phase and push data to the port
                    if (PORT60_DWIDTH == 8)
                        pc_port60_out  <= data_byte[0];
                    else if (PORT60_DWIDTH ==16)
                        pc_port60_out  <= {data_byte[1], data_byte[0]};
                    else if (PORT60_DWIDTH ==32)
                        pc_port60_out  <= {data_byte[3], data_byte[2], data_byte[1], data_byte[0]};
                end
	    end
	end
        assign pc_port_data_60 = {PORT60_DWIDTH{1'b0}};
    end
    else begin
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port_data_60   <= {PORT60_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iord_short && (rx_detect_header && spiclk_cnt_done_hl && (rx_hdr_array_cnt == 1) && (header_byte[1] == `IOPORT_ADDR_6OH))) begin
                    pc_port_data_60   <= pc_port60_in;
                end
                else if (stop_det) begin
                    pc_port_data_60   <= {PORT60_DWIDTH{1'b0}};
                end
            end
        end
        assign pc_port60_out = {PORT60_DWIDTH{1'b0}};
    end
end
else begin
    assign pc_port60_out = {PORT60_DWIDTH{1'b0}};
    assign pc_port_data_60 = {PORT60_DWIDTH{1'b0}};
end

if (PC_PORT70_EN) begin : blk7
    if (PC_PORT70_OUTPUT) begin : blk7_0
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port70_out  <= {PORT70_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iowr_short && (rx_detect_data && spiclk_cnt_done_hl && (header_byte[1] == `IOPORT_ADDR_7OH))) begin // check the header (address) during rx_detect_data phase and push data to the port
                    if (PORT70_DWIDTH == 8)
                        pc_port70_out  <= data_byte[0];
                    else if (PORT70_DWIDTH ==16)
                        pc_port70_out  <= {data_byte[1], data_byte[0]};
                    else if (PORT70_DWIDTH ==32)
                        pc_port70_out  <= {data_byte[3], data_byte[2], data_byte[1], data_byte[0]};
                end
            end
        end
        assign pc_port_data_70 = {PORT70_DWIDTH{1'b0}};
    end
    else begin
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port_data_70   <= {PORT70_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iord_short && (rx_detect_header && spiclk_cnt_done_hl && (rx_hdr_array_cnt == 1) && (header_byte[1] == `IOPORT_ADDR_7OH))) begin
                    pc_port_data_70   <= pc_port70_in;
                end
                else if (stop_det) begin
                    pc_port_data_70   <= {PORT70_DWIDTH{1'b0}};
                end
            end
        end
        assign pc_port70_out = {PORT70_DWIDTH{1'b0}};
    end
end
else begin
    assign pc_port70_out = {PORT70_DWIDTH{1'b0}};
    assign pc_port_data_70 = {PORT70_DWIDTH{1'b0}};
end

if (PC_PORT80_EN) begin : blk8
    if (PC_PORT80_OUTPUT) begin : blk8_0
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port80_out  <= {PORT80_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iowr_short && (rx_detect_data && spiclk_cnt_done_hl && (header_byte[1] == `IOPORT_ADDR_8OH))) begin // check the header (address) during rx_detect_data phase and push data to the port
                    if (PORT80_DWIDTH == 8)
                        pc_port80_out  <= data_byte[0];
                    else if (PORT80_DWIDTH ==16)
                        pc_port80_out  <= {data_byte[1], data_byte[0]};
                    else if (PORT80_DWIDTH ==32)
                        pc_port80_out  <= {data_byte[3], data_byte[2], data_byte[1], data_byte[0]};
                end
            end
        end
        assign pc_port_data_80 = {PORT80_DWIDTH{1'b0}};
    end
    else begin
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port_data_80   <= {PORT80_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iord_short && (rx_detect_header && spiclk_cnt_done_hl && (rx_hdr_array_cnt == 1) && (header_byte[1] == `IOPORT_ADDR_8OH))) begin
                    pc_port_data_80   <= pc_port80_in;
                end
                else if (stop_det) begin
                    pc_port_data_80   <= {PORT80_DWIDTH{1'b0}};
                end
            end
        end
        assign pc_port80_out = {PORT80_DWIDTH{1'b0}};
    end
end
else begin
    assign pc_port80_out = {PORT80_DWIDTH{1'b0}};
    assign pc_port_data_80 = {PORT80_DWIDTH{1'b0}};
end

if (PC_PORT90_EN) begin : blk9
    if (PC_PORT90_OUTPUT) begin : blk9_0
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port90_out  <= {PORT90_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iowr_short && (rx_detect_data && spiclk_cnt_done_hl && (header_byte[1] == `IOPORT_ADDR_9OH))) begin // check the header (address) during rx_detect_data phase and push data to the port
                    if (PORT90_DWIDTH == 8)
                        pc_port90_out  <= data_byte[0];
                    else if (PORT90_DWIDTH ==16)
                        pc_port90_out  <= {data_byte[1], data_byte[0]};
                    else if (PORT90_DWIDTH ==32)
                        pc_port90_out  <= {data_byte[3], data_byte[2], data_byte[1], data_byte[0]};
                end	
            end
        end
        assign pc_port_data_90 = {PORT90_DWIDTH{1'b0}};
    end
    else begin
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port_data_90   <= {PORT90_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iord_short && (rx_detect_header && spiclk_cnt_done_hl && (rx_hdr_array_cnt == 1) && (header_byte[1] == `IOPORT_ADDR_9OH))) begin
                    pc_port_data_90   <= pc_port90_in;
                end
                else if (stop_det) begin
                    pc_port_data_90   <= {PORT90_DWIDTH{1'b0}};
                end
            end
        end
        assign pc_port90_out = {PORT90_DWIDTH{1'b0}};
    end
end
else begin
    assign pc_port90_out = {PORT90_DWIDTH{1'b0}};
    assign pc_port_data_90 = {PORT90_DWIDTH{1'b0}};
end

if (PC_PORTA0_EN) begin : blk10
    if (PC_PORTA0_OUTPUT) begin : blk10_0
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_portA0_out  <= {PORTA0_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iowr_short && (rx_detect_data && spiclk_cnt_done_hl && (header_byte[1] == `IOPORT_ADDR_AOH))) begin // check the header (address) during rx_detect_data phase and push data to the port
                    if (PORTA0_DWIDTH == 8)
                        pc_portA0_out  <= data_byte[0];
                    else if (PORTA0_DWIDTH ==16)
                        pc_portA0_out  <= {data_byte[1], data_byte[0]};
                    else if (PORTA0_DWIDTH ==32)
                        pc_portA0_out  <= {data_byte[3], data_byte[2], data_byte[1], data_byte[0]};
                end	
	    end
	end
	assign pc_port_data_A0 = {PORTA0_DWIDTH{1'b0}};
    end
    else begin
        always @(posedge clk or negedge channel_reset_n) begin
            if (!channel_reset_n) begin
                pc_port_data_A0   <= {PORTA0_DWIDTH{1'b0}};
            end
            else begin
                if (detect_iord_short && (rx_detect_header && spiclk_cnt_done_hl && (rx_hdr_array_cnt == 1) && (header_byte[1] == `IOPORT_ADDR_AOH))) begin
                    pc_port_data_A0   <= pc_portA0_in;
                end
                else if (stop_det) begin
                    pc_port_data_A0   <= {PORTA0_DWIDTH{1'b0}};
                end
            end
        end
        assign pc_portA0_out = {PORTA0_DWIDTH{1'b0}};
    end
end
else begin
    assign pc_portA0_out = {PORTA0_DWIDTH{1'b0}};
    assign pc_port_data_A0 = {PORTA0_DWIDTH{1'b0}};
end

endgenerate 

endmodule
