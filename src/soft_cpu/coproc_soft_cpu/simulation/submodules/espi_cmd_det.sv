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
module espi_cmd_det #(
    parameter DATABYTE_ARR = 2,
    parameter HDRBYTE_ARR = 4
)(
    input                             clk,
    input                             reset_n,
    input                             stop_det,
    input                             rx_detect_command_end,
    input                             rx_detect_cycletype_end,
    input                             rx_detect_header,
    input [7:0]                       header_byte[HDRBYTE_ARR],
    input [7:0]                       data_byte[DATABYTE_ARR],
    input [7:0]                       command_byte,
    input [7:0]                       command_byte_duplic,
    input [7:0]                       command_byte_duplic2,
    input [7:0]                       command_byte_duplic3,
    input [6:0]                       length_byte, 
    input [4:0]                       cycletype_byte,
    input [4:0]                       cycletype_byte_duplic,
    input [2:0]                       cmd_cycletype_msb,
    input [7:0]                       crc_byte,  
    output logic [15:0]               config_reg_addr,
    output logic [31:0]               config_reg_datain,
    output logic [3:0]                cmd_hdr_ptr,
    output logic [6:0]                cmd_data_ptr,
    output logic [2:0]                cmd_data_array,
    output logic                      detect_getvwire,
    output logic                      detect_getstatus,
    output logic                      detect_getconfig,
    output logic                      detect_setconfig,
    output logic                      detect_putpc,
    output logic                      detect_putnp,
    output logic                      detect_getpc,
    output logic                      detect_getnp,
    output logic                      detect_putvwire,
    output logic                      detect_put_np_rxfifo,
    output logic                      detect_put_pc_rxfifo,
    output logic                      detect_get_np_txfifo,   
    output logic                      detect_get_pc_txfifo,   
    output logic                      detect_pc_cmd_withdata,
    output logic                      detect_iord_short,
    output logic                      detect_iowr_short,
    output logic                      detect_iord_short1b,
    output logic                      detect_iord_short2b,
    output logic                      detect_iord_short4b,
    output logic                      detect_memrd_short,
    output logic                      detect_reset,
    output logic                      invalid_cmd,
    output logic                      invalid_cycletype,
    output logic                      rx_with_cycletype,
    output logic [7:0]                vw_data_ptr,
    output logic [3:0]                addr_ptr
	
);

logic detect_ch0_cmd, detect_ch1_cmd, detect_config_cmd, detect_ioshort_cmd, detect_memshort_cmd, detect_memwr_short;
logic [3:0] length_ptr, cmd_hdr_ptr_combi;
logic [6:0] cmd_data_ptr_combi;
logic [7:0] vw_data_ptr_int;

//---- further command decode -------
// for all `PUT_IORD_SHORT command,  (command_byte[7:2] == 6'b010000)
// for all `PUT_IOWR_SHORT command,  (command_byte[7:2] == 6'b010001)
// for all `PUT_MEMRD_SHORT command, (command_byte[7:2] == 6'b010010)
// for all `PUT_MEMWR_SHORT command, (command_byte[7:2] == 6'b010011)

