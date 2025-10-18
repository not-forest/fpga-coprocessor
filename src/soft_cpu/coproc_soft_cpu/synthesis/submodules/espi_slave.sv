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
module espi_slave #(
    parameter PC_PORT00_EN              = 0,
    parameter PC_PORT10_EN              = 0,
    parameter PC_PORT20_EN              = 0,
    parameter PC_PORT30_EN              = 0,
    parameter PC_PORT40_EN              = 0,
    parameter PC_PORT50_EN              = 0,
    parameter PC_PORT60_EN              = 0,
    parameter PC_PORT70_EN              = 0,
    parameter PC_PORT80_EN              = 1,
    parameter PC_PORT90_EN              = 0,
    parameter PC_PORTA0_EN              = 0,
    parameter PC_PORT00_OUTPUT          = 0,
    parameter PC_PORT10_OUTPUT          = 0,
    parameter PC_PORT20_OUTPUT          = 0,
    parameter PC_PORT30_OUTPUT          = 0,
    parameter PC_PORT40_OUTPUT          = 0,
    parameter PC_PORT50_OUTPUT          = 0,
    parameter PC_PORT60_OUTPUT          = 0,
    parameter PC_PORT70_OUTPUT          = 0,
    parameter PC_PORT80_OUTPUT          = 1,
    parameter PC_PORT90_OUTPUT          = 0,
    parameter PC_PORTA0_OUTPUT          = 0,	
    parameter PORT00_DWIDTH             = 8,
    parameter PORT10_DWIDTH             = 8,
    parameter PORT20_DWIDTH             = 8,
    parameter PORT30_DWIDTH             = 8,
    parameter PORT40_DWIDTH             = 8,
    parameter PORT50_DWIDTH             = 8,
    parameter PORT60_DWIDTH             = 8,
    parameter PORT70_DWIDTH             = 8,
    parameter PORT80_DWIDTH             = 8,
    parameter PORT90_DWIDTH             = 8,
    parameter PORTA0_DWIDTH             = 8,
    parameter DEVICE_FAMILY             = "MAX 10 FPGA",
    parameter IO_MODE_RANGE             = 2'b00,           
    parameter OPEN_DRAIN_ALERT_EN       = 1'b0, 
    parameter MAX_FREQ_RANGE            = 3'b000,
    parameter CHANNEL_SUPPORT           = 8'b00000001,
    parameter MAX_PC_PAYLOAD_SIZE_RANGE = 3'b001,
    parameter MAX_PC_READREQ_SIZE_RANGE = 3'b001,
    parameter MAX_VW_COUNT_SUPPORTED    = 6'b000111,
    parameter DWIDTH                    = 4
) (
    input               clk,
    input               reset_n,
    
    // avalon protocol
    input               avmm_write,
    input               avmm_read,
    input [31:0]        avmm_writedata,
    input [4:0]         avmm_address,
    output logic [31:0] avmm_readdata,
    
    // interrupt
    output logic        irq,
    
    // espi protocol
    input               espi_clk,
    input               espi_reset_n,
    input               espi_cs_n,
    inout [DWIDTH-1:0]  espi_data,
    output logic        espi_alert_n,
    
    // conduit
    output logic                      slp_s5_n,
    output logic                      slp_s4_n,
    output logic                      slp_s3_n,
    output logic                      slp_a_n,
    output logic                      slp_lan_n,
    output logic                      slp_wlan_n,
    output logic                      sus_warn_n,
    output logic                      sus_pwrdn_ack,
    output logic                      sus_stat_n,
    output logic                      oob_rst_warn,
    output logic                      host_rst_warn,
    output logic       	              smiout_n,
    output logic       	              nmiout_n,
    output logic       	              host_c10,	
    output logic                      pltrst_n,
    output logic [7:0]                pch_to_ec,
    input  [PORT00_DWIDTH-1:0]        pc_port00_in,
    input  [PORT10_DWIDTH-1:0]        pc_port10_in,
    input  [PORT20_DWIDTH-1:0]        pc_port20_in,
    input  [PORT30_DWIDTH-1:0]        pc_port30_in,
    input  [PORT40_DWIDTH-1:0]        pc_port40_in,
    input  [PORT50_DWIDTH-1:0]        pc_port50_in,
    input  [PORT60_DWIDTH-1:0]        pc_port60_in,
    input  [PORT70_DWIDTH-1:0]        pc_port70_in,
    input  [PORT80_DWIDTH-1:0]        pc_port80_in,
    input  [PORT90_DWIDTH-1:0]        pc_port90_in,
    input  [PORTA0_DWIDTH-1:0]        pc_portA0_in,
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
    output logic [PORTA0_DWIDTH-1:0]  pc_portA0_out,
    input  logic [7:0]                vw_irq0,
    input  logic [7:0]                vw_irq1,
    input  logic [7:0]                ec_to_pch,
    input                             slave_boot_load_done,
    input                             slave_boot_load_status,
    input                             sus_ack_n,
    input                             oob_rst_ack,
    input                             wake_n,
    input                             pme_n,
    input                             sci_n,
    input                             smi_n,
    input                             rcin_n,
    input                             host_rst_ack,
    input                             rsmrst_n
);
// ------------------------------------------------------------------
// Ceil(log2()) function log2ceil of 4 = 2
// ------------------------------------------------------------------
function integer log2ceil;
    input reg[63:0] val;
    reg [63:0] i;
    begin
        i = 1;
        log2ceil = 0;
        while (i < val) begin
            log2ceil = log2ceil + 1;
            i = i << 1;
        end
    end
endfunction

localparam PC_RXFIFO_SIZE = 256;
                         //(MAX_PC_PAYLOAD_SIZE_RANGE == 3'b001) ? 64 : 0;
                         //     (MAX_PC_PAYLOAD_SIZE_RANGE == 3'b010) ? 128 : 
                         //       (MAX_PC_PAYLOAD_SIZE_RANGE == 3'b011) ? 256 : 64;
								
