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
module espi_rx_shifter #(
    parameter DWIDTH = 1,
    parameter DATABYTE_ARR = 2,
    parameter HDRBYTE_ARR = 3
)(
    input                                clk,
    input                                ip_reset_n,
    input                                invalid_cmd,
    input                                invalid_cycletype,
    input                                detect_reset,
    input                                spiclk_cnt_done_hl,
    input                                spiclk_cnt_done_lh,
    input  [7:0]                         rxshift_data,
    input                                start_det,
    input                                stop_det,
    input  [3:0]                         cmd_hdr_ptr,
    input  [6:0]                         cmd_data_ptr,	
    input  [2:0]                         cmd_data_array,
    input                                rx_with_cycletype,
    output logic [1:0]                   rx_hdr_array_cnt, 
    output logic [2:0]                   rx_data_array_cnt,
    output logic [7:0]                   command_byte, 
    output logic [7:0]                   command_byte_duplic,
    output logic [7:0]                   command_byte_duplic2,
    output logic [7:0]                   command_byte_duplic3,
    output logic [7:0]                   header_byte[HDRBYTE_ARR], 	
    output logic [7:0]                   data_byte[DATABYTE_ARR], 
    output logic [7:0]                   crc_byte,
    output logic [4:0]                   cycletype_byte,
    output logic [4:0]                   cycletype_byte_duplic,
    output logic [2:0]                   cmd_cycletype_msb,
    output logic [6:0]                   length_byte,
    output logic [63:0]                  addr_byte,
    output logic                         rx_detect_command, 
    output logic                         rx_detect_header,
    output logic                         rx_detect_data,
    output logic                         rx_detect_crc,
    output logic                         rx_detect_cycletype_end,
    output logic                         rx_detect_command_end,
    output logic                         rx_detect_header_end,
    output logic                         rx_detect_data_end,
    output logic                         rx_detect_crc_end,
    output logic                         detect_rx_idle
);

localparam IDLE                = 3'b000;
localparam RX_DET_CMD          = 3'b001;
localparam RX_DET_CYCLETYPE    = 3'b010;
localparam RX_DET_HDR          = 3'b011;
localparam RX_DET_DATA         = 3'b100;
localparam RX_DET_CRC          = 3'b101;
localparam BYTE                = 8;

logic rx_hdr_ptr_cnt_done, rx_data_ptr_cnt_done, rx_detect_cycletype, rx_detect_length, rx_detect_header_duplic, spiclk_cnt_done_hl_nxt;
logic [2:0] rx_shiftfsm_state, rx_shiftfsm_nx_state;
logic [2:0] cmd_hdr_array;
logic [6:0] rx_data_ptr_cnt;
logic [3:0] rx_hdr_ptr_cnt;

