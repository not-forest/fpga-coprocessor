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


//-------------------------------
//reminder to add:
// Add specific reset pin such as in-band reset command and pltrst which can also reset some of the registers

//--------------------------------
`include "espi_header.iv"

`timescale 1 ps / 1 ps
module espi_register #(
    parameter IO_MODE_RANGE             = 2'b11,
    parameter OPEN_DRAIN_ALERT_EN       = 1'b0,
    parameter MAX_FREQ_RANGE            = 3'b000,
    parameter CHANNEL_SUPPORT           = 8'b00000001,
    parameter MAX_PC_PAYLOAD_SIZE_RANGE = 3'b001,
    parameter MAX_VW_COUNT_SUPPORTED    = 6'b001111 //6'b000111
)(
    input                     clk,
    input                     ip_reset_n,
    input                     detect_reset, 
    input                     pltrst_n,
    input                     espi_cs_n_nxt2,
    input                     start_det,
    input [7:0]               avmm_writedata,
    input                     write_error_reg,
    input                     write_control_reg,
    input                     invalid_cmd,
    input                     invalid_cycletype,
    input                     crc_error,
    input                     invalid_cs_deassertion,
    input                     invalid_putfifo,
    input                     invalid_getfifo,
    input                     malform_pc_packet,
    input                     malform_vw_packet,
    input                     stop_det,
    input                     tx_gen_status,
    input                     detect_getstatus,
    input                     detect_getconfig,
    input                     detect_setconfig,
    input                     vwire_avail, 
    input                     pc_rxfifo_avail,
    input                     np_rxfifo_avail,
    input                     np_free, 
    input                     pc_free,
    input                     get_pc_txfifo,
    input                     get_np_txfifo,
    input                     pc_channel_ready,
    input                     vw_channel_ready,
    input  [15:0]             config_reg_addr,
    input  [31:0]             config_reg_datain,
    output logic [3:0]        max_wait_state,
    output logic [1:0]        io_mode,
    output logic [15:0]       status_reg_dataout,
    output logic [31:0]       config_reg_dataout,
    output logic              crc_en,
    output logic              resp_mod_en,
    output logic              alert_mode,
    output logic              opendrain_alert,
    output logic [2:0]        freq_value,
    output logic [2:0]        max_pc_payload_size,
    output logic [2:0]        max_pc_readreq_size,
    output logic              bus_master_en,
    output logic              pc_channel_en,
    output logic [5:0]        max_vw_count,
    output logic              vw_channel_en,
    output logic              update_status_reg,
    output logic              np_txfifo_avail, 
    output logic              pc_txfifo_avail, 
    output logic              interrupt,
    output logic              pc_channel_reset,
    output logic [1:0]        avalon_status_reg,
    output logic [7:0]        error_reg
);
localparam DEFAULT_STATUS_VALUE = (CHANNEL_SUPPORT == 8'b00000001 || CHANNEL_SUPPORT == 8'b00000011) ? 16'h30F : 16'h30C;      // default valud of the status bit

logic [15:0] status_field, status_reg, status_reg_nxt;
logic [31:0] device_id_reg, general_config_reg, channel0_config_reg, config_reg_dataout_combi;
logic [31:0] channel1_config_reg, channel2_config_reg, channel3_config_reg;
logic [1:0] avalon_status_field, avalon_control_reg;
logic oob_channel_en, fa_channel_en, pc_channel_en_reg, chan0_config_reset_n, trigger_alert_phase;
logic [2:0] max_fa_readreq_size, max_fa_payload_size, flash_erase_size;

assign chan0_config_reset_n = ip_reset_n && pltrst_n;
assign pc_txfifo_avail = avalon_control_reg[0];
assign np_txfifo_avail = avalon_control_reg[1];

assign avalon_status_field   = {np_rxfifo_avail,
                                pc_rxfifo_avail};

assign status_field          = {1'b0, 
                                1'b0, 
                                1'b0,            //flash_np_txfifo_avail
                                1'b0,            //flash_c_avail, 
                                1'b0, 
                                1'b0, 
                                1'b1,            //flash_np_free, 
                                1'b1,            //flash_c_free, 
                                1'b0,            //oob_avail, 
                                vwire_avail, 
                                np_txfifo_avail, 
                                pc_txfifo_avail, 
                                1'b1,            //oob_free, 
                                1'b1,            //vwire_free, always 1
                                np_free, 
                                pc_free};
							    
