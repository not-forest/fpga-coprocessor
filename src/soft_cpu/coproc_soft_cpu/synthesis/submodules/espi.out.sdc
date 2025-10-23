# (C) 2001-2025 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and other 
# software and tools, and its AMPP partner logic functions, and any output 
# files from any of the foregoing (including device programming or simulation 
# files), and any associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License Subscription 
# Agreement, Altera IP License Agreement, or other applicable 
# license agreement, including, without limitation, that your use is for the 
# sole purpose of programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the applicable 
# agreement for further details.


## Generated SDC file "espi.out.sdc"

## Copyright (C) 2017  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 17.1.0 Build 590 10/25/2017 SJ Standard Edition"

## DATE    "Fri Dec 22 18:26:35 2017"

##
## DEVICE  "10M02DCU324A6G"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

#---------- User will have to change <ip_clock_name> to the IP clock name at the top level wrapper file ------------
#---------- User will have to change <spi_clock_name> to the SPI clock name at the top level wrapper file ----------

#create_clock -name {<ip_clock_name>} -period 6.667 -waveform { 0.000 3.333 } [get_ports {<ip_clock_name>}]
#create_clock -name {<spi_clock_name>} -period 15.000 -waveform { 0.000 7.500 } [get_ports {<spi_clock_name>}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_registers {*espi_register:espi_register_inst|io_mode[0] *espi_register:espi_register_inst|io_mode[1]}] 
set_false_path -to [get_registers {*espi_condt_det:espi_condt_det_inst|rx_detect_command_nxt}]
set_false_path -to [get_registers {*espi_condt_det:espi_condt_det_inst|trigger_output_nxt}]
set_false_path -to [get_registers {*espi_condt_det:espi_condt_det_inst|error_condition1_nxt}]
set_false_path -to [get_registers {*espi_condt_det:espi_condt_det_inst|detect_rx_idle_nxt}]
set_false_path -to [get_registers {*espi_condt_det:espi_condt_det_inst|detect_tx_idle_nxt}]
set_false_path -to [get_registers {*espi_condt_det:espi_condt_det_inst|rx_detect_crc_nxt}]
set_false_path -to [get_registers {*espi_condt_det:espi_condt_det_inst|tx_gen_crc_nxt}]
set_false_path -to [get_registers {*espi_condt_det:espi_condt_det_inst|espi_cs_n_nxt}]
set_false_path -to [get_registers {*espi_condt_det:espi_condt_det_inst|spiclk_cnt_done_nxt}]
set_false_path -to [get_registers {*espi_condt_det:espi_condt_det_inst|posspiclk_cnt_done_nxt}]
set_false_path -to [get_registers {*espi_condt_det:espi_condt_det_inst|rxshift_data_nxt[0] *espi_condt_det:espi_condt_det_inst|rxshift_data_nxt[1] *espi_condt_det:espi_condt_det_inst|rxshift_data_nxt[2] *espi_condt_det:espi_condt_det_inst|rxshift_data_nxt[3] *espi_condt_det:espi_condt_det_inst|rxshift_data_nxt[4] *espi_condt_det:espi_condt_det_inst|rxshift_data_nxt[5] *espi_condt_det:espi_condt_det_inst|rxshift_data_nxt[6] *espi_condt_det:espi_condt_det_inst|rxshift_data_nxt[7]}]
set_false_path -to [get_registers {*espi_condt_det:espi_condt_det_inst|tx_dataout_byte_nxt[0] *espi_condt_det:espi_condt_det_inst|tx_dataout_byte_nxt[1] *espi_condt_det:espi_condt_det_inst|tx_dataout_byte_nxt[2] *espi_condt_det:espi_condt_det_inst|tx_dataout_byte_nxt[3] *espi_condt_det:espi_condt_det_inst|tx_dataout_byte_nxt[4] *espi_condt_det:espi_condt_det_inst|tx_dataout_byte_nxt[5] *espi_condt_det:espi_condt_det_inst|tx_dataout_byte_nxt[6] *espi_condt_det:espi_condt_det_inst|tx_dataout_byte_nxt[7]}]
set_false_path -from [get_keepers {*error_condition1}] -to [get_registers {*espi_condt_det_inst|spiclk_cnt[0] *espi_condt_det_inst|spiclk_cnt[1] *espi_condt_det_inst|spiclk_cnt[2] *espi_condt_det_inst|spiclk_cnt[3]}]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

