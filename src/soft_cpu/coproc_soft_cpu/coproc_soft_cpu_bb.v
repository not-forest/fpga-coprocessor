
module coproc_soft_cpu (
	i_clk_clk,
	i_clr_reset_n,
	o_spi_export_MISO,
	o_spi_export_MOSI,
	o_spi_export_SCLK,
	o_spi_export_SS_n);	

	input		i_clk_clk;
	input		i_clr_reset_n;
	output		o_spi_export_MISO;
	input		o_spi_export_MOSI;
	input		o_spi_export_SCLK;
	input		o_spi_export_SS_n;
endmodule
