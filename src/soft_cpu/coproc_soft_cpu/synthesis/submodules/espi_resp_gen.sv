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


//-------------------------------------------------------------
//-- (i) this module decide which response to return ----------
//-- DERIVE DATA BYTE
//-- derive header byte
//-------------------------------------------------------------
`include "espi_header.iv"

`timescale 1 ps / 1 ps
module espi_resp_gen (
    input                  clk,
    input                  reset_n,
    input                  stop_det,
    input                  tx_gen_command,
    input                  tx_gen_data,
    input                  tx_gen_status,
    input                  tx_gen_header,
    input                  tx_gen_cycletype,
    input                  tx_gen_length_h,
    input                  tx_gen_length_l,
    input                  spiclk_cnt_done_hl,
    input                  spiclk_cnt_done_lh,
    input        [2:0]     tx_data_array_cnt,
    input        [15:0]    status_reg_dataout,
    input        [31:0]    config_reg_dataout,
    input        [31:0]    pc_port_data,
    input        [7:0]     txfifo_rdata,
    input                  detect_getvwire,
    input                  detect_getstatus,
    input                  detect_getconfig,
    input                  detect_setconfig,
    input                  detect_iord_short,
    input                  detect_iord_short1b,
    input                  detect_iord_short2b,
    input                  detect_iord_short4b,
    input                  detect_memrd_short,
    input                  detect_getpc,
    input                  detect_getnp,
    input        [15:0]    vw_data,
    input        [6:0]     vw_count,
    input                  vwire_avail,
    output logic [7:0]     resp_header,
    output logic [4:0]     resp_cycletype,
    output logic [2:0]     resp_cycletype_msb,
    output logic [7:0]     resp_data[4],
    output logic [7:0]     resp_status[2],
    output logic [3:0]     resp_hdr_ptr,
    output logic [6:0]     resp_data_ptr,
    output logic [2:0]     resp_data_array,
    output logic           pop_vw_databyte,
    output logic           detect_pc_rsp_withdata,
    output logic           tx_with_cycletype
);

logic detect_getconfig_reg, detect_iord_short_reg, detect_pc_rsp_withdata_reg, detect_memrd_short_reg;
logic detect_pc_rsp_withhdr_reg, detect_np_rsp_withhdr_reg, detect_getvwire_reg, tx_gen_header_reg;
logic pop_vw_databyte_reg, detect_pc_rsp_withhdr, detect_np_rsp_withhdr;
logic [3:0] resp_hdr_ptr_combi;
logic [6:0] vw_count_int, vw_count_reg;
logic [2:0] resp_data_array_combi;
logic [31:0] vw_data_int;
logic [15:0] status_reg_dataout_reg;
logic [6:0] resp_length, vw_count_cnt;

//---- further cycletype decode -------
// for all `LOCAL_MESSAGE cycletypes, (resp_cycletype[4:1] == 4'b1000)
// for `SUCCESSFUL_COMPLETE_DATA & UNSUCCESSFUL_COMPLETE cycletypes, (resp_cycletype[4:1] == 4'b0111)
// for resp_cycletype == `MEM_WRITE_32 || resp_cycletype == `MEM_WRITE_64, (~(|resp_cycletype[4:2]) && resp_cycletype[0])

assign detect_pc_rsp_withhdr = ((detect_getpc) && ((~(|resp_cycletype[4:2]) && resp_cycletype[0]) || 
                                 (resp_cycletype[4:1] == 4'b1000) || (resp_cycletype == `SUCCESSFUL_COMPLETE) || (resp_cycletype[4:1] == 4'b0111)));		
assign detect_pc_rsp_withdata = ((detect_getpc) && ((~(|resp_cycletype[4:2]) && resp_cycletype[0]) ||
                                 (resp_cycletype == `LOCAL_MESSAGE_DATA) || (resp_cycletype == `SUCCESSFUL_COMPLETE_DATA)));
