	component coproc_soft_cpu is
		port (
			i_clk_clk         : in  std_logic := 'X'; -- clk
			i_clr_reset_n     : in  std_logic := 'X'; -- reset_n
			o_spi_export_MISO : out std_logic;        -- MISO
			o_spi_export_MOSI : in  std_logic := 'X'; -- MOSI
			o_spi_export_SCLK : in  std_logic := 'X'; -- SCLK
			o_spi_export_SS_n : in  std_logic := 'X'  -- SS_n
		);
	end component coproc_soft_cpu;

	u0 : component coproc_soft_cpu
		port map (
			i_clk_clk         => CONNECTED_TO_i_clk_clk,         --        i_clk.clk
			i_clr_reset_n     => CONNECTED_TO_i_clr_reset_n,     --        i_clr.reset_n
			o_spi_export_MISO => CONNECTED_TO_o_spi_export_MISO, -- o_spi_export.MISO
			o_spi_export_MOSI => CONNECTED_TO_o_spi_export_MOSI, --             .MOSI
			o_spi_export_SCLK => CONNECTED_TO_o_spi_export_SCLK, --             .SCLK
			o_spi_export_SS_n => CONNECTED_TO_o_spi_export_SS_n  --             .SS_n
		);

