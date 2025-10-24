	coproc_soft_cpu u0 (
		.i_clk_clk         (<connected-to-i_clk_clk>),         //        i_clk.clk
		.i_clr_reset_n     (<connected-to-i_clr_reset_n>),     //        i_clr.reset_n
		.o_spi_export_MISO (<connected-to-o_spi_export_MISO>), // o_spi_export.MISO
		.o_spi_export_MOSI (<connected-to-o_spi_export_MOSI>), //             .MOSI
		.o_spi_export_SCLK (<connected-to-o_spi_export_SCLK>), //             .SCLK
		.o_spi_export_SS_n (<connected-to-o_spi_export_SS_n>)  //             .SS_n
	);

