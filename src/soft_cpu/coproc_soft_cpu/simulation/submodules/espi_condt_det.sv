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


//-----------------------------
//At the last falling edge of the serial clock after CRC is sent, the eSPI slave must drive I/O[n:0] pins to high until
//Chip Select# is deasserted. 
//--------------------------------------------

`timescale 1 ps / 1 ps

module espi_condt_det #(
    parameter DWIDTH = 1
)(
    input                      clk,
    input                      reset_n,
    input                      espi_cs_n,
    input                      espi_clk,
    input                      espi_reset_n,
    input  [DWIDTH-1:0]        espi_data_in,
    input                      rx_detect_command,
    input                      rx_detect_crc,
    input                      detect_rx_idle,
    input                      tx_gen_crc,
    input                      detect_tx_idle,
    input                      trigger_alert,
    input                      alert_mode,
    input  [1:0]               io_mode,
    input  [7:0]               tx_dataout_byte,
    input  [3:0]               max_wait_state,
    input                      error_condition1,
    input                      tx_gen_waitstate,
    output logic [7:0]         rxshift_data_nxt2,
    output logic               trigger_output,
    output logic               trigger_output_high,
    output logic               start_det,
    output logic               stop_det,
    output logic [DWIDTH-1:0]  espi_data_out,
    output logic               espi_cs_n_nxt2,
    output logic               espi_cs_n_nxt4,
    output logic               spiclk_cnt_done_lh,
    output logic               spiclk_cnt_done_hl,
    output logic               invalid_cs_deassertion,
    output logic               error_condition1_nxt2,
    output logic               ws_counter_done
);
localparam BYTE = 8;

logic espi_cs_n_nxt, espi_cs_n_nxt3, trigger_tar, trigger_input, trigger_txshift_data, detect_tx_idle_nxt, detect_tx_idle_nxt2;
logic spiclk_cnt_done, posspiclk_cnt_done, spiclk_cnt_done_nxt, spiclk_cnt_done_nxt3, spiclk_cnt_done_nxt4, rx_detect_crc_nxt, rx_detect_crc_nxt2, tx_gen_crc_nxt, tx_gen_crc_nxt2;
logic spi_domain_reset_n, rx_detect_command_nxt, rx_detect_command_nxt2, trigger_tar_spistg1, trigger_tar_spistg2, spiclk_cnt_done_nxt2;
logic posspiclk_cnt_done_nxt, posspiclk_cnt_done_nxt2, posspiclk_cnt_done_nxt3, posspiclk_cnt_done_nxt4, start_trigger_output, load_first_txshift_data;
logic stop_trigger_output, trigger_output_nxt, trigger_output_nxt2, trigger_output_nxt3;
logic error_condition1_nxt, condition_reset_n;
logic detect_rx_idle_nxt2, detect_rx_idle_nxt;
logic [3:0] spiclk_cnt, spiclk_cnt_incr_value, spiclk_cnt_loadvalue, shiftvalue;
logic [7:0] txshift_data, rxshift_data_nxt, rxshift_data, tx_dataout_byte_nxt, tx_dataout_byte_nxt2, io_mode_txshift_data;
logic [4:0] max_wait_state_int, ws_counter;

assign shiftvalue = (io_mode == 2'b00) ? 4'h1 :
                      (io_mode == 2'b01) ? 4'h2 :
                        (io_mode == 2'b10) ? 4'h4 : 4'h1;

assign start_det = espi_cs_n_nxt3 && ~espi_cs_n_nxt2;
assign stop_det = ~espi_cs_n_nxt3 && espi_cs_n_nxt2;
assign spi_domain_reset_n = espi_reset_n;
assign spiclk_cnt_done_lh = (~posspiclk_cnt_done_nxt4 && posspiclk_cnt_done_nxt3);
assign spiclk_cnt_done_hl = (spiclk_cnt_done_nxt4 && ~spiclk_cnt_done_nxt3);
assign spiclk_cnt_incr_value = (io_mode == 2'b00) ? 4'h1 :					  // single IO mode - 8 spiclk per byte
                                 (io_mode == 2'b01) ? 4'h2 :                    // dual IO mode - 4 spiclk per byte
                                   (io_mode == 2'b10) ? 4'h4 : 4'h1;         // quad IO mode - 2 spiclk per byte
assign trigger_tar = rx_detect_crc_nxt2 && spiclk_cnt_done;
assign start_trigger_output = (io_mode == 2'b00) ? trigger_tar_spistg2 :					  // single IO mode - 8 spiclk per byte
                                (io_mode == 2'b01) ? trigger_tar_spistg2 :                    // dual IO mode - 4 spiclk per byte
                                  (io_mode == 2'b10) ? trigger_tar : 1'h1;         // quad IO mode - 2 spiclk per byte
assign load_first_txshift_data = (io_mode == 2'b00) ? trigger_tar_spistg1 :					  // single IO mode - 8 spiclk per byte
                                   (io_mode == 2'b01) ? trigger_tar_spistg1 :                    // dual IO mode - 4 spiclk per byte
                                     (io_mode == 2'b10) ? trigger_tar : 1'h1;         // quad IO mode - 2 spiclk per byte
assign trigger_txshift_data = trigger_output && spiclk_cnt_done;

//----------------------------------- IP clock domain -----------------------------------------
// SPI clock signal to IP clock signal syncronizer
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        espi_cs_n_nxt               <= 1'b1;
        espi_cs_n_nxt2              <= 1'b1;
        espi_cs_n_nxt3              <= 1'b1;
        espi_cs_n_nxt4              <= 1'b1;
        spiclk_cnt_done_nxt         <= 1'b0;
        spiclk_cnt_done_nxt2        <= 1'b0;
        spiclk_cnt_done_nxt3        <= 1'b0;
        spiclk_cnt_done_nxt4        <= 1'b0;
        posspiclk_cnt_done_nxt      <= 1'b0;
        posspiclk_cnt_done_nxt2     <= 1'b0;
        posspiclk_cnt_done_nxt3     <= 1'b0;
        posspiclk_cnt_done_nxt4     <= 1'b0;
        trigger_output_nxt          <= 1'b0;
        trigger_output_nxt2         <= 1'b0;
        trigger_output_nxt3         <= 1'b0;
        rxshift_data_nxt            <= 8'd0;
        rxshift_data_nxt2           <= 8'd0;
	end
    else begin
        espi_cs_n_nxt               <= espi_cs_n;
        espi_cs_n_nxt2              <= espi_cs_n_nxt;
        espi_cs_n_nxt3              <= espi_cs_n_nxt2;
        espi_cs_n_nxt4              <= espi_cs_n_nxt3;
        spiclk_cnt_done_nxt         <= spiclk_cnt_done;
        spiclk_cnt_done_nxt2        <= spiclk_cnt_done_nxt;
        spiclk_cnt_done_nxt3        <= spiclk_cnt_done_nxt2;
        spiclk_cnt_done_nxt4        <= spiclk_cnt_done_nxt3;
        posspiclk_cnt_done_nxt      <= posspiclk_cnt_done;
        posspiclk_cnt_done_nxt2     <= posspiclk_cnt_done_nxt;
        posspiclk_cnt_done_nxt3     <= posspiclk_cnt_done_nxt2;
        posspiclk_cnt_done_nxt4     <= posspiclk_cnt_done_nxt3;
        trigger_output_nxt          <= trigger_output;
        trigger_output_nxt2         <= trigger_output_nxt;
        trigger_output_nxt3         <= trigger_output_nxt2;
        rxshift_data_nxt            <= rxshift_data;
        rxshift_data_nxt2           <= rxshift_data_nxt;
    end
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        invalid_cs_deassertion     <= 1'b0;
    end
    else begin
        if (espi_cs_n_nxt2 && (~detect_tx_idle || ~detect_rx_idle))
            invalid_cs_deassertion     <= 1'b1;
        else
            invalid_cs_deassertion     <= 1'b0;
    end
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        max_wait_state_int     <= 5'b00000;
    end
    else begin
        if (max_wait_state == 4'b0000) begin
            max_wait_state_int     <= 5'b10000;
        end
        else begin
            max_wait_state_int     <= {1'b0, max_wait_state};
        end
    end
end

assign ws_counter_done = (io_mode == 2'b10 && (max_wait_state_int == 5'h1)) ? (spiclk_cnt_done_hl && trigger_output_nxt2) :
                           ((ws_counter == (max_wait_state_int - 5'h1)) && spiclk_cnt_done_hl && tx_gen_waitstate);

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        ws_counter <= 5'h0;					
    end
    else begin
        if (ws_counter_done || error_condition1) begin
            ws_counter <= 5'h0;
        end
        else if (spiclk_cnt_done_hl && ws_counter > 5'h0) begin
            ws_counter <= ws_counter + 5'h1;
        end
        else if (trigger_output_nxt2 && ~trigger_output_nxt3 && (ws_counter < (max_wait_state_int - 5'h1))) begin
            ws_counter <= 5'h1;	
        end
    end
end

//----------------------------------- SPI clock domain -----------------------------------------
// IP clock signal to SPI clock signal syncronizer
always @(negedge espi_clk or negedge spi_domain_reset_n) begin
    if (!spi_domain_reset_n) begin
        rx_detect_crc_nxt      <= 1'b0;
        rx_detect_crc_nxt2     <= 1'b0;
        detect_rx_idle_nxt     <= 1'b0;
        detect_rx_idle_nxt2    <= 1'b0;
        tx_gen_crc_nxt         <= 1'b0;
        tx_gen_crc_nxt2        <= 1'b0;
        detect_tx_idle_nxt     <= 1'b0;
        detect_tx_idle_nxt2    <= 1'b0;
        rx_detect_command_nxt  <= 1'b0;
        rx_detect_command_nxt2 <= 1'b0;
        error_condition1_nxt   <= 1'b0;
        error_condition1_nxt2  <= 1'b0;
    end
    else begin
        rx_detect_crc_nxt      <= rx_detect_crc;
        rx_detect_crc_nxt2     <= rx_detect_crc_nxt;
        detect_rx_idle_nxt     <= detect_rx_idle;
        detect_rx_idle_nxt2    <= detect_rx_idle_nxt;
        tx_gen_crc_nxt         <= tx_gen_crc;
        tx_gen_crc_nxt2        <= tx_gen_crc_nxt;
        detect_tx_idle_nxt     <= detect_tx_idle;
        detect_tx_idle_nxt2    <= detect_tx_idle_nxt;
        rx_detect_command_nxt  <= rx_detect_command;
        rx_detect_command_nxt2 <= rx_detect_command_nxt;
        error_condition1_nxt   <= error_condition1;
        error_condition1_nxt2  <= error_condition1_nxt;
    end
end

always @(posedge espi_clk or negedge spi_domain_reset_n) begin
    if (!spi_domain_reset_n) begin
        tx_dataout_byte_nxt    <= 8'h0;
        tx_dataout_byte_nxt2   <= 8'h0;
    end
    else begin
        tx_dataout_byte_nxt    <= tx_dataout_byte;
        tx_dataout_byte_nxt2   <= tx_dataout_byte_nxt;
    end
end

// TAR is 2 clock cycles, uses this register signal to generate the stage
always @(negedge espi_clk or negedge spi_domain_reset_n) begin
    if (!spi_domain_reset_n) begin
        trigger_tar_spistg1     <= 1'b0;
        trigger_tar_spistg2     <= 1'b0;
    end
    else begin
        trigger_tar_spistg1     <= trigger_tar;
        trigger_tar_spistg2     <= trigger_tar_spistg1;
    end
end

assign condition_reset_n = ~espi_cs_n && spi_domain_reset_n;	// this is to reset the espi clock register when espi clock is stopped

always @(negedge espi_clk or negedge condition_reset_n) begin
    if (!condition_reset_n) begin
        spiclk_cnt_done     <= 1'b0; 
    end
    else begin
        if (io_mode == 2'b00 && (spiclk_cnt == 4'h6)) begin
            spiclk_cnt_done     <= 1'b1;
        end
        else if (io_mode == 2'b01 && (spiclk_cnt == 4'h4)) begin
            spiclk_cnt_done     <= 1'b1;
        end
        else if (io_mode == 2'b10 && (spiclk_cnt == 4'h0)) begin
            spiclk_cnt_done     <= 1'b1;
        end
        else begin
            spiclk_cnt_done     <= 1'b0;
        end
    end
end

always @(negedge espi_clk or negedge condition_reset_n) begin
    if (!condition_reset_n) begin
        trigger_output     <= 1'b0;
    end
    else begin
        if (start_trigger_output)		// during error condition 1, slave doesn't need to drive response phase
            trigger_output <= 1'b1;
        else if (stop_trigger_output || (error_condition1_nxt2 && spiclk_cnt_done))
            trigger_output <= 1'b0;
    end
end

always @(negedge espi_clk or negedge condition_reset_n) begin
    if (!condition_reset_n) begin
        trigger_input      <= 1'b0;
    end
    else begin
        if (rx_detect_command_nxt2)
            trigger_input <= 1'b1;
        else if (trigger_tar || detect_rx_idle_nxt2)
            trigger_input <= 1'b0;
    end
end

always @(negedge espi_clk or negedge condition_reset_n) begin
    if (!condition_reset_n) begin
        trigger_output_high     <= 1'b0;
    end
    else begin
        if (trigger_input)
            trigger_output_high     <= 1'b0;
        else if (trigger_output) 
            trigger_output_high     <= 1'b1;
    end
end

always @(negedge espi_clk or negedge condition_reset_n) begin
    if(!condition_reset_n) begin
        spiclk_cnt <= 4'h0;					
    end
    else begin
        if (spiclk_cnt_done || start_trigger_output) // || (~espi_cs_n && error_condition1 && error_condition1_nxt2 && ~trigger_output))		// 
            spiclk_cnt <= 4'h0;
        else if (~espi_cs_n)
            spiclk_cnt <= spiclk_cnt + spiclk_cnt_incr_value;
    end
end

always @(posedge espi_clk or negedge spi_domain_reset_n) begin
    if(!spi_domain_reset_n) begin
        stop_trigger_output <= 1'b0;			
    end
    else begin
        if (((io_mode == 2'b00 || io_mode == 2'b01) && detect_tx_idle_nxt2 && trigger_output && spiclk_cnt_done) 
             || (io_mode == 2'b10 && trigger_output && tx_gen_crc_nxt2 && spiclk_cnt_done)) 
            stop_trigger_output <= 1'b1;
        else
            stop_trigger_output <= 1'b0;
    end
end

always @(posedge espi_clk or negedge spi_domain_reset_n) begin
    if(!spi_domain_reset_n) begin
        posspiclk_cnt_done <= 1'b0;			
    end
    else begin
        if (spiclk_cnt_done)
            posspiclk_cnt_done <= 1'b1;
        else
            posspiclk_cnt_done <= 1'b0;
    end
end

generate if (DWIDTH == 2) begin : io_mode_blk0
// RX shifter
always @(posedge espi_clk or negedge spi_domain_reset_n) begin
    if(!spi_domain_reset_n) begin
        rxshift_data <= 8'h0;					
    end
    else begin
        if (io_mode == 2'b00)
            rxshift_data <= {rxshift_data[6:0], espi_data_in[0]};
        else if (io_mode == 2'b01)
            rxshift_data <= {rxshift_data[5:0], espi_data_in[1:0]};
    end
end
	
end
else begin
// RX shifter
always @(posedge espi_clk or negedge spi_domain_reset_n) begin
    if(!spi_domain_reset_n) begin
        rxshift_data <= 8'h0;					
    end
    else begin
        if (io_mode == 2'b00)
            rxshift_data <= {rxshift_data[6:0], espi_data_in[0]};
        else if (io_mode == 2'b01)
            rxshift_data <= {rxshift_data[5:0], espi_data_in[1:0]};
        else if (io_mode == 2'b10)
            rxshift_data <= {rxshift_data[3:0], espi_data_in[3:0]};
    end
end

end
endgenerate

assign io_mode_txshift_data = (io_mode == 2'b10) ? tx_dataout_byte_nxt : tx_dataout_byte_nxt2;

// TX shifter
always @(negedge espi_clk or negedge spi_domain_reset_n) begin
    if (!spi_domain_reset_n) begin
        txshift_data <= {8{1'b0}};
    end
    else begin
        if (load_first_txshift_data || trigger_txshift_data) begin
            txshift_data <= io_mode_txshift_data;
        end
        else if (trigger_output) begin
            txshift_data <= txshift_data << shiftvalue;
        end
    end
end

generate if (DWIDTH == 2) begin : io_mode_blk1
    assign espi_data_out[0] = (trigger_output) ? (io_mode[0] ? txshift_data[6] : 1'bz) : ((trigger_output_high && io_mode[0]) ? 1'b1 : 1'bz);
    
    assign espi_data_out[1] = (trigger_output) ? txshift_data[7] : (trigger_output_high ? 1'b1 : ((trigger_alert && !alert_mode) ? 1'b0 : 1'bz));
end
else begin
    assign espi_data_out[0] = (trigger_output) ? (io_mode[0] ? txshift_data[6] : (io_mode[1] ? txshift_data[4] : 1'bz)) : ((trigger_output_high && io_mode[0]) ? 1'b1 : 1'bz);
                                
    assign espi_data_out[1] = (trigger_output) ? (io_mode[1] ? txshift_data[5] : txshift_data[7]) : (trigger_output_high ? 1'b1 : ((trigger_alert && !alert_mode) ? 1'b0 : 1'bz));

    assign espi_data_out[2] = (trigger_output) ? (io_mode[1] ? txshift_data[6] : 1'bz) : ((trigger_output_high && io_mode[1]) ? 1'b1 : 1'bz);

    assign espi_data_out[3] = (trigger_output) ? (io_mode[1] ? txshift_data[7] : 1'bz) : ((trigger_output_high && io_mode[1]) ? 1'b1 : 1'bz);
end
endgenerate


endmodule
