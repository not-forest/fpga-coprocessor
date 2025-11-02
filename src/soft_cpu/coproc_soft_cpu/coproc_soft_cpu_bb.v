
module coproc_soft_cpu (
	i_clk_clk,
	i_clr_reset_n,
	o_batch_data_export_conduit_i_rd_clk,
	o_batch_data_export_conduit_i_rd_row,
	o_batch_data_export_conduit_o_data,
	o_batch_data_export_conduit_o_rd_ready,
	o_batch_weight_export_conduit_i_rd_clk,
	o_batch_weight_export_conduit_i_rd_row,
	o_batch_weight_export_conduit_o_data,
	o_batch_weight_export_conduit_o_rd_ready,
	o_spi_export_MISO,
	o_spi_export_MOSI,
	o_spi_export_SCLK,
	o_spi_export_SS_n,
	o_serializer_export_i_acc,
	o_serializer_export_o_clr,
	o_serializer_export_o_read);	

	input		i_clk_clk;
	input		i_clr_reset_n;
	input		o_batch_data_export_conduit_i_rd_clk;
	input	[2:0]	o_batch_data_export_conduit_i_rd_row;
	output	[63:0]	o_batch_data_export_conduit_o_data;
	output		o_batch_data_export_conduit_o_rd_ready;
	input		o_batch_weight_export_conduit_i_rd_clk;
	input	[2:0]	o_batch_weight_export_conduit_i_rd_row;
	output	[63:0]	o_batch_weight_export_conduit_o_data;
	output		o_batch_weight_export_conduit_o_rd_ready;
	output		o_spi_export_MISO;
	input		o_spi_export_MOSI;
	input		o_spi_export_SCLK;
	input		o_spi_export_SS_n;
	input	[23:0]	o_serializer_export_i_acc;
	output		o_serializer_export_o_clr;
	output		o_serializer_export_o_read;
endmodule
