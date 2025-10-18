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
//-- (ii) construct the response data byte if any -------------
//-- (iii) construst status byte if any -----------------------
//-- (iv) construct CRC byte if any ---------------------------
//-------------------------------------------------------------
`include "espi_header.iv"

`timescale 1 ps / 1 ps
module espi_tx_shifter #(
    parameter DWIDTH = 1
)(
    input                     clk,
    input                     ip_reset_n,
    input                     rx_detect_crc,
    input                     tx_with_cycletype,
    input                     detect_put_np_rxfifo,
    input                     error_condition1,
    input                     error_condition2,
    input                     invalid_ioport_addr,
    input                     stop_det,
    input                     start_det,
    input  [3:0]              resp_hdr_ptr,
    input  [6:0]              resp_data_ptr,
    input  [2:0]              resp_data_array,
    input  [1:0]              io_mode,  
    input                     spiclk_cnt_done_hl,
    input                     ws_counter_done,
    input [7:0]               resp_header,
    input [4:0]               resp_cycletype,
    input [2:0]               resp_cycletype_msb,
    input [7:0]               resp_data[4],
    input [7:0]               resp_status[2],
    input [7:0]               resp_crc,
    output logic [1:0]        tx_status_cnt, 
    output logic [2:0]        tx_data_array_cnt,
    output logic              tx_gen_waitstate,
    output logic              tx_gen_command,
    output logic              tx_gen_header,   
    output logic              tx_gen_cycletype,
    output logic              tx_gen_length_h,
    output logic              tx_gen_length_l,
    output logic              tx_gen_data,       
    output logic              tx_gen_status,     
    output logic              tx_gen_crc,
    output logic [7:0]        tx_dataout_byte,
    output logic [7:0]        resp_command,
    output logic              detect_tx_idle
);

localparam IDLE               = 3'b000;
localparam TX_GEN_WAITSTATE   = 3'b001;
localparam TX_GEN_CMD         = 3'b010;
localparam TX_GEN_CYCLETYPE   = 3'b011;
localparam TX_GEN_HDR         = 3'b100;
localparam TX_GEN_DATA        = 3'b101;
localparam TX_GEN_STATUS      = 3'b110;
localparam TX_GEN_CRC         = 3'b111;
localparam BYTE               = 8;
localparam STATUS_BYTE        = 2'd1;  // 2 byte minus 1

logic [7:0] resp_waitstate;
logic [2:0] resp_fsm_state, resp_fsm_nx_state;
logic [3:0] msb_byte, lsb_byte, tx_cnt_load_value, byte_time;
logic [6:0] tx_data_ptr_cnt;
logic [3:0] tx_hdr_ptr_cnt;
logic load_tx_cnt, decr_tx_cnt, tx_hdr_ptr_cnt_done, tx_status_cnt_done;
logic detect_txshiftstate, tx_data_ptr_cnt_done;

