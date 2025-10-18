	coproc_soft_cpu u0 (
		.i_clk_clk                                                    (<connected-to-i_clk_clk>),                                                    //        i_clk.clk
		.i_clr_reset_n                                                (<connected-to-i_clr_reset_n>),                                                //        i_clr.reset_n
		.o_dbg_reset_reset                                            (<connected-to-o_dbg_reset_reset>),                                            //  o_dbg_reset.reset
		.o_spi_export_mosi_to_the_spislave_inst_for_spichain          (<connected-to-o_spi_export_mosi_to_the_spislave_inst_for_spichain>),          // o_spi_export.mosi_to_the_spislave_inst_for_spichain
		.o_spi_export_nss_to_the_spislave_inst_for_spichain           (<connected-to-o_spi_export_nss_to_the_spislave_inst_for_spichain>),           //             .nss_to_the_spislave_inst_for_spichain
		.o_spi_export_miso_to_and_from_the_spislave_inst_for_spichain (<connected-to-o_spi_export_miso_to_and_from_the_spislave_inst_for_spichain>), //             .miso_to_and_from_the_spislave_inst_for_spichain
		.o_spi_export_sclk_to_the_spislave_inst_for_spichain          (<connected-to-o_spi_export_sclk_to_the_spislave_inst_for_spichain>)           //             .sclk_to_the_spislave_inst_for_spichain
	);

