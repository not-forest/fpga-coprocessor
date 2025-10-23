
module coproc_soft_cpu (
	i_clk_clk,
	i_clr_reset_n,
	o_spi_export_mosi_to_the_spislave_inst_for_spichain,
	o_spi_export_nss_to_the_spislave_inst_for_spichain,
	o_spi_export_miso_to_and_from_the_spislave_inst_for_spichain,
	o_spi_export_sclk_to_the_spislave_inst_for_spichain,
	o_dbg_reset_reset);	

	input		i_clk_clk;
	input		i_clr_reset_n;
	input		o_spi_export_mosi_to_the_spislave_inst_for_spichain;
	input		o_spi_export_nss_to_the_spislave_inst_for_spichain;
	inout		o_spi_export_miso_to_and_from_the_spislave_inst_for_spichain;
	input		o_spi_export_sclk_to_the_spislave_inst_for_spichain;
	output		o_dbg_reset_reset;
endmodule