assign cmd_hdr_array = (cmd_hdr_ptr > 4'd4) ? 3'd4 : cmd_hdr_ptr[2:0];
assign rx_hdr_ptr_cnt_done = rx_detect_header_duplic && (rx_hdr_ptr_cnt == (cmd_hdr_ptr - 4'h1));
assign rx_data_ptr_cnt_done = (rx_data_ptr_cnt == (cmd_data_ptr - 7'h1));
assign rx_detect_cycletype_end = (rx_detect_cycletype && spiclk_cnt_done_hl_nxt);
assign rx_detect_command_end = (rx_detect_command && spiclk_cnt_done_hl_nxt);
assign rx_detect_header_end = (rx_detect_header_duplic && rx_hdr_ptr_cnt_done && spiclk_cnt_done_hl_nxt);
assign rx_detect_data_end = (rx_detect_data && rx_data_ptr_cnt_done && spiclk_cnt_done_hl_nxt);
assign rx_detect_crc_end = (rx_detect_crc && spiclk_cnt_done_hl_nxt);
assign rx_detect_length = (rx_detect_header_duplic && rx_hdr_ptr_cnt <= 4'd2 && rx_hdr_ptr_cnt != 4'd0);
assign detect_rx_idle = (rx_shiftfsm_state == IDLE);

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n)
        rx_shiftfsm_state <= IDLE;
    else
        rx_shiftfsm_state <= rx_shiftfsm_nx_state;
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n)
        spiclk_cnt_done_hl_nxt <= 1'b0;
    else
        spiclk_cnt_done_hl_nxt <= spiclk_cnt_done_hl;
end

always @* begin
    case(rx_shiftfsm_state)
        IDLE	: begin
            if (start_det)
                rx_shiftfsm_nx_state = RX_DET_CMD;
            else 
                rx_shiftfsm_nx_state = IDLE;
        end
        
        RX_DET_CMD : begin
            if (stop_det || invalid_cmd)
                rx_shiftfsm_nx_state = IDLE;	
            else if (spiclk_cnt_done_hl_nxt)
                if (rx_with_cycletype)
                    rx_shiftfsm_nx_state = RX_DET_CYCLETYPE;				
                else if (cmd_hdr_ptr > 4'd0)
                    rx_shiftfsm_nx_state = RX_DET_HDR;
                else if (detect_reset) 
                    rx_shiftfsm_nx_state = IDLE;
                else
                    rx_shiftfsm_nx_state = RX_DET_CRC;			//crc is mandatory
            else 
                rx_shiftfsm_nx_state = RX_DET_CMD;
        end
        
        RX_DET_CYCLETYPE : begin
            if (stop_det || invalid_cycletype)
                rx_shiftfsm_nx_state = IDLE;
            else if (spiclk_cnt_done_hl_nxt)
                rx_shiftfsm_nx_state = RX_DET_HDR;
            else 
                rx_shiftfsm_nx_state = RX_DET_CYCLETYPE;
        end
        
        RX_DET_HDR : begin
            if (stop_det)
                rx_shiftfsm_nx_state = IDLE;
            else if (spiclk_cnt_done_hl_nxt)
                if (rx_hdr_ptr_cnt_done)
            	    if (cmd_data_ptr > 7'd0)
            		    rx_shiftfsm_nx_state = RX_DET_DATA;
            	    else 
            		    rx_shiftfsm_nx_state = RX_DET_CRC;        //crc is mandatory
                else
            	    rx_shiftfsm_nx_state = RX_DET_HDR;         
            else
            	rx_shiftfsm_nx_state = RX_DET_HDR;
        end
        
        RX_DET_DATA : begin
            if (stop_det)
                rx_shiftfsm_nx_state = IDLE;
            else if (spiclk_cnt_done_hl_nxt)
                if (rx_data_ptr_cnt_done)							
                    rx_shiftfsm_nx_state = RX_DET_CRC;				//crc is mandatory
                else 
                    rx_shiftfsm_nx_state = RX_DET_DATA;
            else
                rx_shiftfsm_nx_state = RX_DET_DATA;
        end
        
        RX_DET_CRC : begin
            if (stop_det)
                rx_shiftfsm_nx_state = IDLE;
            else if (spiclk_cnt_done_hl_nxt)
                rx_shiftfsm_nx_state = IDLE;
            else 
                rx_shiftfsm_nx_state = RX_DET_CRC;
        end
        
        default: rx_shiftfsm_nx_state = 3'b000;
    endcase
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        rx_detect_command           <= 1'b0;
        rx_detect_cycletype         <= 1'b0;
        rx_detect_header            <= 1'b0;
        rx_detect_header_duplic     <= 1'b0;
        rx_detect_data              <= 1'b0;
        rx_detect_crc               <= 1'b0;
    end
    else begin
        case(rx_shiftfsm_nx_state)
            IDLE : begin
                rx_detect_command           <= 1'b0;
                rx_detect_cycletype         <= 1'b0;
                rx_detect_header            <= 1'b0;
                rx_detect_header_duplic     <= 1'b0;
                rx_detect_data              <= 1'b0;
                rx_detect_crc               <= 1'b0;
            end
            
            RX_DET_CMD : begin
                rx_detect_command           <= 1'b1;
                rx_detect_cycletype         <= 1'b0;
                rx_detect_header            <= 1'b0;
                rx_detect_header_duplic     <= 1'b0;
                rx_detect_data              <= 1'b0;
                rx_detect_crc               <= 1'b0;
            end
            
            RX_DET_CYCLETYPE : begin
                rx_detect_header            <= 1'b1;
                rx_detect_header_duplic     <= 1'b1;
                rx_detect_cycletype         <= 1'b1;
                rx_detect_command           <= 1'b0;
                rx_detect_data              <= 1'b0;
                rx_detect_crc               <= 1'b0;
            end
            
            RX_DET_HDR : begin
                rx_detect_header            <= 1'b1;
                rx_detect_header_duplic     <= 1'b1;
                rx_detect_cycletype         <= 1'b0;
                rx_detect_command           <= 1'b0;
                rx_detect_data              <= 1'b0;
                rx_detect_crc               <= 1'b0;
            end
            
            RX_DET_DATA : begin
                rx_detect_data              <= 1'b1;
                rx_detect_command           <= 1'b0;
                rx_detect_cycletype         <= 1'b0;
                rx_detect_header            <= 1'b0;
                rx_detect_header_duplic     <= 1'b0;
                rx_detect_crc               <= 1'b0;
            end
            
            RX_DET_CRC : begin
                rx_detect_crc               <= 1'b1;
                rx_detect_data              <= 1'b0;
                rx_detect_header            <= 1'b0;
                rx_detect_header_duplic     <= 1'b0;
                rx_detect_cycletype         <= 1'b0;
                rx_detect_command           <= 1'b0;
            end
            
            default: begin
                rx_detect_command           <= 1'b0;
                rx_detect_header            <= 1'b0;
                rx_detect_header_duplic     <= 1'b0;
                rx_detect_data              <= 1'b0;
                rx_detect_cycletype         <= 1'b0;
                rx_detect_crc               <= 1'b0;
            end
        endcase
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        rx_hdr_array_cnt <= 2'd0;
    end
    else begin
        if (rx_detect_header_duplic && spiclk_cnt_done_hl_nxt) begin	
            if (rx_hdr_array_cnt < cmd_hdr_array - 2'd1) begin
                rx_hdr_array_cnt <= rx_hdr_array_cnt + 2'd1;
            end
            else begin
                rx_hdr_array_cnt <= 2'd0;
            end
        end
        else if (rx_detect_command) begin
            rx_hdr_array_cnt <= 2'd0;
        end
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        rx_hdr_ptr_cnt <= 4'd0;
    end
    else begin
        if (rx_detect_header_duplic && spiclk_cnt_done_hl_nxt) begin	
            if (rx_hdr_ptr_cnt < cmd_hdr_ptr - 4'd1) begin
                rx_hdr_ptr_cnt <= rx_hdr_ptr_cnt + 4'd1;
            end
            else begin
                rx_hdr_ptr_cnt <= 4'd0;
            end
        end
        else if (rx_detect_command) begin
            rx_hdr_ptr_cnt <= 4'd0;
        end
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        rx_data_array_cnt <= 3'd0;
    end
    else begin
        if (rx_detect_data && spiclk_cnt_done_hl_nxt) begin
            if (rx_data_array_cnt < (cmd_data_array - 3'd1)) begin		// count up until before the counter reach cmd_data_array
                rx_data_array_cnt <= rx_data_array_cnt + 3'd1;
            end
            else begin
                rx_data_array_cnt <= 3'd0;
            end
        end
        else if (rx_detect_command) begin
            rx_data_array_cnt <= 3'd0;
        end
    end
end


always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        rx_data_ptr_cnt <= 7'd0;
    end
    else begin
        if (rx_detect_data && spiclk_cnt_done_hl_nxt) begin
            if (rx_data_ptr_cnt < cmd_data_ptr - 7'd1) begin
                rx_data_ptr_cnt <= rx_data_ptr_cnt + 7'd1;
            end
            else begin
                rx_data_ptr_cnt <= 7'd0;
            end
        end
        else if (rx_detect_command) begin
            rx_data_ptr_cnt <= 7'd0;
        end
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        command_byte <= {BYTE{1'b0}};
    end
    else if (rx_detect_command && spiclk_cnt_done_lh) begin
        command_byte <= rxshift_data;
    end
    else if (stop_det) begin
        command_byte <= {BYTE{1'b0}};
    end
end

//--------- duplicate command_byte register for timing issue ------------
always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        command_byte_duplic <= {BYTE{1'b0}};
    end
    else if (rx_detect_command && spiclk_cnt_done_lh) begin
        command_byte_duplic <= rxshift_data;
    end
    else if (stop_det) begin
        command_byte_duplic <= {BYTE{1'b0}};
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        command_byte_duplic2 <= {BYTE{1'b0}};
    end
    else if (rx_detect_command && spiclk_cnt_done_lh) begin
        command_byte_duplic2 <= rxshift_data;
    end
    else if (stop_det) begin
        command_byte_duplic2 <= {BYTE{1'b0}};
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        command_byte_duplic3 <= {BYTE{1'b0}};
    end
    else if (rx_detect_command && spiclk_cnt_done_lh) begin
        command_byte_duplic3 <= rxshift_data;
    end
    else if (stop_det) begin
        command_byte_duplic3 <= {BYTE{1'b0}};
    end
end
//------------------------------------------------------------------------

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        header_byte <= '{{BYTE{1'b0}}, {BYTE{1'b0}}, {BYTE{1'b0}}, {BYTE{1'b0}}};			// reserved 3 entries to keep track of length at Byte1 and Byte2
    end
    else if (rx_detect_header_duplic && spiclk_cnt_done_lh) begin
        header_byte[rx_hdr_array_cnt] <= rxshift_data;
    end
    else if (stop_det) begin
        header_byte <= '{{BYTE{1'b0}}, {BYTE{1'b0}}, {BYTE{1'b0}}, {BYTE{1'b0}}};
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        cycletype_byte     <= {5{1'b0}};
        cmd_cycletype_msb <= {3{1'b0}};
    end
    else if (rx_detect_cycletype && spiclk_cnt_done_lh) begin
        cycletype_byte     <= rxshift_data[4:0];
        cmd_cycletype_msb <= rxshift_data[7:5];
    end
    else if (stop_det) begin
        cycletype_byte     <= {5{1'b0}};
        cmd_cycletype_msb <= {3{1'b0}};
    end
end

//--------- duplicate cycletype_byte register for timing issue ------------
always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        cycletype_byte_duplic <= {5{1'b0}};
    end
    else if (rx_detect_cycletype && spiclk_cnt_done_lh) begin
        cycletype_byte_duplic <= rxshift_data[4:0];
    end
    else if (stop_det) begin
        cycletype_byte_duplic <= {5{1'b0}};
    end
end
//------------------------------------------------------------------------

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        addr_byte <= {64{1'b0}};				// to capture address bytes from header bytes
    end
    else if ((rx_detect_header && ~rx_detect_cycletype && ~rx_detect_length) && spiclk_cnt_done_lh) begin
        addr_byte <= {addr_byte[55:0], rxshift_data};
    end
    else if (stop_det) begin
        addr_byte <= {64{1'b0}};
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        data_byte <= '{{BYTE{1'b0}}, {BYTE{1'b0}}, {BYTE{1'b0}}, {BYTE{1'b0}}};					// max reserved 4 entries to keep track of set_config data
    end
    else if (rx_detect_data && spiclk_cnt_done_lh) begin
        data_byte[rx_data_array_cnt] <= rxshift_data;
    end
    else if (stop_det) begin
        data_byte <= '{{BYTE{1'b0}}, {BYTE{1'b0}}, {BYTE{1'b0}}, {BYTE{1'b0}}};
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        crc_byte <= {BYTE{1'b0}};
    end
    else if (rx_detect_crc && spiclk_cnt_done_lh) begin
        crc_byte <= rxshift_data;
    end
    else if (stop_det) begin
        crc_byte <= {BYTE{1'b0}};
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        length_byte <= {7{1'b0}};
    end
    else if (rx_detect_length && spiclk_cnt_done_hl && rx_hdr_ptr_cnt == 4'd2) begin
        //if ({header_byte[1][3:0], header_byte[2]} == {12{1'b0}}) begin				// only support 64 byte
        //    length_byte <= 13'd4096;
        //end
        //else begin
        //    length_byte <= {1'b0, header_byte[1][3:0], header_byte[2]};
        //end
        length_byte <= header_byte[2][6:0];
    end
    else if (stop_det) begin
        length_byte <= {7{1'b0}};
    end
end


endmodule
