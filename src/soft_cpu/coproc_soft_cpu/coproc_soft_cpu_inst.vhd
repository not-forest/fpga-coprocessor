	component coproc_soft_cpu is
		port (
			i_clk_clk                                                    : in    std_logic := 'X'; -- clk
			i_clr_reset_n                                                : in    std_logic := 'X'; -- reset_n
			o_spi_export_mosi_to_the_spislave_inst_for_spichain          : in    std_logic := 'X'; -- mosi_to_the_spislave_inst_for_spichain
			o_spi_export_nss_to_the_spislave_inst_for_spichain           : in    std_logic := 'X'; -- nss_to_the_spislave_inst_for_spichain
			o_spi_export_miso_to_and_from_the_spislave_inst_for_spichain : inout std_logic := 'X'; -- miso_to_and_from_the_spislave_inst_for_spichain
			o_spi_export_sclk_to_the_spislave_inst_for_spichain          : in    std_logic := 'X'; -- sclk_to_the_spislave_inst_for_spichain
			o_dbg_reset_reset                                            : out   std_logic         -- reset
		);
	end component coproc_soft_cpu;

	u0 : component coproc_soft_cpu
		port map (
			i_clk_clk                                                    => CONNECTED_TO_i_clk_clk,                                                    --        i_clk.clk
			i_clr_reset_n                                                => CONNECTED_TO_i_clr_reset_n,                                                --        i_clr.reset_n
			o_spi_export_mosi_to_the_spislave_inst_for_spichain          => CONNECTED_TO_o_spi_export_mosi_to_the_spislave_inst_for_spichain,          -- o_spi_export.mosi_to_the_spislave_inst_for_spichain
			o_spi_export_nss_to_the_spislave_inst_for_spichain           => CONNECTED_TO_o_spi_export_nss_to_the_spislave_inst_for_spichain,           --             .nss_to_the_spislave_inst_for_spichain
			o_spi_export_miso_to_and_from_the_spislave_inst_for_spichain => CONNECTED_TO_o_spi_export_miso_to_and_from_the_spislave_inst_for_spichain, --             .miso_to_and_from_the_spislave_inst_for_spichain
			o_spi_export_sclk_to_the_spislave_inst_for_spichain          => CONNECTED_TO_o_spi_export_sclk_to_the_spislave_inst_for_spichain,          --             .sclk_to_the_spislave_inst_for_spichain
			o_dbg_reset_reset                                            => CONNECTED_TO_o_dbg_reset_reset                                             --  o_dbg_reset.reset
		);

