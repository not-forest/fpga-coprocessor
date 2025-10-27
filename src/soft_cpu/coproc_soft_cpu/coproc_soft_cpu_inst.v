	coproc_soft_cpu u0 (
		.i_clk_clk                                (<connected-to-i_clk_clk>),                                //                 i_clk.clk
		.i_clr_reset_n                            (<connected-to-i_clr_reset_n>),                            //                 i_clr.reset_n
		.o_spi_export_MISO                        (<connected-to-o_spi_export_MISO>),                        //          o_spi_export.MISO
		.o_spi_export_MOSI                        (<connected-to-o_spi_export_MOSI>),                        //                      .MOSI
		.o_spi_export_SCLK                        (<connected-to-o_spi_export_SCLK>),                        //                      .SCLK
		.o_spi_export_SS_n                        (<connected-to-o_spi_export_SS_n>),                        //                      .SS_n
		.o_batch_weight_export_conduit_i_rd_clk   (<connected-to-o_batch_weight_export_conduit_i_rd_clk>),   // o_batch_weight_export.conduit_i_rd_clk
		.o_batch_weight_export_conduit_i_rd_row   (<connected-to-o_batch_weight_export_conduit_i_rd_row>),   //                      .conduit_i_rd_row
		.o_batch_weight_export_conduit_o_data     (<connected-to-o_batch_weight_export_conduit_o_data>),     //                      .conduit_o_data
		.o_batch_weight_export_conduit_o_rd_ready (<connected-to-o_batch_weight_export_conduit_o_rd_ready>), //                      .conduit_o_rd_ready
		.o_batch_data_export_conduit_i_rd_clk     (<connected-to-o_batch_data_export_conduit_i_rd_clk>),     //   o_batch_data_export.conduit_i_rd_clk
		.o_batch_data_export_conduit_i_rd_row     (<connected-to-o_batch_data_export_conduit_i_rd_row>),     //                      .conduit_i_rd_row
		.o_batch_data_export_conduit_o_data       (<connected-to-o_batch_data_export_conduit_o_data>),       //                      .conduit_o_data
		.o_batch_data_export_conduit_o_rd_ready   (<connected-to-o_batch_data_export_conduit_o_rd_ready>)    //                      .conduit_o_rd_ready
	);