assign resp_waitstate = `WAIT_STATE;
assign detect_tx_idle = (resp_fsm_state == IDLE);
assign tx_data_ptr_cnt_done = (tx_data_ptr_cnt == (resp_data_ptr-7'h1));
assign tx_hdr_ptr_cnt_done = (tx_hdr_ptr_cnt == (resp_hdr_ptr-4'h1));
assign tx_status_cnt_done = (tx_status_cnt == STATUS_BYTE);
assign tx_gen_length_l = (tx_gen_header && tx_hdr_ptr_cnt == 4'd2);
assign tx_gen_length_h = (tx_gen_header && tx_hdr_ptr_cnt == 4'd1);
always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        resp_command <= 8'h0;
    end
    else if (error_condition2) begin
        resp_command <= `FATAL_ERROR;
    end
    else if (invalid_ioport_addr) begin
        resp_command <= `NON_FATAL_ERROR;
    end
    else if (detect_put_np_rxfifo) begin		// always defer non-posted read trans
        resp_command <= `DEFER;
    end
    else begin
        resp_command <= `ACCEPT;
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n)
        resp_fsm_state <= IDLE;
    else
        resp_fsm_state <= resp_fsm_nx_state;
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        tx_data_array_cnt <= 3'd0;
    end
    else begin
        if (tx_gen_data && spiclk_cnt_done_hl) begin
            if (tx_data_array_cnt < (resp_data_array - 3'd1)) begin		// count up until before the counter reach resp_data_array
                tx_data_array_cnt <= tx_data_array_cnt + 3'd1;
            end
            else begin
                tx_data_array_cnt <= 3'd0;
            end
        end
        else if (tx_gen_command) begin
            tx_data_array_cnt <= 3'd0;
        end
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        tx_data_ptr_cnt <= 7'd0;
    end
    else begin
        if (tx_gen_data && spiclk_cnt_done_hl) begin
            if (tx_data_ptr_cnt < (resp_data_ptr - 7'd1)) begin
                tx_data_ptr_cnt <= tx_data_ptr_cnt + 7'd1;
            end
            else begin
                tx_data_ptr_cnt <= 7'd0;
            end
        end
        else if (tx_gen_command) begin
            tx_data_ptr_cnt <= 7'd0;
        end
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        tx_hdr_ptr_cnt <= 4'd0;
    end
    else begin
        if (tx_gen_header && spiclk_cnt_done_hl) begin
            if (tx_hdr_ptr_cnt < (resp_hdr_ptr - 4'd1)) begin
                tx_hdr_ptr_cnt <= tx_hdr_ptr_cnt + 4'd1;
            end
            else begin
                tx_hdr_ptr_cnt <= 4'd0;
            end
        end
        else if (tx_gen_command) begin
            tx_hdr_ptr_cnt <= 4'd0;
        end
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        tx_status_cnt <= 2'd0;
    end
    else begin
        if (tx_gen_status && spiclk_cnt_done_hl) begin
            if (tx_status_cnt < STATUS_BYTE) begin
                tx_status_cnt <= tx_status_cnt + 2'd1;
            end
            else begin
                tx_status_cnt <= 2'd0;
            end
        end
        else if (tx_gen_command) begin
            tx_status_cnt <= 2'd0;
        end
    end
end

always @* begin
    case(resp_fsm_state)
        IDLE	: begin
            if (rx_detect_crc)
                resp_fsm_nx_state = TX_GEN_WAITSTATE;
            else 
                resp_fsm_nx_state = IDLE;
        end
        
        TX_GEN_WAITSTATE : begin
            if (stop_det)
                resp_fsm_nx_state = IDLE;	
            else if (error_condition1 && spiclk_cnt_done_hl)
                resp_fsm_nx_state = IDLE;
            else if (ws_counter_done)
                resp_fsm_nx_state = TX_GEN_CMD;
            else 
                resp_fsm_nx_state = TX_GEN_WAITSTATE;
        end
        
        TX_GEN_CMD : begin
            if (stop_det)
                resp_fsm_nx_state = IDLE;
            else if (spiclk_cnt_done_hl)
                if (error_condition2 || invalid_ioport_addr)
                    resp_fsm_nx_state = TX_GEN_STATUS;
                else if (tx_with_cycletype)
                    resp_fsm_nx_state = TX_GEN_CYCLETYPE;	
                else if (resp_hdr_ptr > 4'h0)												
                    resp_fsm_nx_state = TX_GEN_HDR;
                else if (resp_data_ptr > 7'h0)										
                    resp_fsm_nx_state = TX_GEN_DATA;
                else
                    resp_fsm_nx_state = TX_GEN_STATUS;
             else 
                 resp_fsm_nx_state = TX_GEN_CMD;
        end
        
        TX_GEN_CYCLETYPE: begin
            if (stop_det)
                resp_fsm_nx_state = IDLE;
            else if (spiclk_cnt_done_hl)
                resp_fsm_nx_state = TX_GEN_HDR;
            else
                resp_fsm_nx_state = TX_GEN_CYCLETYPE;
        end
        
        TX_GEN_HDR : begin
            if (stop_det)
                resp_fsm_nx_state = IDLE;
            else if (spiclk_cnt_done_hl)
                if (tx_hdr_ptr_cnt_done)
                    if (resp_data_ptr > 7'h0)	
                        resp_fsm_nx_state = TX_GEN_DATA;
                    else
                        resp_fsm_nx_state = TX_GEN_STATUS;
                else
                     resp_fsm_nx_state = TX_GEN_HDR;
            else
                resp_fsm_nx_state = TX_GEN_HDR;
        end
        
        TX_GEN_DATA : begin
            if (stop_det)
                resp_fsm_nx_state = IDLE;
            else if (spiclk_cnt_done_hl)
                if (tx_data_ptr_cnt_done)
                    resp_fsm_nx_state = TX_GEN_STATUS;
                else
                    resp_fsm_nx_state = TX_GEN_DATA;
            else 
                resp_fsm_nx_state = TX_GEN_DATA;
        end
        
        TX_GEN_STATUS : begin
            if (stop_det)
                resp_fsm_nx_state = IDLE;
            else if (spiclk_cnt_done_hl)
                if (tx_status_cnt_done)
                    resp_fsm_nx_state = TX_GEN_CRC;
                else
                    resp_fsm_nx_state = TX_GEN_STATUS;
            else 
                resp_fsm_nx_state = TX_GEN_STATUS;
        end
        
        TX_GEN_CRC : begin
            if (stop_det)
                resp_fsm_nx_state = IDLE;
            else if (spiclk_cnt_done_hl)
                resp_fsm_nx_state = IDLE;
            else 
                resp_fsm_nx_state = TX_GEN_CRC;
        end
        
        default: resp_fsm_nx_state = 3'b000;
    endcase
end

always @(posedge clk or negedge ip_reset_n) begin			
    if (!ip_reset_n) begin
        tx_gen_waitstate    <= 1'b0;
        tx_gen_command      <= 1'b0;
        tx_gen_cycletype    <= 1'b0;
        tx_gen_header       <= 1'b0;
        tx_gen_data         <= 1'b0;
        tx_gen_status       <= 1'b0;
        tx_gen_crc          <= 1'b0;
    end
    else begin
        case(resp_fsm_nx_state)
            IDLE : begin
                tx_gen_waitstate    <= 1'b0;
                tx_gen_command      <= 1'b0;
                tx_gen_cycletype    <= 1'b0;
                tx_gen_header       <= 1'b0;
                tx_gen_data         <= 1'b0;
                tx_gen_status       <= 1'b0;
                tx_gen_crc          <= 1'b0;
            end
            
            TX_GEN_WAITSTATE : begin
                tx_gen_waitstate    <= 1'b1;
                tx_gen_command      <= 1'b0;
                tx_gen_cycletype    <= 1'b0;
                tx_gen_header       <= 1'b0;
                tx_gen_data         <= 1'b0;
                tx_gen_status       <= 1'b0;
                tx_gen_crc          <= 1'b0;
            end
        
            TX_GEN_CMD : begin
                tx_gen_waitstate    <= 1'b0;
                tx_gen_command      <= 1'b1;
                tx_gen_cycletype    <= 1'b0;
                tx_gen_header       <= 1'b0;
                tx_gen_data         <= 1'b0;
                tx_gen_status       <= 1'b0;
                tx_gen_crc          <= 1'b0;
            end
        
            TX_GEN_CYCLETYPE : begin
                tx_gen_waitstate    <= 1'b0;
                tx_gen_command      <= 1'b0;
                tx_gen_cycletype    <= 1'b1;
                tx_gen_header       <= 1'b1;
                tx_gen_data         <= 1'b0;
                tx_gen_status       <= 1'b0;
                tx_gen_crc          <= 1'b0;
            end
        
            TX_GEN_HDR : begin
                tx_gen_waitstate    <= 1'b0;			
                tx_gen_command      <= 1'b0;
                tx_gen_cycletype    <= 1'b0;
                tx_gen_header       <= 1'b1;
                tx_gen_data         <= 1'b0;
                tx_gen_status       <= 1'b0;
                tx_gen_crc          <= 1'b0;
            end
        
            TX_GEN_DATA : begin
                tx_gen_waitstate    <= 1'b0;			
                tx_gen_command      <= 1'b0;
                tx_gen_cycletype    <= 1'b0;
                tx_gen_header       <= 1'b0;
                tx_gen_data         <= 1'b1;
                tx_gen_status       <= 1'b0;
                tx_gen_crc          <= 1'b0;
            end
        
            TX_GEN_STATUS : begin
                tx_gen_waitstate    <= 1'b0;			
                tx_gen_command      <= 1'b0;
                tx_gen_cycletype    <= 1'b0;
                tx_gen_header       <= 1'b0;
                tx_gen_data         <= 1'b0;
                tx_gen_status       <= 1'b1;
                tx_gen_crc          <= 1'b0;
            end
        
            TX_GEN_CRC : begin
                tx_gen_waitstate    <= 1'b0;			
                tx_gen_command      <= 1'b0;
                tx_gen_cycletype    <= 1'b0;
                tx_gen_header       <= 1'b0;
                tx_gen_data         <= 1'b0;
                tx_gen_status       <= 1'b0;
                tx_gen_crc          <= 1'b1;
            end
        
            default: begin
                tx_gen_waitstate    <= 1'b0;
                tx_gen_command      <= 1'b0;
                tx_gen_cycletype    <= 1'b0;
                tx_gen_header       <= 1'b0;
                tx_gen_data         <= 1'b0;
                tx_gen_status       <= 1'b0;
                tx_gen_crc          <= 1'b0;
            end
        endcase
    end
end

assign tx_dataout_byte = (tx_gen_waitstate) ? resp_waitstate : 
                           (tx_gen_command) ? resp_command :
                             (tx_gen_cycletype) ? {resp_cycletype_msb, resp_cycletype} :
                               (tx_gen_header) ? resp_header :
                                 (tx_gen_data) ? resp_data[tx_data_array_cnt] :
                                   (tx_gen_status) ? resp_status[tx_status_cnt] :
                                     (tx_gen_crc) ? resp_crc : {8{1'b0}};				 

							 
endmodule

