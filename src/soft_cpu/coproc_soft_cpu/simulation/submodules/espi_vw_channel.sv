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


//----------------------
// NEED TO FIND OUT THE RESET PORT FOR vw CHANNEL
//
//----------------------------------------

`include "espi_header.iv"

`timescale 1 ps / 1 ps
module espi_vw_channel #(
    parameter VW_FIFO_SIZE = 32,
    parameter VW_FIFO_WIDTHU = 6,
    parameter DATABYTE_ARR = 4,
    parameter DEVICE_FAMILY = "MAX 10 FPGA"
)(                                    
    input                             clk,
    input                             reset_n,
    input                             espi_reset_n,  //
    input [2:0]                       rx_data_array_cnt,
    input                             malform_vw_packet_reg,
    input                             pec_mismatch_reg,
    input                             vw_channel_en,
    input                             rsmrst_n,
    input [7:0]                       data_byte[DATABYTE_ARR], 
    input                             stop_det,
    input                             detect_putvwire,
    input                             spiclk_cnt_done_hl,
    input [7:0]                       vw_irq0,
    input [7:0]                       vw_irq1,	
    input                             slave_boot_load_done,
    input                             slave_boot_load_status,
    input                             sus_ack_n,
    input                             oob_rst_ack, //
    input                             wake_n,
    input                             pme_n,
    input                             sci_n,
    input                             smi_n,
    input                             rcin_n,
    input                             host_rst_ack, //
    input  [7:0]                      ec_to_pch,
    input                             pop_vw_databyte,
    input  [6:0]                      max_vw_count_int,
    output logic                      vw_channel_ready,
    output logic                      vwire_avail,
    output logic [7:0]                vw_data,
    output logic [7:0]                vw_index,
    output logic [6:0]                vw_count,	
    output logic                      slp_s3_n,
    output logic                      slp_s4_n,
    output logic                      slp_s5_n, 
    output logic                      sus_warn_n, 
    output logic                      sus_stat_n,
    output logic                      oob_rst_warn, //
    output logic                      host_rst_warn,
    output logic                      smiout_n,
    output logic                      nmiout_n,     
    output logic                      host_c10,    //
    output logic                      pltrst_n,
    output logic                      sus_pwrdn_ack,      
    output logic                      slp_a_n, 
    output logic                      slp_lan_n,
    output logic                      slp_wlan_n,
    output logic [7:0]                pch_to_ec
);

logic put_fifo, pop_fifo, empty, full;
logic [7:0] index, data, ec_to_pch_reg, vw_pch_to_ec;
logic slave_boot_load_done_reg, slave_boot_load_status_reg, sus_ack_n_reg, oob_rst_ack_reg, wake_n_reg, pme_n_reg, sci_n_reg, smi_n_reg, rcin_n_reg, host_rst_ack_reg;
logic vw_slp_s3_n, vw_slp_s4_n, vw_slp_s5_n, vw_sus_stat_n, vw_oob_rst_warn, vw_pltrst_n, vw_sus_warn_n, vw_host_rst_warn, vw_smiout_n, vw_nmiout_n;    
logic vw_sus_pwrdn_ack, vw_slp_a_n, vw_slp_lan_n, vw_slp_wlan_n, vw_index_rsm_reset_n, vw_index_espi_reset_n, vw_index_plt_reset_n, vw_host_c10;    
logic serve_index_5h,  serve_index_4h, serve_index_6h, serve_index_40h, serve_index_45h, serve_index_46h;
logic slave_boot_load_done_c, slave_boot_load_status_c, oob_rst_ack_c, wake_n_c, pme_n_c, sci_n_c, smi_n_c, rcin_n_c, host_rst_ack_c, sus_ack_n_c, ec_to_pch_low_c, ec_to_pch_high_c;
logic vw_irq0_bit7_reg, vw_irq1_bit7_reg, vw_irq0_bit7_c, vw_irq1_bit7_c, serve_index_0h, serve_index_1h;
logic [VW_FIFO_WIDTHU-1:0] vw_count_num;