assign detect_np_rsp_withhdr = (detect_getnp && (~(|resp_cycletype[4:2]) && ~resp_cycletype[0]));
assign tx_with_cycletype = (tx_gen_command && spiclk_cnt_done_hl && (detect_getpc || detect_getnp)) ? 1'b1 : 1'b0;
assign vw_data_int = {16'h0, vw_data};
assign vw_count_int = vw_count - 7'd1; 	// 0-base count
assign pop_vw_databyte = (detect_getvwire && (tx_gen_header || (tx_gen_data && tx_data_array_cnt == 3'd1)) && spiclk_cnt_done_lh && vwire_avail && vw_count_cnt > 7'd0) ? 1'b1 : 1'b0;
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        vw_count_cnt        <= 7'd0;
    end
    else begin
        if (detect_getvwire) begin
            if (pop_vw_databyte)
                vw_count_cnt        <= vw_count_cnt - 7'd1;
            else if (tx_gen_command && spiclk_cnt_done_hl)
                vw_count_cnt        <= vw_count_int + 7'd1;
        end
        else begin
                vw_count_cnt        <= 7'd0;
        end
    end	
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        resp_hdr_ptr         <= 4'h0;
    end
    else begin
        if (detect_getvwire) begin
            resp_hdr_ptr         <= 4'd1;
        end
        else if (detect_getpc || detect_getnp) begin
            if (|resp_cycletype_msb)		// invalid cycle type
                resp_hdr_ptr         <= 4'd1;
            else if ((resp_cycletype == `SUCCESSFUL_COMPLETE) || (resp_cycletype[4:1] == 4'b0111))
                resp_hdr_ptr         <= 4'd3;
            else if (~(|resp_cycletype[4:1]))    // MEM_READ_32 || MEM_WRITE_32
                resp_hdr_ptr         <= 4'd7;
            else if (resp_cycletype[4:1] == 4'b0001)  // MEM_READ_64 || MEM_WRITE_64
                resp_hdr_ptr         <= 4'd11;
            else if (resp_cycletype[4:1] == 4'b1000)  // LOCAL_MESSAGE || LOCAL_MESSAGE_DATA
                resp_hdr_ptr         <= 4'd8;
        end
        else begin
            resp_hdr_ptr         <= 4'd0;
        end
    end	
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        resp_data_ptr      <= 7'd0;
    end
    else begin
        if (detect_getvwire) begin
            resp_data_ptr      <= vw_count_reg << 7'd1;   // include vw_data and vw_index
        end
        else if (detect_iord_short1b)
            resp_data_ptr      <= 7'd1;
        else if (detect_iord_short2b)
            resp_data_ptr      <= 7'd2;
        else if (detect_iord_short4b)
            resp_data_ptr      <= 7'd4;
        else if ((detect_getpc || detect_getnp) && ~(|resp_cycletype_msb)) begin
            if (resp_cycletype == `SUCCESSFUL_COMPLETE_DATA)
                resp_data_ptr      <= resp_length; 
            else if (~(|resp_cycletype[4:2]) && resp_cycletype[0])    //MEM_WRITE_32 || MEM_WRITE_64
                resp_data_ptr      <= resp_length;
            else if (resp_cycletype == `LOCAL_MESSAGE_DATA)
                resp_data_ptr      <= resp_length;
        end
        else if (detect_getconfig) begin
            resp_data_ptr      <= 7'd4;
        end
        else begin
            resp_data_ptr      <= 7'd0;
        end
    end	
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        resp_data_array        <= 3'd0;
    end
    else begin
        if (detect_getvwire)
            resp_data_array        <= 3'd2;
        else if (resp_data_ptr > 7'd4)
            resp_data_array        <= 3'd4;
        else
            resp_data_array        <= resp_data_ptr[2:0];
    end	
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        resp_cycletype      <= 5'h0;
        resp_cycletype_msb  <= 3'h0;
    end
    else begin
        if (tx_gen_command && spiclk_cnt_done_hl && (detect_getpc || detect_getnp)) begin
            resp_cycletype      <= txfifo_rdata[4:0];
            resp_cycletype_msb  <= txfifo_rdata[7:5];
        end
        else if (stop_det) begin
            resp_cycletype      <= 5'h0;
            resp_cycletype_msb  <= 3'h0;
        end
    end	
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        resp_length      <= 7'h0;
    end
    else begin
        if (tx_gen_length_h && spiclk_cnt_done_hl && (detect_getpc || detect_getnp))
            resp_length      <= txfifo_rdata[6:0];
        else if (stop_det)
            resp_length      <= 7'h0;
    end	
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        vw_count_reg      <= 7'd0;
    end
    else begin
        if (detect_getvwire && tx_gen_command && spiclk_cnt_done_hl)					
            vw_count_reg      <= vw_count;		
    end	
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        detect_getconfig_reg        <= 1'b0;
        detect_iord_short_reg       <= 1'b0;
        detect_pc_rsp_withdata_reg  <= 1'b0;
        detect_memrd_short_reg      <= 1'b0;
        detect_pc_rsp_withhdr_reg   <= 1'b0;
        detect_np_rsp_withhdr_reg   <= 1'b0;
        detect_getvwire_reg         <= 1'b0;
        pop_vw_databyte_reg         <= 1'b0;
        //tx_gen_header_reg           <= 1'b0;
    end
    else begin
        detect_getconfig_reg        <= detect_getconfig;
        detect_iord_short_reg       <= detect_iord_short;
        detect_pc_rsp_withdata_reg  <= detect_pc_rsp_withdata;
        detect_memrd_short_reg      <= detect_memrd_short;
        detect_pc_rsp_withhdr_reg   <= detect_pc_rsp_withhdr;
        detect_np_rsp_withhdr_reg   <= detect_np_rsp_withhdr;
        detect_getvwire_reg         <= detect_getvwire;
        pop_vw_databyte_reg         <= pop_vw_databyte;
        //tx_gen_header_reg           <= tx_gen_header;
    end	
end

genvar i, j;
generate 
for (i=0; i<2; i++) begin : resp_status_blk0										// 2byte status
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            resp_status[i]        <= 8'd0;
        end
        else begin
            if (~tx_gen_status) begin		// update resp_status only when status register changes outside of tx_gen_status
                resp_status[i]        <= status_reg_dataout[((i+1)*8)-1 : i*8];
            end
        end	
    end
end

for (j=0; j<4; j++) begin : resp_data_blk1										// 4-byte config register data
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            resp_data[j]      <= 8'd0;
        end
        else begin   // update the resp_data one state earlier
            if (detect_getconfig_reg && tx_gen_command && spiclk_cnt_done_hl) begin					
                resp_data[j]      <= config_reg_dataout[((j+1)*8)-1 : j*8];
            end
            if (detect_iord_short_reg && tx_gen_command && spiclk_cnt_done_hl) begin					
                resp_data[j]      <= pc_port_data[((j+1)*8)-1 : j*8];
            end
            if (pop_vw_databyte_reg) begin
                resp_data[j]      <= vw_data_int[((j+1)*8)-1 : j*8];
            end
            if ((detect_pc_rsp_withdata_reg || detect_memrd_short_reg) && spiclk_cnt_done_hl && (tx_gen_header || tx_gen_data)) begin
                resp_data[j]      <= txfifo_rdata;
            end
        end	
    end
end
endgenerate 

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        resp_header      <= 8'd0;
    end
    else begin
        if (detect_getvwire_reg && tx_gen_command && spiclk_cnt_done_hl) begin
            resp_header      <= {1'd0, vw_count_int};
        end
        if ((detect_pc_rsp_withhdr_reg || detect_np_rsp_withhdr_reg) && spiclk_cnt_done_hl && tx_gen_header) begin
            resp_header      <= txfifo_rdata;
        end
    end	
end

endmodule