assign device_id_reg         = {{24{1'b0}}, 
                                `VERSION_ID};
							    
assign general_config_reg    = {crc_en, 			
                                resp_mod_en,        
                                1'b0,               
                                alert_mode,         
                                io_mode,            
                                IO_MODE_RANGE,      
                                opendrain_alert,    
                                freq_value,         
                                OPEN_DRAIN_ALERT_EN,
                                MAX_FREQ_RANGE,     
                                max_wait_state,     
                                {4{1'b0}},          
                                CHANNEL_SUPPORT};   
assign channel0_config_reg   = {{17{1'b0}},
                                max_pc_readreq_size,
                                1'b0,
                                max_pc_payload_size, 
                                1'b0, 
                                MAX_PC_PAYLOAD_SIZE_RANGE, 
                                1'b0, 
                                bus_master_en, 
                                pc_channel_ready, 
                                pc_channel_en};
assign channel1_config_reg   = {{10{1'b0}}, 
                                max_vw_count, 
                                {2{1'b0}}, 
                                MAX_VW_COUNT_SUPPORTED, 
                                {6{1'b0}}, 
                                vw_channel_ready, 
                                vw_channel_en};
assign channel2_config_reg   = {{20{1'b0}}, 
                                3'b001,          // oob_max_payload_size_selected 
                                1'b0,
                                3'b001,          //MAX_OOB_PAYLOAD_SIZE_RANGE, 
                                2'b00,
                                1'b0,                 //oob_channel_ready, 
                                oob_channel_en};
assign channel3_config_reg   = {{17{1'b0}}, 
                                max_fa_readreq_size, 
                                1'b0,                 //flash_sharing_mode, 
                                max_fa_payload_size, 
                                3'b001,             //MAX_FA_PAYLOAD_SIZE_RANGE, 
                                flash_erase_size, 
                                1'b0,                 //fa_channel_ready, 
                                fa_channel_en};
assign status_reg_dataout = status_reg;
assign config_reg_dataout_combi = (detect_getconfig && config_reg_addr == 16'h4) ? device_id_reg :
                                    (detect_getconfig && config_reg_addr == 16'h8) ? general_config_reg :
                                      (detect_getconfig && config_reg_addr == 16'h10) ? channel0_config_reg :		
                                        (detect_getconfig && config_reg_addr == 16'h20) ? channel1_config_reg :	
                                          (detect_getconfig && config_reg_addr == 16'h30) ? channel2_config_reg :
                                            (detect_getconfig && config_reg_addr == 16'h40) ? channel3_config_reg : {32{1'b0}};
											
always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        config_reg_dataout   <= {32{1'b0}};
    end
    else begin
        config_reg_dataout   <= config_reg_dataout_combi;
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        trigger_alert_phase   <= 1'b0;
    end
    else begin
        if (tx_gen_status)		
            trigger_alert_phase   <= 1'b1;
        else if (stop_det)
            trigger_alert_phase   <= 1'b0;
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        update_status_reg   <= 1'b0;
    end
    else begin
        if ((tx_gen_status || trigger_alert_phase || espi_cs_n_nxt2) && (status_reg_nxt != status_reg))
            update_status_reg   <= 1'b1;
        else if (start_det)
            update_status_reg   <= 1'b0;
    end
end
							
// general config register
always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        crc_en                  <= 1'b0;
        resp_mod_en             <= 1'b0;
        alert_mode              <= 1'b0;
        io_mode                 <= 2'b00;
        opendrain_alert         <= 1'b0;
        freq_value              <= 3'h0;
        max_wait_state          <= 4'h0; 
	end
    else begin
		if (detect_reset && stop_det) begin
            crc_en                  <= 1'b0;
            resp_mod_en             <= 1'b0;
            alert_mode              <= 1'b0;
            io_mode                 <= 2'b00;
            opendrain_alert         <= 1'b0;
            freq_value              <= 3'h0;
            max_wait_state          <= 4'h0;
		end
		else begin
            if (stop_det && detect_setconfig && config_reg_addr == `GENERAL_CONFIG_REG)
            	crc_en <= config_reg_datain[31];
            if (stop_det && detect_setconfig && config_reg_addr == `GENERAL_CONFIG_REG)
            	resp_mod_en <= config_reg_datain[30];
            if (stop_det && detect_setconfig && config_reg_addr == `GENERAL_CONFIG_REG)
            	alert_mode <= config_reg_datain[28];
            if (stop_det && detect_setconfig && config_reg_addr == `GENERAL_CONFIG_REG)
            	io_mode <= config_reg_datain[27:26];
            if (stop_det && detect_setconfig && config_reg_addr == `GENERAL_CONFIG_REG)
            	opendrain_alert <= 1'b0; //config_reg_datain[23];   // temporary only support driven output
            if (stop_det && detect_setconfig && config_reg_addr == `GENERAL_CONFIG_REG)
            	freq_value <= config_reg_datain[22:20];
            if (stop_det && detect_setconfig && config_reg_addr == `GENERAL_CONFIG_REG)
            	max_wait_state <= config_reg_datain[15:12];
		end
    end
end

//Channel0 config register
always @(posedge clk or negedge chan0_config_reset_n) begin
    if (!chan0_config_reset_n) begin
        max_pc_readreq_size     <= 3'b001;		
        max_pc_payload_size     <= 3'b001;
        bus_master_en           <= 1'b0;
        pc_channel_en           <= 1'b1; 
	end
    else begin
        if (stop_det && detect_setconfig && config_reg_addr == `CHANNEL0_CONFIG_REG)
            max_pc_readreq_size <= config_reg_datain[14:12];
        if (stop_det && detect_setconfig && config_reg_addr == `CHANNEL0_CONFIG_REG)
            max_pc_payload_size <= config_reg_datain[10:8];
        if (stop_det && detect_setconfig && config_reg_addr == `CHANNEL0_CONFIG_REG)
            bus_master_en <= config_reg_datain[2];
        if (stop_det && detect_setconfig && config_reg_addr == `CHANNEL0_CONFIG_REG)
            pc_channel_en <= config_reg_datain[0];
    end
end

//version id/ channel1/ channel2/ channel3 config register
always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        max_vw_count            <= 6'h0; 
        vw_channel_en           <= 1'b0;
        oob_channel_en          <= 1'b0;
        max_fa_readreq_size     <= 3'b001;
        max_fa_payload_size     <= 3'b001; 
        flash_erase_size        <= 3'b001; 
        fa_channel_en           <= 1'b0;   
    end
    else begin
        if (stop_det && detect_setconfig && config_reg_addr == `CHANNEL1_CONFIG_REG)
            max_vw_count <= config_reg_datain[21:16];
        if (stop_det && detect_setconfig && config_reg_addr == `CHANNEL1_CONFIG_REG)
            vw_channel_en <= config_reg_datain[0];
        if (stop_det && detect_setconfig && config_reg_addr == `CHANNEL2_CONFIG_REG)
            oob_channel_en <= config_reg_datain[0];
        if (stop_det && detect_setconfig && config_reg_addr == `CHANNEL3_CONFIG_REG)
            max_fa_readreq_size <= config_reg_datain[14:12];
        if (stop_det && detect_setconfig && config_reg_addr == `CHANNEL3_CONFIG_REG)
            max_fa_payload_size <= config_reg_datain[10:8];
        if (stop_det && detect_setconfig && config_reg_addr == `CHANNEL3_CONFIG_REG)
            flash_erase_size <= config_reg_datain[4:2];
        if (stop_det && detect_setconfig && config_reg_addr == `CHANNEL3_CONFIG_REG)
            fa_channel_en <= config_reg_datain[0];
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        pc_channel_reset      <= 1'b0;		
	end
    else begin
        pc_channel_reset      <= ~pc_channel_en && pc_channel_en_reg;	    
	end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        interrupt      <= 1'b0;
    end
    else begin
        if ((avalon_status_reg != avalon_status_field) || (|error_reg == 1'b1)) begin
            interrupt      <= 1'b1;
        end
        else begin
            interrupt      <= 1'b0;
        end
    end	
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        avalon_status_reg      <= 2'h0;			// avalon interface status register reset value	
        pc_channel_en_reg      <= 1'b0;
        status_reg             <= DEFAULT_STATUS_VALUE;
        status_reg_nxt         <= DEFAULT_STATUS_VALUE;
	end
    else begin
        pc_channel_en_reg      <= pc_channel_en;
        avalon_status_reg      <= avalon_status_field;
        status_reg             <= status_field;
        status_reg_nxt         <= status_reg;      
	end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n)
        avalon_control_reg <= 2'h0;			
    else begin
        if (write_control_reg && avmm_writedata[0])
            avalon_control_reg[0] <= 1'b1;
        else if (get_pc_txfifo)
            avalon_control_reg[0] <= 1'b0;
    		
        if (write_control_reg && avmm_writedata[1])
            avalon_control_reg[1] <= 1'b1;
        else if (get_np_txfifo)
            avalon_control_reg[1] <= 1'b0;
    end
end

always @(posedge clk or negedge ip_reset_n) begin
    if (!ip_reset_n) begin
        error_reg <= 8'h0;
    end
    else begin
        if (invalid_cmd) 
            error_reg[0] <= 1'b1;
        else if (write_error_reg && avmm_writedata[0])
            error_reg[0] <= 1'b0;
        	
        if (invalid_cycletype) 
            error_reg[1] <= 1'b1;
        else if (write_error_reg && avmm_writedata[1])
            error_reg[1] <= 1'b0;
        	
        if (crc_error) 
            error_reg[2] <= 1'b1;
        else if (write_error_reg && avmm_writedata[2])
            error_reg[2] <= 1'b0;
        	
        if (invalid_cs_deassertion) 
            error_reg[3] <= 1'b1;
        else if (write_error_reg && avmm_writedata[3])
            error_reg[3] <= 1'b0;
        	
        if (invalid_putfifo) 
            error_reg[4] <= 1'b1;
        else if (write_error_reg && avmm_writedata[4])
            error_reg[4] <= 1'b0;
        	
        if (invalid_getfifo) 
            error_reg[5] <= 1'b1;
        else if (write_error_reg && avmm_writedata[5])
            error_reg[5] <= 1'b0;
        	
        if (malform_pc_packet) 
            error_reg[6] <= 1'b1;
        else if (write_error_reg && avmm_writedata[6])
            error_reg[6] <= 1'b0;
        	
        if (malform_vw_packet) 
            error_reg[7] <= 1'b1;
        else if (write_error_reg && avmm_writedata[7])
            error_reg[7] <= 1'b0;
    end
end

endmodule