assign detect_reset          = (command_byte == `RESET);
assign detect_getvwire       = (command_byte == `GET_VWIRE);
assign detect_putvwire       = (command_byte_duplic == `PUT_VWIRE);
assign detect_getstatus      = (command_byte == `GET_STATUS);
assign detect_putnp          = (command_byte_duplic2 == `PUT_NP);
assign detect_putpc          = (command_byte_duplic == `PUT_PC);
assign detect_getpc          = (command_byte_duplic2 == `GET_PC);
assign detect_getnp          = (command_byte_duplic2 == `GET_NP);
assign detect_iord_short1b   = (command_byte_duplic3 == `PUT_IORD_SHORT_1B);
assign detect_iord_short2b   = (command_byte_duplic3 == `PUT_IORD_SHORT_2B);
assign detect_iord_short4b   = (command_byte_duplic3 == `PUT_IORD_SHORT_4B);
assign detect_getconfig      = (command_byte_duplic == `GET_CONFIGURATION);
assign detect_setconfig      = (command_byte_duplic == `SET_CONFIGURATION);
assign detect_iord_short     = (command_byte_duplic3[7:2] == 6'b010000);
assign detect_iowr_short     = (command_byte_duplic[7:2] == 6'b010001);
assign detect_memrd_short    = (command_byte_duplic3[7:2] == 6'b010010);
assign detect_memwr_short    = (command_byte_duplic[7:2] == 6'b010011);

assign detect_pc_cmd_withdata = ((detect_putpc) && ((~(|cycletype_byte_duplic[4:2]) && cycletype_byte_duplic[0]) ||  // MEM_WRITE_32 || MEM_WRITE_64
                                    cycletype_byte_duplic == `LOCAL_MESSAGE_DATA || cycletype_byte == `SUCCESSFUL_COMPLETE_DATA));		
assign detect_ioshort_cmd   = (detect_iord_short || detect_iowr_short);
assign detect_memshort_cmd  = (detect_memrd_short || detect_memwr_short);
assign detect_put_np_rxfifo = (detect_putnp || detect_memrd_short);
assign detect_put_pc_rxfifo = (detect_putpc || detect_memwr_short);
assign detect_config_cmd    = (detect_getconfig || detect_setconfig);
assign detect_get_np_txfifo = (detect_getnp);
assign detect_get_pc_txfifo = (detect_getpc);

assign detect_ch0_cmd = (detect_put_np_rxfifo || detect_put_pc_rxfifo || detect_get_np_txfifo || detect_get_pc_txfifo);

assign detect_ch1_cmd = (command_byte[7:1] == 7'b0000010);  // PUT_VWIRE || GET_VWIRE

assign cmd_hdr_ptr_combi = (detect_putpc || detect_putnp) ? addr_ptr + length_ptr + 4'd1 :  // + 1 is for cycletype byte
                             (detect_ioshort_cmd) ? 4'd2 :
                               (detect_memshort_cmd) ? 4'd4 :
                                 (detect_putvwire) ? 4'd1 : 
                                   (detect_config_cmd) ? 4'd2 : 4'd0;   // for config_command, address is 16-bit wide (2bytes)
						   
assign rx_with_cycletype = (rx_detect_command_end && (~(|command_byte[7:2]) && ~command_byte[0])) ? 1'b1 : 1'b0;  // detect_putnp || detect_putpc

assign cmd_data_array = (detect_putvwire) ? 3'd2 : 3'd4;
						
assign vw_data_ptr_int = vw_data_ptr + 8'd1;
assign cmd_data_ptr_combi   = (detect_pc_cmd_withdata) ? length_byte : 
                                (command_byte[7:4] == 4'b0100) && (command_byte[2:0] == 3'b100) ? 7'd1 :			// PUT_IOWR_SHORT_1B || PUT_MEMWR32_SHORT_1B
                                  (command_byte[7:4] == 4'b0100) && (command_byte_duplic[2:0] == 3'b101) ? 7'd2 :    // PUT_IOWR_SHORT_2B || PUT_MEMWR32_SHORT_2B
                                    (command_byte[7:4] == 4'b0100) && (command_byte_duplic2[2:0] == 3'b111) ? 7'd4 :   // PUT_IOWR_SHORT_4B || PUT_MEMWR32_SHORT_4B
                                      (detect_putvwire) ? vw_data_ptr_int[6:0] << 7'd1 :   //include vw_index and vw_data 
                                        (detect_setconfig) ? 7'd4 : 7'd0;
assign invalid_cmd = (rx_detect_command_end && (~(detect_ch0_cmd || detect_ch1_cmd || detect_iord_short || detect_iowr_short || detect_config_cmd || detect_getstatus || detect_reset))); 
assign invalid_cycletype = (rx_detect_cycletype_end && (((addr_ptr == 4'b1111) && (length_ptr == 4'b1111)) || (|cmd_cycletype_msb)));

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        config_reg_addr         <= 16'h0;
    end
    else if (detect_getconfig || detect_setconfig) begin
        config_reg_addr         <= {header_byte[0], header_byte[1]};
    end
    else begin
        config_reg_addr         <= 16'h0;
    end
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        config_reg_datain         <= 32'h0;
    end
    else if (detect_setconfig) begin
        config_reg_datain         <= {data_byte[3], data_byte[2], data_byte[1], data_byte[0]};
    end
    else begin
        config_reg_datain         <= 16'h0;
    end
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        cmd_data_ptr         <= 7'd0;
        cmd_hdr_ptr          <= 4'd0;
    end
    else begin
        cmd_data_ptr         <= cmd_data_ptr_combi;
        cmd_hdr_ptr          <= cmd_hdr_ptr_combi;
    end
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        addr_ptr      <= 4'd0;		
        length_ptr    <= 4'd0;        
    end
    else if (rx_detect_header) begin
        case ({command_byte_duplic, cycletype_byte})
        {`PUT_PC, `MEM_WRITE_32} : begin
                addr_ptr      <= 4'd4;			// 32-bit address
                length_ptr    <= 4'd2;          // 2-byte length
        end
        {`PUT_PC, `MEM_WRITE_64} : begin
                addr_ptr      <= 4'd8;			// 64-bit address
                length_ptr    <= 4'd2;          // 2-byte length
        end
        {`PUT_PC, `LOCAL_MESSAGE} : begin
                addr_ptr      <= 4'd5;          // 5 Message specific Byte			
                length_ptr    <= 4'd2;          // 2 byte length
        end
        {`PUT_PC, `LOCAL_MESSAGE_DATA} : begin
                addr_ptr      <= 4'd5;			// 5 Message specific Byte			
                length_ptr    <= 4'd2;          // 2 byte length
        end
        {`PUT_PC, `UNSUCCESSFUL_COMPLETE} : begin
                addr_ptr      <= 4'd0;			
                length_ptr    <= 4'd2;          // 2-byte length
        end
        {`PUT_PC, `SUCCESSFUL_COMPLETE_DATA} : begin
                addr_ptr      <= 4'd0;		
                length_ptr    <= 4'd2;          // 2-byte length
        end
        {`PUT_NP, `MEM_READ_32} : begin
                addr_ptr      <= 4'd4;			// 32-bit address
                length_ptr    <= 4'd2;          // 2-byte length
        end
        {`PUT_NP, `MEM_READ_64} : begin
                addr_ptr      <= 4'd8;			// 64-bit address
                length_ptr    <= 4'd2;          // 2-byte length
        end
        default: begin 
                addr_ptr      <= 4'b1111;	
                length_ptr    <= 4'b1111;  
        end
        endcase
    end
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        vw_data_ptr         <= 8'd0;
    end
    else if (stop_det) begin
        vw_data_ptr         <= 8'd0;
    end
    else if (detect_putvwire) begin
        vw_data_ptr         <= header_byte[0];
    end
end

endmodule