localparam PC_TXFIFO_SIZE = 256;
                         //(MAX_PC_READREQ_SIZE_RANGE == 3'b001) ? 64 + 11 : 0;
                         //     (MAX_PC_READREQ_SIZE_RANGE == 3'b010) ? 128 + 11 : 
                         //       (MAX_PC_READREQ_SIZE_RANGE == 3'b011) ? 256 + 11 :
                         //         (MAX_PC_READREQ_SIZE_RANGE == 3'b100) ? 512 + 11 :
                         //           (MAX_PC_READREQ_SIZE_RANGE == 3'b101) ? 1024 + 11 :
                         //             (MAX_PC_READREQ_SIZE_RANGE == 3'b110) ? 2048 + 11 :
                         //               (MAX_PC_READREQ_SIZE_RANGE == 3'b111) ? 4096 + 11 : 64 + 11;
								
localparam VW_FIFO_SIZE = 32;
localparam VW_FIFO_WIDTHU = log2ceil(VW_FIFO_SIZE);
localparam PC_RXFIFO_WIDTHU = log2ceil(PC_RXFIFO_SIZE);
localparam PC_TXFIFO_WIDTHU = log2ceil(PC_TXFIFO_SIZE);
localparam DATABYTE_ARR = 4;			//max is 4 byte for status data byte
localparam HDRBYTE_ARR  = 4;            //max is 4 byte because length byte is in byte1 and byte2
localparam BYTE         = 8;
								
logic trigger_alert, start_det, espi_clk_int, update_crc, rx_update_crc, tx_update_crc, verify_crc, stop_det, crc_en, pop_vw_databyte, detect_getpc, detect_getnp, read_status_reg, read_error_reg;
logic rx_detect_command, rx_detect_header, rx_detect_data, rx_detect_crc, detect_getvwire, detect_tx_idle, tx_with_cycletype, pc_channel_reset, rx_detect_data_end;
logic tx_gen_waitstate, tx_gen_crc, tx_gen_command, tx_gen_header, tx_gen_cycletype, tx_gen_data, tx_gen_status, pec_mismatch, invalid_cmd, invalid_cycletype, vw_channel_en;
logic rx_detect_header_end, rx_detect_command_end, invalid_putfifo, invalid_getfifo, detect_putpc, detect_putnp, detect_putvwire, detect_reset, interrupt;
logic pc_free, np_free, pc_txfifo_avail, np_txfifo_avail, vwire_avail, malform_vw_packet, malform_pc_packet, error_condition1;
logic error_condition2, rx_with_cycletype, alert_mode, pc_channel_en, opendrain_alert, detect_pc_cmd_withdata, invalid_ioport_addr, rx_detect_cycletype_end;
logic detect_put_np_rxfifo, detect_put_pc_rxfifo, detect_get_np_txfifo, detect_get_pc_txfifo, detect_iord_short1b, detect_iord_short2b, detect_iord_short4b, spiclk_cnt_done_lh;
logic detect_iord_short, detect_iowr_short, pc_channel_ready, ip_reset_n, vw_channel_ready, read_pc_rxfifo, read_np_rxfifo;
logic detect_memrd_short, detect_pc_rsp_withdata, detect_rx_idle, rx_detect_crc_end, error_condition1_nxt2, invalid_cs_deassertion;
logic espi_cs_n_nxt2, espi_cs_n_nxt4, trigger_output, spiclk_cnt_done_hl, trigger_output_high, read_status_regx2, read_error_regx2, read_pc_rxfifo_reg, read_np_rxfifo_reg, ws_counter_done; 
logic read_pc_rxfifo_regx2, read_np_rxfifo_regx2, tx_gen_length_h, tx_gen_length_l, pc_rxfifo_avail, np_rxfifo_avail, tx_gen_waitstate_reg, update_status_reg;
logic write_error_reg, write_control_reg, get_pc_txfifo, get_np_txfifo, flush_crc, trigger_output_nxt2, detect_getstatus, detect_getconfig, detect_setconfig, resp_mod_en, bus_master_en;
logic [7:0] rx_crc_data_in, tx_crc_data_in, crc_data_in, crc_code_out, rxshift_data, resp_data[4], resp_status[2], tx_dataout_byte;
logic [1:0] io_mode, avalon_status_reg;
logic [3:0] resp_hdr_ptr, cmd_hdr_ptr;
logic [7:0] command_byte, command_byte_duplic, command_byte_duplic2, command_byte_duplic3, crc_byte, resp_header, resp_crc, vw_data, vw_index, txfifo_rdata;
logic [7:0] data_byte[DATABYTE_ARR], header_byte[HDRBYTE_ARR], resp_command, pc_rxfifo_rdata, np_rxfifo_rdata;
logic [DWIDTH-1:0] espi_data_in, espi_data_out;
logic [3:0] max_wait_state;
logic [15:0] config_reg_addr, status_reg_dataout;
logic [6:0] cmd_data_ptr, resp_data_ptr, length_byte;
logic [31:0] config_reg_datain, config_reg_dataout, pc_port_data;
logic [2:0] freq_value, max_pc_payload_size, max_pc_readreq_size, cmd_data_array, rx_data_array_cnt, tx_data_array_cnt;
logic [3:0] addr_ptr;
logic [5:0] max_vw_count;
logic [6:0] max_vw_count_int, vw_count;
logic [1:0] rx_hdr_array_cnt, tx_status_cnt;
logic [2:0] resp_data_array;
logic [7:0] error_reg, vw_data_ptr;
logic [4:0] resp_cycletype, cycletype_byte, cycletype_byte_duplic;
logic [2:0] cmd_cycletype_msb, resp_cycletype_msb;
logic [63:0] addr_byte;
logic [6:0] payload_addr_boundary, max_payload_byte;
logic [6:0] readreq_addr_boundary, max_readreq_byte;

