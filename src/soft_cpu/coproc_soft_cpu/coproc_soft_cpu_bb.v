
module coproc_soft_cpu (
	i_clk_clk,
	i_clr_reset_n,
	o_data_batch_export_i_rd_clk,
	o_data_batch_export_i_rd_row,
	o_data_batch_export_o_data,
	o_data_batch_export_i_rd_col,
	o_data_batch_export_o_sticky,
	o_serializer_export_i_acc,
	o_serializer_export_o_clr,
	o_serializer_export_i_rx_ready,
	o_serializer_export_o_iterations,
	o_serializer_export_o_iterations_write,
	o_serializer_export_o_rx_ready,
	o_spi_export_MISO,
	o_spi_export_MOSI,
	o_spi_export_SCLK,
	o_spi_export_SS_n,
	o_weight_batch_export_i_rd_clk,
	o_weight_batch_export_i_rd_row,
	o_weight_batch_export_o_data,
	o_weight_batch_export_i_rd_col,
	o_weight_batch_export_o_sticky);	

	input		i_clk_clk;
	input		i_clr_reset_n;
	input		o_data_batch_export_i_rd_clk;
	input	[2:0]	o_data_batch_export_i_rd_row;
	output	[7:0]	o_data_batch_export_o_data;
	input	[2:0]	o_data_batch_export_i_rd_col;
	output	[7:0]	o_data_batch_export_o_sticky;
	input	[31:0]	o_serializer_export_i_acc;
	output		o_serializer_export_o_clr;
	input		o_serializer_export_i_rx_ready;
	output	[31:0]	o_serializer_export_o_iterations;
	output		o_serializer_export_o_iterations_write;
	output		o_serializer_export_o_rx_ready;
	output		o_spi_export_MISO;
	input		o_spi_export_MOSI;
	input		o_spi_export_SCLK;
	input		o_spi_export_SS_n;
	input		o_weight_batch_export_i_rd_clk;
	input	[2:0]	o_weight_batch_export_i_rd_row;
	output	[7:0]	o_weight_batch_export_o_data;
	input	[2:0]	o_weight_batch_export_i_rd_col;
	output	[7:0]	o_weight_batch_export_o_sticky;
endmodule