assign vw_channel_ready = vw_channel_en;
assign vwire_avail = ~empty;
assign pop_fifo = pop_vw_databyte;
assign vw_index_rsm_reset_n = reset_n && rsmrst_n;
assign vw_index_espi_reset_n = reset_n && espi_reset_n;
assign vw_index_plt_reset_n = reset_n && pltrst_n;
assign vw_count = (vw_count_num > max_vw_count_int) ? max_vw_count_int : {{(7-VW_FIFO_WIDTHU){1'b0}}, vw_count_num};

// ----------------- MASTER TO SLAVE VW PORT -----------------------------------
always @(posedge clk or negedge vw_index_rsm_reset_n) begin
    if (!vw_index_rsm_reset_n) begin
        slp_s3_n        <= 1'b0;
        slp_s4_n        <= 1'b0;
        slp_s5_n        <= 1'b0;
        slp_lan_n       <= 1'b0;
        slp_wlan_n      <= 1'b0;
    end
    else begin
        if (stop_det) begin
            slp_s3_n        <= vw_slp_s3_n;
            slp_s4_n        <= vw_slp_s4_n;
            slp_s5_n        <= vw_slp_s5_n;
            slp_lan_n       <= vw_slp_lan_n;     
            slp_wlan_n      <= vw_slp_wlan_n; 
        end
    end
end

always @(posedge clk or negedge vw_index_rsm_reset_n) begin
    if (!vw_index_rsm_reset_n) begin
        vw_slp_s3_n      <= 1'b0;
        vw_slp_s4_n      <= 1'b0;
        vw_slp_s5_n      <= 1'b0;
        vw_slp_lan_n     <= 1'b0;
        vw_slp_wlan_n    <= 1'b0;
    end
    else if (detect_putvwire && spiclk_cnt_done_hl && (rx_data_array_cnt == 3'h1) && ~malform_vw_packet_reg && vw_channel_ready) begin
        if (data_byte[0] == `VW_INDEX_2H && data_byte[1][4] == 1'b1) begin // AND with mask bit
            vw_slp_s3_n <= data_byte[1][0];
        end
        
        if (data_byte[0] == `VW_INDEX_2H && data_byte[1][5] == 1'b1) begin
            vw_slp_s4_n <= data_byte[1][1];
        end
        
        if (data_byte[0] == `VW_INDEX_2H && data_byte[1][6] == 1'b1) begin
            vw_slp_s5_n <= data_byte[1][2];
        end
        
        if (data_byte[0] == `VW_INDEX_42H && data_byte[1][4] == 1'b1) begin
            vw_slp_lan_n <= data_byte[1][0];
        end
        
        if (data_byte[0] == `VW_INDEX_42H && data_byte[1][5] == 1'b1) begin
            vw_slp_wlan_n <= data_byte[1][1];
        end
    end
    else if (pec_mismatch_reg) begin // revert the vw_* signal if its pec_mismatch
        vw_slp_s3_n      <= slp_s3_n;
        vw_slp_s4_n      <= slp_s4_n;
        vw_slp_s5_n      <= slp_s5_n;
        vw_slp_lan_n     <= slp_lan_n;
        vw_slp_wlan_n    <= slp_wlan_n;
    end
end

always @(posedge clk or negedge vw_index_espi_reset_n) begin
    if (!vw_index_espi_reset_n) begin
        sus_stat_n      <= 1'b0;
        pltrst_n        <= 1'b0;
        oob_rst_warn    <= 1'b0;
        sus_warn_n      <= 1'b0;
        sus_pwrdn_ack   <= 1'b0;
        slp_a_n         <= 1'b0;
        pch_to_ec       <= 8'h0;
    end
    else begin
        if (stop_det) begin
            sus_stat_n      <= vw_sus_stat_n;
            pltrst_n        <= vw_pltrst_n;
            oob_rst_warn    <= vw_oob_rst_warn;    
            sus_warn_n      <= vw_sus_warn_n;    
            sus_pwrdn_ack   <= vw_sus_pwrdn_ack; 
            slp_a_n         <= vw_slp_a_n;  
            pch_to_ec       <= vw_pch_to_ec; 
        end
    end
end

always @(posedge clk or negedge vw_index_espi_reset_n) begin
    if (!vw_index_espi_reset_n) begin
        vw_sus_stat_n    <= 1'b0;  
        vw_pltrst_n      <= 1'b0;
        vw_oob_rst_warn  <= 1'b0;
        vw_sus_warn_n    <= 1'b0;
        vw_sus_pwrdn_ack <= 1'b0;
        vw_slp_a_n       <= 1'b0;
        vw_pch_to_ec     <= 8'h0;
    end
    else if (detect_putvwire && spiclk_cnt_done_hl && (rx_data_array_cnt == 3'h1) && ~malform_vw_packet_reg && vw_channel_ready) begin
        if (data_byte[0] == `VW_INDEX_3H && data_byte[1][4] == 1'b1) begin
            vw_sus_stat_n <= data_byte[1][0];
        end
        
        if (data_byte[0] == `VW_INDEX_3H && data_byte[1][5] == 1'b1) begin
            vw_pltrst_n <= data_byte[1][1];
        end
        
        if (data_byte[0] == `VW_INDEX_3H && data_byte[1][6] == 1'b1) begin
            vw_oob_rst_warn <= data_byte[1][2];
        end
        
        if (data_byte[0] == `VW_INDEX_41H && data_byte[1][4] == 1'b1) begin
            vw_sus_warn_n <= data_byte[1][0];
        end
        
        if (data_byte[0] == `VW_INDEX_41H && data_byte[1][5] == 1'b1) begin
            vw_sus_pwrdn_ack <= data_byte[1][1];
        end
        
        if (data_byte[0] == `VW_INDEX_41H && data_byte[1][7] == 1'b1) begin
            vw_slp_a_n <= data_byte[1][3];
        end
        
        if (data_byte[0] == `VW_INDEX_43H && data_byte[1][4] == 1'b1) begin
            vw_pch_to_ec[0] <= data_byte[1][0];
        end
        
        if (data_byte[0] == `VW_INDEX_43H && data_byte[1][5] == 1'b1) begin
            vw_pch_to_ec[1] <= data_byte[1][1];
        end
        
        if (data_byte[0] == `VW_INDEX_43H && data_byte[1][6] == 1'b1) begin
            vw_pch_to_ec[2] <= data_byte[1][2];
        end
        
        if (data_byte[0] == `VW_INDEX_43H && data_byte[1][7] == 1'b1) begin
            vw_pch_to_ec[3] <= data_byte[1][3];
        end
        
        if (data_byte[0] == `VW_INDEX_44H && data_byte[1][4] == 1'b1) begin
            vw_pch_to_ec[4] <= data_byte[1][0];
        end
        
        if (data_byte[0] == `VW_INDEX_44H && data_byte[1][5] == 1'b1) begin
            vw_pch_to_ec[5] <= data_byte[1][1];
        end
        
        if (data_byte[0] == `VW_INDEX_44H && data_byte[1][6] == 1'b1) begin
            vw_pch_to_ec[6] <= data_byte[1][2];
        end
        
        if (data_byte[0] == `VW_INDEX_44H && data_byte[1][7] == 1'b1) begin
            vw_pch_to_ec[7] <= data_byte[1][3];
        end
    end
    else if (pec_mismatch_reg) begin // revert the vw_* signal if its pec_mismatch
        vw_sus_stat_n    <= sus_stat_n;    
        vw_pltrst_n      <= pltrst_n;     
        vw_oob_rst_warn  <= oob_rst_warn; 
        vw_sus_warn_n    <= sus_warn_n;   
        vw_sus_pwrdn_ack <= sus_pwrdn_ack;
        vw_slp_a_n       <= slp_a_n;      
        vw_pch_to_ec     <= pch_to_ec;    
    end
end

always @(posedge clk or negedge vw_index_plt_reset_n) begin
    if (!vw_index_plt_reset_n) begin
        host_rst_warn   <= 1'b0;
        smiout_n        <= 1'b1;
        nmiout_n        <= 1'b1;
        host_c10        <= 1'b0;
    end
    else begin
        if (stop_det) begin
            host_rst_warn   <= vw_host_rst_warn;
            smiout_n        <= vw_smiout_n;
            nmiout_n        <= vw_nmiout_n; 
            host_c10        <= vw_host_c10;
        end
    end
end

always @(posedge clk or negedge vw_index_plt_reset_n) begin
    if (!vw_index_plt_reset_n) begin
        vw_host_rst_warn <= 1'b0;
        vw_smiout_n      <= 1'b1;
        vw_nmiout_n      <= 1'b1;
        vw_host_c10      <= 1'b0;
    end
    else if (detect_putvwire && spiclk_cnt_done_hl && (rx_data_array_cnt == 3'h1) && ~malform_vw_packet_reg && vw_channel_ready) begin
        if (data_byte[0] == `VW_INDEX_7H && data_byte[1][4] == 1'b1) begin
            vw_host_rst_warn <= data_byte[1][0];
        end
        
        if (data_byte[0] == `VW_INDEX_7H && data_byte[1][5] == 1'b1) begin
            vw_smiout_n <= data_byte[1][1];
        end
        
        if (data_byte[0] == `VW_INDEX_7H && data_byte[1][6] == 1'b1) begin
            vw_nmiout_n <= data_byte[1][2];
        end
        
        if (data_byte[0] == `VW_INDEX_47H && data_byte[1][4] == 1'b1) begin
            vw_host_c10 <= data_byte[1][0];
        end
    end
    else if (pec_mismatch_reg) begin // revert the vw_* signal if its pec_mismatch
        vw_host_rst_warn <= host_rst_warn;
        vw_smiout_n      <= smiout_n;
        vw_nmiout_n      <= nmiout_n;
        vw_host_c10      <= host_c10;
    end
end

//------------------------- SLAVE TO MASTER VWIRE PORT ---------------------
// once the logical state of a virtual wire changes, this VW index and data will be stored in the TX FIFO
// this VW message will get retrieve and send to eSPI master when the master issue GET_VWIRE
always @(posedge clk or negedge vw_index_espi_reset_n) begin
    if (!vw_index_espi_reset_n) begin
        slave_boot_load_done_reg   <= 1'b0;
        slave_boot_load_status_reg <= 1'b0;
        sus_ack_n_reg              <= 1'b0;
        oob_rst_ack_reg            <= 1'b0;
        wake_n_reg                 <= 1'b1;
        pme_n_reg                  <= 1'b1;
        ec_to_pch_reg              <= 8'h0;
        vw_irq0_bit7_reg           <= 1'b0;
        vw_irq1_bit7_reg           <= 1'b0;
    end
    else if (vw_channel_ready) begin
        slave_boot_load_done_reg   <= slave_boot_load_done;
        slave_boot_load_status_reg <= slave_boot_load_status;
        sus_ack_n_reg              <= sus_ack_n;
        oob_rst_ack_reg            <= oob_rst_ack;
        wake_n_reg                 <= wake_n;
        pme_n_reg                  <= pme_n;
        ec_to_pch_reg              <= ec_to_pch;
        vw_irq0_bit7_reg           <= vw_irq0[7];
        vw_irq1_bit7_reg           <= vw_irq1[7];
    end
end

always @(posedge clk or negedge vw_index_plt_reset_n) begin
    if (!vw_index_plt_reset_n) begin
        sci_n_reg                  <= 1'b1;
        smi_n_reg                  <= 1'b1;
        rcin_n_reg                 <= 1'b1;
        host_rst_ack_reg           <= 1'b0;
    end
    else if (vw_channel_ready) begin
        sci_n_reg                  <= sci_n;
        smi_n_reg                  <= smi_n;
        rcin_n_reg                 <= rcin_n;
        host_rst_ack_reg           <= host_rst_ack;
    end
end

always @(posedge clk or negedge vw_index_espi_reset_n) begin
    if (!vw_index_espi_reset_n) begin
        slave_boot_load_done_c   <= 1'b0;
        slave_boot_load_status_c <= 1'b0;
        oob_rst_ack_c            <= 1'b0;
        wake_n_c                 <= 1'b0;
        pme_n_c                  <= 1'b0;
        sus_ack_n_c              <= 1'b0;
        ec_to_pch_low_c          <= 1'b0;
        ec_to_pch_high_c         <= 1'b0;
        vw_irq0_bit7_c           <= 1'b0;
        vw_irq1_bit7_c           <= 1'b0;
    end
    else if (vw_channel_ready) begin
        if (slave_boot_load_done != slave_boot_load_done_reg) 
            slave_boot_load_done_c <= 1'b1;
        else if (serve_index_5h)
            slave_boot_load_done_c <= 1'b0;
        	
        if (slave_boot_load_status != slave_boot_load_status_reg)
            slave_boot_load_status_c <= 1'b1;
        else if (serve_index_5h)
            slave_boot_load_status_c <= 1'b0;
        	
        if (oob_rst_ack != oob_rst_ack_reg)
            oob_rst_ack_c <= 1'b1;
        else if (serve_index_4h)
            oob_rst_ack_c <= 1'b0;
        	
        if (wake_n != wake_n_reg)
            wake_n_c <= 1'b1;
        else if (serve_index_4h)
            wake_n_c <= 1'b0;
        	
        if (pme_n != pme_n_reg)
            pme_n_c <= 1'b1;
        else if (serve_index_4h)
            pme_n_c <= 1'b0;

        if (sus_ack_n != sus_ack_n_reg)
            sus_ack_n_c <= 1'b1;
        else if (serve_index_40h)
            sus_ack_n_c <= 1'b0;
        	
        if (ec_to_pch[3:0] != ec_to_pch_reg[3:0])
            ec_to_pch_low_c <= 1'b1;
        else if (serve_index_45h)
            ec_to_pch_low_c <= 1'b0;
        	
        if (ec_to_pch[7:4] != ec_to_pch_reg[7:4])
            ec_to_pch_high_c <= 1'b1;
        else if (serve_index_46h)
            ec_to_pch_high_c <= 1'b0;
			
        if (vw_irq0[7] != vw_irq0_bit7_reg)
            vw_irq0_bit7_c <= 1'b1;
        else if (serve_index_0h)
            vw_irq0_bit7_c <= 1'b0;
			
        if (vw_irq1[7] != vw_irq1_bit7_reg)
            vw_irq1_bit7_c <= 1'b1;
        else if (serve_index_1h)
            vw_irq1_bit7_c <= 1'b0;
    end
end

always @(posedge clk or negedge vw_index_plt_reset_n) begin
    if (!vw_index_plt_reset_n) begin
        sci_n_c                  <= 1'b0;
        smi_n_c                  <= 1'b0;
        rcin_n_c                 <= 1'b0;
        host_rst_ack_c           <= 1'b0;
    end
    else if (vw_channel_ready) begin
        if (sci_n != sci_n_reg)
            sci_n_c <= 1'b1;
        else if (serve_index_6h)
            sci_n_c <= 1'b0;
        	
        if (smi_n != smi_n_reg)
            smi_n_c <= 1'b1;
        else if (serve_index_6h)
            smi_n_c <= 1'b0;
        	
        if (rcin_n != rcin_n_reg)
            rcin_n_c <= 1'b1;
        else if (serve_index_6h)
            rcin_n_c <= 1'b0;
        	
        if (host_rst_ack != host_rst_ack_reg)
            host_rst_ack_c <= 1'b1;
        else if (serve_index_6h)
            host_rst_ack_c <= 1'b0;
    end
end

// detect state changes on VW
always @(posedge clk or negedge vw_index_espi_reset_n) begin
    if (!vw_index_espi_reset_n) begin
        index            <= 8'h0;
        serve_index_0h   <= 1'b0;
        serve_index_1h   <= 1'b0;
        serve_index_5h   <= 1'b0;
        serve_index_4h   <= 1'b0;
        serve_index_6h   <= 1'b0;
        serve_index_40h  <= 1'b0;
        serve_index_45h  <= 1'b0;
        serve_index_46h  <= 1'b0;
    end
    else begin
    	if (~serve_index_0h && vw_irq0_bit7_c) begin
            index           <= `VW_INDEX_0H;
            serve_index_0h  <= 1'b1;
    	end
    	else if (~serve_index_1h && vw_irq1_bit7_c) begin
            index           <= `VW_INDEX_1H;
            serve_index_1h  <= 1'b1;
    	end
    	else if (~serve_index_5h && (slave_boot_load_done_c || slave_boot_load_status_c)) begin
            index           <= `VW_INDEX_5H;
            serve_index_5h  <= 1'b1;
    	end
    	else if (~serve_index_4h && (oob_rst_ack_c || wake_n_c || pme_n_c)) begin
            index           <= `VW_INDEX_4H;
            serve_index_4h  <= 1'b1;
    	end
    	else if (~serve_index_6h && (sci_n_c || smi_n_c || rcin_n_c || host_rst_ack_c)) begin
            index           <= `VW_INDEX_6H;
            serve_index_6h  <= 1'b1;
    	end
    	else if (~serve_index_40h && sus_ack_n_c) begin
            index           <= `VW_INDEX_40H;
            serve_index_40h <= 1'b1;
    	end
    	else if (~serve_index_45h && ec_to_pch_low_c) begin
            index           <= `VW_INDEX_45H;
            serve_index_45h <= 1'b1;
    	end
    	else if (~serve_index_46h && ec_to_pch_high_c) begin
            index           <= `VW_INDEX_46H;
            serve_index_46h <= 1'b1;
    	end
    	else if (put_fifo) begin
    	    serve_index_0h   <= 1'b0;
    	    serve_index_1h   <= 1'b0;
    	    serve_index_5h   <= 1'b0;
    	    serve_index_4h   <= 1'b0;
    	    serve_index_6h   <= 1'b0;
    	    serve_index_40h  <= 1'b0;
    	    serve_index_45h  <= 1'b0;
    	    serve_index_46h  <= 1'b0;
    	end
    end
end

always @(posedge clk or negedge vw_index_espi_reset_n) begin
    if (!vw_index_espi_reset_n) begin
        data   <= 8'h0;
    end
    else begin
    	if (~serve_index_0h && vw_irq0_bit7_c) begin
            data    <= vw_irq0;
		end
    	else if (~serve_index_1h && vw_irq1_bit7_c) begin
            data    <= vw_irq1;
		end
        else if (~serve_index_5h && (slave_boot_load_done_c || slave_boot_load_status_c)) begin
            if (slave_boot_load_done_c) begin
                data[0]   <= slave_boot_load_done;
                data[4]   <= 1'b1;
            end
            else begin
                data[0]   <= 1'b0;
                data[4]   <= 1'b0;
            end
            if (slave_boot_load_status_c) begin
                data[3]   <= slave_boot_load_status;
                data[7]   <= 1'b1;
            end
            else begin
                data[3]   <= 1'b0;
                data[7]   <= 1'b0;
            end
            data[1]   <= 1'b0;
            data[2]   <= 1'b0;
            data[5]   <= 1'b0;
            data[6]   <= 1'b0;
        end
        else if (~serve_index_4h && (oob_rst_ack_c || wake_n_c || pme_n_c)) begin
            if (oob_rst_ack_c) begin
                data[0]   <= oob_rst_ack;
                data[4]   <= 1'b1;
            end
            else begin
                data[0]   <= 1'b0;
                data[4]   <= 1'b0;
            end
            if (wake_n_c) begin
                data[2]   <= wake_n;
                data[6]   <= 1'b1;
            end
            else begin
                data[2]   <= 1'b0;
                data[6]   <= 1'b0;
            end
            if (pme_n_c) begin
                data[3]   <= pme_n;
                data[7]   <= 1'b1;
            end
            else begin
                data[3]   <= 1'b0;
                data[7]   <= 1'b0;
            end
            data[1]   <= 1'b0;
            data[5]   <= 1'b0;
        end
        else if (~serve_index_6h && (sci_n_c || smi_n_c || rcin_n_c || host_rst_ack_c)) begin
            if (sci_n_c) begin
                data[0]   <= sci_n;
                data[4]   <= 1'b1;
            end
            else begin
                data[0]   <= 1'b0;
                data[4]   <= 1'b0;
            end
            if (smi_n_c) begin
                data[1]   <= smi_n;
                data[5]   <= 1'b1;
            end
            else begin
                data[1]   <= 1'b0;
                data[5]   <= 1'b0;
            end
            if (rcin_n_c) begin
                data[2]   <= rcin_n;
                data[6]   <= 1'b1;
            end
            else begin
                data[2]   <= 1'b0;
                data[6]   <= 1'b0;
            end
            if (host_rst_ack_c) begin
                data[3]   <= host_rst_ack;
                data[7]   <= 1'b1;
            end
            else begin
                data[3]   <= 1'b0;
                data[7]   <= 1'b0;
            end
        end
        else if (~serve_index_40h && sus_ack_n_c) begin
            data[0]   <= sus_ack_n;
            data[4]   <= 1'b1;
            data[1]   <= 1'b0;
            data[2]   <= 1'b0;
            data[3]   <= 1'b0;
            data[5]   <= 1'b0;
            data[6]   <= 1'b0;
            data[7]   <= 1'b0;
        end
        else if (~serve_index_45h && ec_to_pch_low_c) begin
            data[3:0]  <= ec_to_pch[3:0];
            data[7:4]  <= {4{1'b1}};
        end
        else if (~serve_index_46h && ec_to_pch_high_c) begin
            data[3:0]   <= ec_to_pch[7:4];
            data[7:4]   <= {4{1'b1}};
        end
        else if (put_fifo) begin
            data   <= 8'h0;
        end
    end
end

always @(posedge clk or negedge vw_index_espi_reset_n) begin
    if (!vw_index_espi_reset_n) begin
        put_fifo              <= 1'b0;
    end
    else begin
    	if (~serve_index_0h && vw_irq0_bit7_c) begin
            put_fifo          <= 1'b1;
        end
    	else if (~serve_index_1h && vw_irq1_bit7_c) begin
            put_fifo          <= 1'b1;
        end
        else if (~serve_index_5h && (slave_boot_load_done_c || slave_boot_load_status_c))
            put_fifo          <= 1'b1;
        else if (~serve_index_4h && (oob_rst_ack_c || wake_n_c || pme_n_c))
            put_fifo          <= 1'b1;
        else if (~serve_index_6h && (sci_n_c || smi_n_c || rcin_n_c || host_rst_ack_c))
            put_fifo          <= 1'b1;
        else if (~serve_index_40h && sus_ack_n_c)
            put_fifo          <= 1'b1;
        else if (~serve_index_45h && ec_to_pch_low_c)
            put_fifo          <= 1'b1;
        else if (~serve_index_46h && ec_to_pch_high_c)
            put_fifo          <= 1'b1;
        else
            put_fifo          <= 1'b0;
    end
end
						  
espi_fifo #(
    .DSIZE  (16),
    .DEPTH  (VW_FIFO_SIZE),			
    .WIDTHU (VW_FIFO_WIDTHU),
    .FAMILY (DEVICE_FAMILY)
) vw_channel_inst (
    .clk          (clk),
    .rst_n        (vw_index_espi_reset_n),
    .put          (put_fifo && ~full),
    .get          (pop_fifo),
    .wdata        ({data, index}),
    .full         (full),               
    .empty        (empty),
    .rdata        ({vw_data, vw_index}),
    .usedw        (vw_count_num)
);
//------------------------- SLAVE TO MASTER VWIRE PORT ---------------------

endmodule