assign write_control_reg = (avmm_write && avmm_address == 5'h04);
assign write_error_reg   = (avmm_write && avmm_address == 5'h18);
assign avmm_readdata     = (read_status_regx2) ? {{30{1'b0}}, avalon_status_reg} :		// read data latency = 2
                             (read_error_regx2) ? {{24{1'b0}}, error_reg} : 
                               (read_pc_rxfifo_regx2) ? {{24{1'b0}}, pc_rxfifo_rdata} : 
                                 (read_np_rxfifo_regx2) ? {{24{1'b0}}, np_rxfifo_rdata} : {32{1'b0}};
assign trigger_alert = espi_cs_n && espi_cs_n_nxt4 && update_status_reg;		// to meet tSHAA by ANDing with espi_cs_n_nxt4, ANDing with espi_cs_n so that Alert wont happen after espi_cs_n is low
assign ip_reset_n = espi_reset_n && reset_n;
//assign espi_data = ~espi_reset_n ? {DWIDTH{1'bZ}} :      // tristate the pins when eSPI Reset# is asserted
//                     (trigger_output || (trigger_output_high) || (trigger_alert && alert_mode == 1'b0)) ? espi_data_out : {DWIDTH{1'bZ}};
assign espi_data = espi_data_out;                    
assign espi_data_in = espi_data;
assign espi_alert_n = ~espi_reset_n ? 1'bz :
                        trigger_alert ? 1'b0 : (opendrain_alert ? 1'bz : 1'b1);
assign max_vw_count_int = max_vw_count + 6'h1;   //max_vw_count + 1 because its 0-base value
assign malform_vw_packet = (vw_data_ptr > max_vw_count_int);
assign invalid_putfifo = ((~pc_free && rx_detect_command_end && detect_put_pc_rxfifo) || (~np_free && rx_detect_command_end && detect_put_np_rxfifo));	//only applicable for pc channel because VW channel is always free
assign invalid_getfifo = ((~pc_txfifo_avail && rx_detect_command_end && detect_getpc) || (~np_txfifo_avail && rx_detect_command_end && detect_getnp) || (~vwire_avail && rx_detect_command_end && detect_getvwire));			   
assign rx_crc_data_in = (rx_detect_command && spiclk_cnt_done_hl) ? command_byte_duplic :
                          (rx_detect_header && spiclk_cnt_done_hl) ? header_byte[rx_hdr_array_cnt] :
                            (rx_detect_data && spiclk_cnt_done_hl) ? data_byte[rx_data_array_cnt] :
                              (rx_detect_crc && spiclk_cnt_done_hl) ? crc_byte : {8{1'b0}};
								 
assign tx_crc_data_in = (tx_gen_command && spiclk_cnt_done_lh) ? resp_command :     
                          (tx_gen_cycletype && spiclk_cnt_done_lh) ? {3'h0, resp_cycletype} :
                            (tx_gen_header && spiclk_cnt_done_lh) ? resp_header : 
                              (tx_gen_data && spiclk_cnt_done_lh) ? resp_data[tx_data_array_cnt] : 
                                (tx_gen_status && spiclk_cnt_done_lh) ? resp_status[tx_status_cnt] : {8{1'b0}};
							   
assign crc_data_in = (rx_update_crc) ? rx_crc_data_in :
                       (tx_update_crc) ? tx_crc_data_in : {8{1'b0}};
						  		   
assign rx_update_crc  = (rx_detect_command || rx_detect_header || rx_detect_data || rx_detect_crc);
assign tx_update_crc  = (tx_gen_command || tx_gen_header || tx_gen_cycletype || tx_gen_data || tx_gen_status);

assign update_crc = ((rx_update_crc && spiclk_cnt_done_hl) || (tx_update_crc && spiclk_cnt_done_lh));
assign irq = interrupt;
assign read_pc_rxfifo = (avmm_read && avmm_address == 5'h08);
assign read_np_rxfifo = (avmm_read && avmm_address == 5'h10);

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n)
        flush_crc <= 1'b0;
    else if (stop_det || (~tx_gen_waitstate && tx_gen_waitstate_reg)) 
        flush_crc <= 1'b1;
    else
        flush_crc <= 1'b0;
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        max_payload_byte <= {7{1'b0}};
        max_readreq_byte <= {7{1'b0}};
    end
    else begin 
        if (max_pc_payload_size == 3'b001)
            max_payload_byte <= 7'd64;
			
        if (max_pc_readreq_size == 3'b001)
            max_readreq_byte <= 7'd64;
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        payload_addr_boundary  <= 7'h0;
        readreq_addr_boundary  <= 7'h0;
    end
    else begin 
        payload_addr_boundary  <= max_payload_byte - 7'h1;
        readreq_addr_boundary  <= max_readreq_byte - 7'h1;
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        malform_pc_packet <= 1'b0;
    end
    else begin 
        if (detect_pc_cmd_withdata && rx_detect_header_end && (((addr_byte[6:0] & payload_addr_boundary) + length_byte[6:0]) > max_payload_byte))  // for memory wite and completion with data
            malform_pc_packet <= 1'b1;
        else if (detect_putnp && rx_detect_header_end && (((addr_byte[6:0] & readreq_addr_boundary) + length_byte) > max_readreq_byte))  // for memory read
            malform_pc_packet <= 1'b1;
        else 
            malform_pc_packet <= 1'b0;
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        error_condition1 <= 1'b0; // condition to issue no-RESPONSE
    end
    else if (stop_det) begin
        error_condition1 <= 1'b0;
    end
    else if (invalid_cmd || invalid_cycletype || pec_mismatch) begin
        error_condition1 <= 1'b1;
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        error_condition2 <= 1'b0; // condition to issue fatal error response
    end
    else if (stop_det) begin
        error_condition2 <= 1'b0;
    end
    else if (invalid_putfifo || invalid_getfifo || malform_vw_packet || malform_pc_packet) begin
        error_condition2 <= 1'b1;
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
       verify_crc <= 1'b0;
    end
    else begin
        if (rx_detect_crc && update_crc && crc_en)
            verify_crc <= 1'b1;
        else
            verify_crc <= 1'b0;
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        tx_gen_waitstate_reg  <= 1'b0;
        read_status_reg       <= 1'b0;
        read_status_regx2     <= 1'b0;
        read_error_reg        <= 1'b0;
        read_error_regx2      <= 1'b0;
        read_pc_rxfifo_reg    <= 1'b0;
        read_np_rxfifo_reg    <= 1'b0;
	end
    else begin
        tx_gen_waitstate_reg <= tx_gen_waitstate;
        read_status_regx2    <= read_status_reg;
        read_error_regx2     <= read_error_reg;
        read_pc_rxfifo_reg   <= read_pc_rxfifo;
        read_np_rxfifo_reg   <= read_np_rxfifo;
        read_pc_rxfifo_regx2 <= read_pc_rxfifo_reg;
        read_np_rxfifo_regx2 <= read_np_rxfifo_reg;
        
        if (avmm_read && avmm_address == 5'h0)
            read_status_reg <= 1'b1;
        else
            read_status_reg <= 1'b0;
        	
        if (avmm_read && avmm_address == 5'h18)
            read_error_reg <= 1'b1;
        else
            read_error_reg <= 1'b0;
	end
end

generate if (CHANNEL_SUPPORT == 8'b00000001 || CHANNEL_SUPPORT == 8'b00000011) begin: pc_channel_enable_blk

logic pc_error_condition, flush_pc_fifo, write_np_txfifo, write_pc_txfifo;
logic [7:0] txfifo_wdata;
assign txfifo_wdata = avmm_writedata[7:0];
assign write_np_txfifo   = (avmm_write && avmm_address == 5'h14);
assign write_pc_txfifo   = (avmm_write && avmm_address == 5'h0C);

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        pc_error_condition <= 1'b0; // condition to drop pc command
    end
    else if (stop_det) begin
        pc_error_condition <= 1'b0;
    end
    else if (invalid_cmd || invalid_cycletype || pec_mismatch || invalid_putfifo || invalid_getfifo || malform_pc_packet) begin
        pc_error_condition <= 1'b1;
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n)
        flush_pc_fifo <= 1'b0;
    else if (stop_det) begin
        flush_pc_fifo <= 1'b0;
    end
    else if (invalid_cmd || invalid_cycletype || pec_mismatch || invalid_putfifo || invalid_getfifo || malform_pc_packet) begin
        flush_pc_fifo <= 1'b1;
    end
end

espi_pc_channel #(
    .PC_PORT00_EN         (PC_PORT00_EN),
    .PC_PORT10_EN         (PC_PORT10_EN),
    .PC_PORT20_EN         (PC_PORT20_EN),
    .PC_PORT30_EN         (PC_PORT30_EN),
    .PC_PORT40_EN         (PC_PORT40_EN),
    .PC_PORT50_EN         (PC_PORT50_EN),
    .PC_PORT60_EN         (PC_PORT60_EN),
    .PC_PORT70_EN         (PC_PORT70_EN),
    .PC_PORT80_EN         (PC_PORT80_EN),
    .PC_PORT90_EN         (PC_PORT90_EN),
    .PC_PORTA0_EN         (PC_PORTA0_EN),
    .PC_PORT00_OUTPUT     (PC_PORT00_OUTPUT),
    .PC_PORT10_OUTPUT     (PC_PORT10_OUTPUT),
    .PC_PORT20_OUTPUT     (PC_PORT20_OUTPUT),
    .PC_PORT30_OUTPUT     (PC_PORT30_OUTPUT),
    .PC_PORT40_OUTPUT     (PC_PORT40_OUTPUT),
    .PC_PORT50_OUTPUT     (PC_PORT50_OUTPUT),
    .PC_PORT60_OUTPUT     (PC_PORT60_OUTPUT),
    .PC_PORT70_OUTPUT     (PC_PORT70_OUTPUT),
    .PC_PORT80_OUTPUT     (PC_PORT80_OUTPUT),
    .PC_PORT90_OUTPUT     (PC_PORT90_OUTPUT),
    .PC_PORTA0_OUTPUT     (PC_PORTA0_OUTPUT),	
    .PORT00_DWIDTH        (PORT00_DWIDTH),
    .PORT10_DWIDTH        (PORT10_DWIDTH),
    .PORT20_DWIDTH        (PORT20_DWIDTH),
    .PORT30_DWIDTH        (PORT30_DWIDTH),
    .PORT40_DWIDTH        (PORT40_DWIDTH),
    .PORT50_DWIDTH        (PORT50_DWIDTH),
    .PORT60_DWIDTH        (PORT60_DWIDTH),
    .PORT70_DWIDTH        (PORT70_DWIDTH),
    .PORT80_DWIDTH        (PORT80_DWIDTH),
    .PORT90_DWIDTH        (PORT90_DWIDTH),
    .PORTA0_DWIDTH        (PORTA0_DWIDTH),
    .HDRBYTE_ARR          (HDRBYTE_ARR),
    .DATABYTE_ARR         (DATABYTE_ARR),
    .PC_RXFIFO_SIZE       (PC_RXFIFO_SIZE),
    .PC_RXFIFO_WIDTHU     (PC_RXFIFO_WIDTHU),
    .PC_TXFIFO_SIZE       (PC_TXFIFO_SIZE),
    .PC_TXFIFO_WIDTHU     (PC_TXFIFO_WIDTHU),
    .DEVICE_FAMILY        (DEVICE_FAMILY)
)  espi_pc_channel_inst (
    .clk                          (clk),
    .reset_n                      (reset_n),
    .pltrst_n                     (pltrst_n),
    .pc_channel_reset             (pc_channel_reset),
    .pc_error_condition           (pc_error_condition),
    .pec_mismatch                 (pec_mismatch),
    .flush_pc_fifo                (flush_pc_fifo),
    .stop_det                     (stop_det),
    .pc_channel_en                (pc_channel_en),
    .read_pc_rxfifo               (read_pc_rxfifo),
    .read_np_rxfifo               (read_np_rxfifo),
    .txfifo_wdata                 (txfifo_wdata),
    .rx_hdr_array_cnt             (rx_hdr_array_cnt),
    .rx_data_array_cnt            (rx_data_array_cnt),
    .data_byte                    (data_byte),
    .header_byte                  (header_byte),
    .command_byte                 (command_byte),
    .rx_detect_header             (rx_detect_header),
    .rx_detect_header_end         (rx_detect_header_end),
    .rx_detect_data               (rx_detect_data),
    .rx_detect_data_end           (rx_detect_data_end),
    .rx_detect_crc_end            (rx_detect_crc_end),
    .rx_detect_command            (rx_detect_command),
    .tx_gen_command               (tx_gen_command),
    .tx_gen_header                (tx_gen_header),
    .tx_gen_data                  (tx_gen_data),
    .spiclk_cnt_done_lh           (spiclk_cnt_done_lh),
    .spiclk_cnt_done_hl           (spiclk_cnt_done_hl),
    .detect_put_np_rxfifo         (detect_put_np_rxfifo),
    .detect_put_pc_rxfifo         (detect_put_pc_rxfifo),
    .detect_get_np_txfifo         (detect_get_np_txfifo),
    .detect_get_pc_txfifo         (detect_get_pc_txfifo),
    .detect_iord_short            (detect_iord_short),
    .detect_iowr_short            (detect_iowr_short),
    .write_pc_txfifo              (write_pc_txfifo),
    .write_np_txfifo              (write_np_txfifo),
    .pc_free                      (pc_free),
    .np_free                      (np_free),
    .pc_rxfifo_avail              (pc_rxfifo_avail),
    .np_rxfifo_avail              (np_rxfifo_avail),
    .pc_channel_ready             (pc_channel_ready),
    .pc_rxfifo_rdata              (pc_rxfifo_rdata),
    .np_rxfifo_rdata              (np_rxfifo_rdata),
    .txfifo_rdata                 (txfifo_rdata),
    .invalid_ioport_addr          (invalid_ioport_addr),
    .get_pc_txfifo                (get_pc_txfifo),
    .get_np_txfifo                (get_np_txfifo),
    .pc_port00_in                 (pc_port00_in),
    .pc_port10_in                 (pc_port10_in),
    .pc_port20_in                 (pc_port20_in),
    .pc_port30_in                 (pc_port30_in),
    .pc_port40_in                 (pc_port40_in),
    .pc_port50_in                 (pc_port50_in),
    .pc_port60_in                 (pc_port60_in),
    .pc_port70_in                 (pc_port70_in),
    .pc_port80_in                 (pc_port80_in),
    .pc_port90_in                 (pc_port90_in),
    .pc_portA0_in                 (pc_portA0_in),
    .pc_port_data                 (pc_port_data),
    .pc_port00_out                (pc_port00_out),
    .pc_port10_out                (pc_port10_out),
    .pc_port20_out                (pc_port20_out),
    .pc_port30_out                (pc_port30_out),
    .pc_port40_out                (pc_port40_out),
    .pc_port50_out                (pc_port50_out),
    .pc_port60_out                (pc_port60_out),
    .pc_port70_out                (pc_port70_out),
    .pc_port80_out                (pc_port80_out),
    .pc_port90_out                (pc_port90_out),
    .pc_portA0_out                (pc_portA0_out)
);
end
else begin : pc_channel_disable_blk
    assign pc_free = 0;
    assign np_free = 0;
    assign pc_rxfifo_avail = 0;
    assign np_rxfifo_avail = 0;
    assign get_pc_txfifo = 0;
    assign get_np_txfifo = 0;
    assign pc_channel_ready = 0;
    assign pc_rxfifo_rdata = {8{1'b0}};
    assign np_rxfifo_rdata = {8{1'b0}};
    assign txfifo_rdata = {8{1'b0}};
    assign invalid_ioport_addr = 0;
    assign pc_port_data = {32{1'b0}};
end
endgenerate 

espi_condt_det  #(
    .DWIDTH        (DWIDTH)
)  espi_condt_det_inst (
    .clk                         (clk),
    .reset_n                     (reset_n),
    .espi_cs_n                   (espi_cs_n),
    .espi_clk                    (espi_clk),
    .espi_reset_n                (espi_reset_n),
    .espi_data_in                (espi_data_in),
    .rx_detect_command           (rx_detect_command),
    .rx_detect_crc               (rx_detect_crc),
    .detect_rx_idle              (detect_rx_idle),
    .tx_gen_crc                  (tx_gen_crc), 
    .detect_tx_idle              (detect_tx_idle),
    .trigger_alert               (trigger_alert),
    .alert_mode                  (alert_mode),
    .io_mode                     (io_mode),
    .tx_dataout_byte             (tx_dataout_byte),
    .max_wait_state              (max_wait_state),
    .error_condition1            (error_condition1),
    .tx_gen_waitstate            (tx_gen_waitstate),
    .rxshift_data_nxt2           (rxshift_data),
    .trigger_output              (trigger_output),
    .trigger_output_high         (trigger_output_high),
    .start_det                   (start_det),
    .stop_det                    (stop_det),
    .espi_data_out               (espi_data_out),
    .espi_cs_n_nxt2              (espi_cs_n_nxt2),
    .espi_cs_n_nxt4              (espi_cs_n_nxt4),
    .spiclk_cnt_done_lh          (spiclk_cnt_done_lh),
    .spiclk_cnt_done_hl          (spiclk_cnt_done_hl),
    .invalid_cs_deassertion      (invalid_cs_deassertion),
    .error_condition1_nxt2       (error_condition1_nxt2),
    .ws_counter_done             (ws_counter_done)
);

espi_tx_shifter  #(
    .DWIDTH        (DWIDTH)
) espi_tx_shifter_inst (
    .clk                        (clk),
    .ip_reset_n                 (ip_reset_n),
    .rx_detect_crc              (rx_detect_crc),
    .tx_with_cycletype          (tx_with_cycletype),
    .detect_put_np_rxfifo       (detect_put_np_rxfifo),
    .error_condition1           (error_condition1),
    .error_condition2           (error_condition2),
    .invalid_ioport_addr        (invalid_ioport_addr),
    .stop_det                   (stop_det),
    .start_det                  (start_det),
    .resp_hdr_ptr               (resp_hdr_ptr),
    .resp_data_ptr              (resp_data_ptr),
    .resp_data_array            (resp_data_array),
    .io_mode                    (io_mode),
    .spiclk_cnt_done_hl         (spiclk_cnt_done_hl),
    .ws_counter_done            (ws_counter_done),
    .resp_header                (resp_header),
    .resp_cycletype             (resp_cycletype),
    .resp_cycletype_msb         (resp_cycletype_msb),
    .resp_data                  (resp_data),
    .resp_status                (resp_status),
    .resp_crc                   (crc_code_out),
    .tx_status_cnt              (tx_status_cnt),
    .tx_data_array_cnt          (tx_data_array_cnt),
    .tx_gen_waitstate           (tx_gen_waitstate),
    .tx_gen_command             (tx_gen_command),
    .tx_gen_header              (tx_gen_header),     
    .tx_gen_cycletype           (tx_gen_cycletype), 
    .tx_gen_length_h            (tx_gen_length_h),
    .tx_gen_length_l            (tx_gen_length_l),
    .tx_gen_data                (tx_gen_data),       
    .tx_gen_status              (tx_gen_status),
    .tx_gen_crc                 (tx_gen_crc),
    .tx_dataout_byte            (tx_dataout_byte),
    .resp_command               (resp_command),
    .detect_tx_idle             (detect_tx_idle)
);


espi_resp_gen espi_resp_gen_inst (
    .clk                     (clk),
    .reset_n                 (reset_n),
    .stop_det                (stop_det),
    .status_reg_dataout      (status_reg_dataout),
    .tx_gen_status           (tx_gen_status),
    .tx_gen_command          (tx_gen_command),
    .tx_gen_data             (tx_gen_data),
    .tx_gen_header           (tx_gen_header),
    .tx_gen_cycletype        (tx_gen_cycletype), 
    .tx_gen_length_h         (tx_gen_length_h),
    .tx_gen_length_l         (tx_gen_length_l),
    .spiclk_cnt_done_hl      (spiclk_cnt_done_hl),
    .spiclk_cnt_done_lh      (spiclk_cnt_done_lh),
    .tx_data_array_cnt       (tx_data_array_cnt),
    .config_reg_dataout      (config_reg_dataout),
    .pc_port_data            (pc_port_data),
    .txfifo_rdata            (txfifo_rdata),
    .detect_getvwire         (detect_getvwire), 
    .detect_getstatus        (detect_getstatus),
    .detect_getconfig        (detect_getconfig),
    .detect_setconfig        (detect_setconfig),
    .detect_iord_short       (detect_iord_short),
    .detect_iord_short1b     (detect_iord_short1b),
    .detect_iord_short2b     (detect_iord_short2b),
    .detect_iord_short4b     (detect_iord_short4b),
    .detect_memrd_short      (detect_memrd_short),
    .detect_getpc            (detect_getpc),
    .detect_getnp            (detect_getnp),
    .resp_data               (resp_data),
    .resp_status             (resp_status),
    .resp_header             (resp_header),  
    .resp_cycletype          (resp_cycletype),
    .resp_cycletype_msb      (resp_cycletype_msb),
    .vw_data                 ({vw_data, vw_index}),
    .vw_count                (vw_count),
    .vwire_avail             (vwire_avail),
    .resp_hdr_ptr            (resp_hdr_ptr),
    .resp_data_ptr           (resp_data_ptr),
    .resp_data_array         (resp_data_array),
    .pop_vw_databyte         (pop_vw_databyte),
    .detect_pc_rsp_withdata  (detect_pc_rsp_withdata),
    .tx_with_cycletype       (tx_with_cycletype)
);

generate if (CHANNEL_SUPPORT == 8'b00000010 || CHANNEL_SUPPORT == 8'b00000011) begin: vw_channel_enable_blk

logic malform_vw_packet_reg, pec_mismatch_reg;
always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        malform_vw_packet_reg <= 1'b0; // condition to issue fatal error response
        pec_mismatch_reg      <= 1'b0;
    end
    else if (stop_det) begin
        malform_vw_packet_reg <= 1'b0;
        pec_mismatch_reg      <= 1'b0;
    end
    else if (malform_vw_packet) begin
        malform_vw_packet_reg <= 1'b1;
    end
    else if (pec_mismatch) begin
        pec_mismatch_reg      <= 1'b1;
    end
end

espi_vw_channel #( 
    .VW_FIFO_SIZE (VW_FIFO_SIZE),
    .VW_FIFO_WIDTHU(VW_FIFO_WIDTHU),
    .DATABYTE_ARR  (DATABYTE_ARR),
    .DEVICE_FAMILY (DEVICE_FAMILY)
) espi_vw_channel_inst (
    .clk                          (clk),
    .reset_n                      (reset_n),
    .espi_reset_n                  (espi_reset_n),
    .rx_data_array_cnt            (rx_data_array_cnt),
    .vw_channel_en                (vw_channel_en),
    .malform_vw_packet_reg        (malform_vw_packet_reg),
    .pec_mismatch_reg             (pec_mismatch_reg),
    .rsmrst_n                     (rsmrst_n),
    .data_byte                    (data_byte), 
    .stop_det                     (stop_det),
    .detect_putvwire              (detect_putvwire),
    .spiclk_cnt_done_hl           (spiclk_cnt_done_hl),
    .vw_irq0                      (vw_irq0),
    .vw_irq1                      (vw_irq1),
    .slave_boot_load_done         (slave_boot_load_done),
    .slave_boot_load_status       (slave_boot_load_status),
    .sus_ack_n                    (sus_ack_n),
    .oob_rst_ack                  (oob_rst_ack),
    .wake_n                       (wake_n),
    .pme_n                        (pme_n),
    .sci_n                        (sci_n),
    .smi_n                        (smi_n),
    .rcin_n                       (rcin_n),
    .host_rst_ack                 (host_rst_ack),
    .ec_to_pch                    (ec_to_pch),
    .pop_vw_databyte              (pop_vw_databyte),
    .max_vw_count_int             (max_vw_count_int),
    .vw_channel_ready             (vw_channel_ready),
    .vwire_avail                  (vwire_avail),
    .vw_data                      (vw_data),
    .vw_index                     (vw_index),
    .vw_count                     (vw_count),
    .slp_s3_n                     (slp_s3_n),
    .slp_s4_n                     (slp_s4_n),
    .slp_s5_n                     (slp_s5_n),
    .sus_warn_n                   (sus_warn_n),
    .sus_stat_n                   (sus_stat_n),
    .oob_rst_warn                 (oob_rst_warn),
    .host_rst_warn                (host_rst_warn),
    .smiout_n                     (smiout_n),
    .nmiout_n                     (nmiout_n),
    .host_c10                     (host_c10),
    .pltrst_n                     (pltrst_n),
    .sus_pwrdn_ack                (sus_pwrdn_ack),    
    .slp_a_n                      (slp_a_n),
    .slp_lan_n                    (slp_lan_n),
    .slp_wlan_n                   (slp_wlan_n),
    .pch_to_ec                    (pch_to_ec)
);
end
else begin: vw_channel_disable_blk
    assign vw_channel_ready = 0;
    assign vwire_avail = 0;
    assign vw_data = 8'h0;
    assign vw_index = 8'h0;
    assign vw_count = 7'h0;
    assign pltrst_n = 1'b1;
end
endgenerate

espi_cmd_det #(
    .DATABYTE_ARR  (DATABYTE_ARR),
    .HDRBYTE_ARR   (HDRBYTE_ARR)
) espi_cmd_det_inst (
    .clk                           (clk),
    .reset_n                       (reset_n),
    .stop_det                      (stop_det),
    .rx_detect_command_end         (rx_detect_command_end),
    .rx_detect_cycletype_end       (rx_detect_cycletype_end),
    .rx_detect_header              (rx_detect_header),
    .command_byte                  (command_byte),
    .command_byte_duplic           (command_byte_duplic),
    .command_byte_duplic2          (command_byte_duplic2),
    .command_byte_duplic3          (command_byte_duplic3),
    .data_byte                     (data_byte),
    .header_byte                   (header_byte),
    .length_byte                   (length_byte),
    .crc_byte                      (crc_byte),
    .cycletype_byte                (cycletype_byte),
    .cycletype_byte_duplic         (cycletype_byte_duplic),
    .cmd_cycletype_msb             (cmd_cycletype_msb),
    .config_reg_addr               (config_reg_addr),
    .config_reg_datain             (config_reg_datain),
    .cmd_hdr_ptr                   (cmd_hdr_ptr),
    .cmd_data_ptr                  (cmd_data_ptr),
    .cmd_data_array                (cmd_data_array),
    .detect_getvwire               (detect_getvwire),
    .detect_getstatus              (detect_getstatus),
    .detect_getconfig              (detect_getconfig),
    .detect_setconfig              (detect_setconfig),
    .detect_putpc                  (detect_putpc),
    .detect_putnp                  (detect_putnp),
    .detect_getpc                  (detect_getpc),
    .detect_getnp                  (detect_getnp),
    .detect_putvwire               (detect_putvwire),
    .detect_put_np_rxfifo          (detect_put_np_rxfifo),
    .detect_put_pc_rxfifo          (detect_put_pc_rxfifo),
    .detect_get_np_txfifo          (detect_get_np_txfifo),
    .detect_get_pc_txfifo          (detect_get_pc_txfifo),
    .detect_pc_cmd_withdata        (detect_pc_cmd_withdata),
    .detect_iord_short             (detect_iord_short),
    .detect_iowr_short             (detect_iowr_short),
    .detect_iord_short1b           (detect_iord_short1b),
    .detect_iord_short2b           (detect_iord_short2b),
    .detect_iord_short4b           (detect_iord_short4b),
    .detect_memrd_short            (detect_memrd_short),
    .detect_reset                  (detect_reset),
    .invalid_cmd                   (invalid_cmd),
    .invalid_cycletype             (invalid_cycletype),
    .rx_with_cycletype             (rx_with_cycletype),
    .vw_data_ptr                   (vw_data_ptr),
    .addr_ptr                      (addr_ptr)
);

espi_crc_gen espi_crc_gen_inst (
    .clk                (clk),
    .reset_n            (ip_reset_n),
    .crc_data_in        (crc_data_in),
    .update_crc         (update_crc),
    .verify_crc         (verify_crc),
    .flush_crc          (flush_crc),
    .crc_code_out       (crc_code_out),
    .pec_mismatch       (pec_mismatch)
);

espi_rx_shifter #(
    .DWIDTH        (DWIDTH),
    .DATABYTE_ARR  (DATABYTE_ARR),
    .HDRBYTE_ARR   (HDRBYTE_ARR)
) espi_rx_shifter_inst (
    .clk                          (clk),
    .ip_reset_n                   (ip_reset_n),
    .invalid_cmd                  (invalid_cmd),
    .invalid_cycletype            (invalid_cycletype),
    .detect_reset                 (detect_reset),
    .spiclk_cnt_done_lh           (spiclk_cnt_done_lh),
    .spiclk_cnt_done_hl           (spiclk_cnt_done_hl),
    .rxshift_data                 (rxshift_data),
    .start_det                    (start_det),
    .stop_det                     (stop_det),
    .cmd_hdr_ptr                  (cmd_hdr_ptr),
    .cmd_data_ptr                 (cmd_data_ptr),
    .cmd_data_array               (cmd_data_array),
    .rx_with_cycletype            (rx_with_cycletype),
    .rx_hdr_array_cnt             (rx_hdr_array_cnt),
    .rx_data_array_cnt            (rx_data_array_cnt),
    .command_byte                 (command_byte),
    .command_byte_duplic          (command_byte_duplic),
    .command_byte_duplic2         (command_byte_duplic2),
    .command_byte_duplic3         (command_byte_duplic3),
    .header_byte                  (header_byte),
    .data_byte                    (data_byte),
    .crc_byte                     (crc_byte),
    .cycletype_byte               (cycletype_byte),
    .cycletype_byte_duplic        (cycletype_byte_duplic),
    .cmd_cycletype_msb            (cmd_cycletype_msb),
    .length_byte                  (length_byte),
    .addr_byte                    (addr_byte),
    .rx_detect_command            (rx_detect_command),
    .rx_detect_header             (rx_detect_header),
    .rx_detect_data               (rx_detect_data),
    .rx_detect_crc                (rx_detect_crc), 
    .rx_detect_cycletype_end      (rx_detect_cycletype_end),
    .rx_detect_command_end        (rx_detect_command_end),
    .rx_detect_header_end         (rx_detect_header_end),
    .rx_detect_data_end           (rx_detect_data_end),
    .rx_detect_crc_end            (rx_detect_crc_end),
    .detect_rx_idle               (detect_rx_idle)
);

espi_register #(
    .IO_MODE_RANGE              (IO_MODE_RANGE),    
    .OPEN_DRAIN_ALERT_EN        (OPEN_DRAIN_ALERT_EN),
    .MAX_FREQ_RANGE             (MAX_FREQ_RANGE),
    .CHANNEL_SUPPORT            (CHANNEL_SUPPORT),
    .MAX_PC_PAYLOAD_SIZE_RANGE  (MAX_PC_PAYLOAD_SIZE_RANGE),
    .MAX_VW_COUNT_SUPPORTED     (MAX_VW_COUNT_SUPPORTED)
) espi_register_inst (
    .clk                    (clk),
    .ip_reset_n             (ip_reset_n),
    .detect_reset           (detect_reset),
    .pltrst_n               (pltrst_n),
    .espi_cs_n_nxt2         (espi_cs_n_nxt2),
    .start_det              (start_det),
    .write_error_reg        (write_error_reg),
    .write_control_reg      (write_control_reg),
    .avmm_writedata         (avmm_writedata[7:0]),
    .invalid_cmd            (invalid_cmd),
    .invalid_cycletype      (invalid_cycletype),
    .crc_error              (pec_mismatch),
    .invalid_cs_deassertion (invalid_cs_deassertion),
    .invalid_putfifo        (invalid_putfifo),
    .invalid_getfifo        (invalid_getfifo),
    .malform_pc_packet      (malform_pc_packet),
    .malform_vw_packet      (malform_vw_packet),
    .stop_det               (stop_det),
    .tx_gen_status          (tx_gen_status),
    .detect_getstatus       (detect_getstatus),
    .detect_getconfig       (detect_getconfig),
    .detect_setconfig       (detect_setconfig),
    .vwire_avail            (vwire_avail),
    .pc_rxfifo_avail        (pc_rxfifo_avail),
    .np_rxfifo_avail        (np_rxfifo_avail),
    .np_free                (np_free),
    .pc_free                (pc_free),
    .get_pc_txfifo          (get_pc_txfifo),
    .get_np_txfifo          (get_np_txfifo),
    .pc_channel_ready       (pc_channel_ready),
    .vw_channel_ready       (vw_channel_ready),
    .config_reg_addr        (config_reg_addr),
    .config_reg_datain      (config_reg_datain),
    .max_wait_state         (max_wait_state),
    .io_mode                (io_mode),
    .config_reg_dataout     (config_reg_dataout),
    .status_reg_dataout     (status_reg_dataout),
    .crc_en                 (crc_en),
    .resp_mod_en            (resp_mod_en),				// not supported
    .alert_mode             (alert_mode),
    .opendrain_alert        (opendrain_alert),       
    .freq_value             (freq_value),
    .max_pc_readreq_size    (max_pc_readreq_size),     
    .max_pc_payload_size    (max_pc_payload_size),
    .bus_master_en          (bus_master_en),            // not supported
    .pc_channel_en          (pc_channel_en),
    .max_vw_count           (max_vw_count),			// 0-base count
    .vw_channel_en          (vw_channel_en),
    .update_status_reg      (update_status_reg),
    .np_txfifo_avail        (np_txfifo_avail),
    .pc_txfifo_avail        (pc_txfifo_avail),
    .interrupt              (interrupt),
    .pc_channel_reset       (pc_channel_reset),
    .avalon_status_reg      (avalon_status_reg),
    .error_reg              (error_reg)
);

endmodule
