	coproc_soft_cpu u0 (
		.i_clk_clk                              (<connected-to-i_clk_clk>),                              //                 i_clk.clk
		.i_clr_reset_n                          (<connected-to-i_clr_reset_n>),                          //                 i_clr.reset_n
		.o_data_batch_export_i_rd_clk           (<connected-to-o_data_batch_export_i_rd_clk>),           //   o_data_batch_export.i_rd_clk
		.o_data_batch_export_i_rd_row           (<connected-to-o_data_batch_export_i_rd_row>),           //                      .i_rd_row
		.o_data_batch_export_o_data             (<connected-to-o_data_batch_export_o_data>),             //                      .o_data
		.o_data_batch_export_i_rd_col           (<connected-to-o_data_batch_export_i_rd_col>),           //                      .i_rd_col
		.o_data_batch_export_o_sticky           (<connected-to-o_data_batch_export_o_sticky>),           //                      .o_sticky
		.o_serializer_export_i_acc              (<connected-to-o_serializer_export_i_acc>),              //   o_serializer_export.i_acc
		.o_serializer_export_o_clr              (<connected-to-o_serializer_export_o_clr>),              //                      .o_clr
		.o_serializer_export_i_rx_ready         (<connected-to-o_serializer_export_i_rx_ready>),         //                      .i_rx_ready
		.o_serializer_export_o_iterations       (<connected-to-o_serializer_export_o_iterations>),       //                      .o_iterations
		.o_serializer_export_o_iterations_write (<connected-to-o_serializer_export_o_iterations_write>), //                      .o_iterations_write
		.o_serializer_export_o_rx_ready         (<connected-to-o_serializer_export_o_rx_ready>),         //                      .o_rx_ready
		.o_spi_export_MISO                      (<connected-to-o_spi_export_MISO>),                      //          o_spi_export.MISO
		.o_spi_export_MOSI                      (<connected-to-o_spi_export_MOSI>),                      //                      .MOSI
		.o_spi_export_SCLK                      (<connected-to-o_spi_export_SCLK>),                      //                      .SCLK
		.o_spi_export_SS_n                      (<connected-to-o_spi_export_SS_n>),                      //                      .SS_n
		.o_weight_batch_export_i_rd_clk         (<connected-to-o_weight_batch_export_i_rd_clk>),         // o_weight_batch_export.i_rd_clk
		.o_weight_batch_export_i_rd_row         (<connected-to-o_weight_batch_export_i_rd_row>),         //                      .i_rd_row
		.o_weight_batch_export_o_data           (<connected-to-o_weight_batch_export_o_data>),           //                      .o_data
		.o_weight_batch_export_i_rd_col         (<connected-to-o_weight_batch_export_i_rd_col>),         //                      .i_rd_col
		.o_weight_batch_export_o_sticky         (<connected-to-o_weight_batch_export_o_sticky>)          //                      .o_sticky
	);

