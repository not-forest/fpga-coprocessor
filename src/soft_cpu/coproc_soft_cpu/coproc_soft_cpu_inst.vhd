	component coproc_soft_cpu is
		port (
			i_clk_clk                                : in  std_logic                     := 'X';             -- clk
			i_clr_reset_n                            : in  std_logic                     := 'X';             -- reset_n
			o_batch_data_export_conduit_i_rd_clk     : in  std_logic                     := 'X';             -- conduit_i_rd_clk
			o_batch_data_export_conduit_i_rd_row     : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- conduit_i_rd_row
			o_batch_data_export_conduit_o_data       : out std_logic_vector(63 downto 0);                    -- conduit_o_data
			o_batch_data_export_conduit_o_rd_ready   : out std_logic;                                        -- conduit_o_rd_ready
			o_batch_weight_export_conduit_i_rd_clk   : in  std_logic                     := 'X';             -- conduit_i_rd_clk
			o_batch_weight_export_conduit_i_rd_row   : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- conduit_i_rd_row
			o_batch_weight_export_conduit_o_data     : out std_logic_vector(63 downto 0);                    -- conduit_o_data
			o_batch_weight_export_conduit_o_rd_ready : out std_logic;                                        -- conduit_o_rd_ready
			o_spi_export_MISO                        : out std_logic;                                        -- MISO
			o_spi_export_MOSI                        : in  std_logic                     := 'X';             -- MOSI
			o_spi_export_SCLK                        : in  std_logic                     := 'X';             -- SCLK
			o_spi_export_SS_n                        : in  std_logic                     := 'X'              -- SS_n
		);
	end component coproc_soft_cpu;

	u0 : component coproc_soft_cpu
		port map (
			i_clk_clk                                => CONNECTED_TO_i_clk_clk,                                --                 i_clk.clk
			i_clr_reset_n                            => CONNECTED_TO_i_clr_reset_n,                            --                 i_clr.reset_n
			o_batch_data_export_conduit_i_rd_clk     => CONNECTED_TO_o_batch_data_export_conduit_i_rd_clk,     --   o_batch_data_export.conduit_i_rd_clk
			o_batch_data_export_conduit_i_rd_row     => CONNECTED_TO_o_batch_data_export_conduit_i_rd_row,     --                      .conduit_i_rd_row
			o_batch_data_export_conduit_o_data       => CONNECTED_TO_o_batch_data_export_conduit_o_data,       --                      .conduit_o_data
			o_batch_data_export_conduit_o_rd_ready   => CONNECTED_TO_o_batch_data_export_conduit_o_rd_ready,   --                      .conduit_o_rd_ready
			o_batch_weight_export_conduit_i_rd_clk   => CONNECTED_TO_o_batch_weight_export_conduit_i_rd_clk,   -- o_batch_weight_export.conduit_i_rd_clk
			o_batch_weight_export_conduit_i_rd_row   => CONNECTED_TO_o_batch_weight_export_conduit_i_rd_row,   --                      .conduit_i_rd_row
			o_batch_weight_export_conduit_o_data     => CONNECTED_TO_o_batch_weight_export_conduit_o_data,     --                      .conduit_o_data
			o_batch_weight_export_conduit_o_rd_ready => CONNECTED_TO_o_batch_weight_export_conduit_o_rd_ready, --                      .conduit_o_rd_ready
			o_spi_export_MISO                        => CONNECTED_TO_o_spi_export_MISO,                        --          o_spi_export.MISO
			o_spi_export_MOSI                        => CONNECTED_TO_o_spi_export_MOSI,                        --                      .MOSI
			o_spi_export_SCLK                        => CONNECTED_TO_o_spi_export_SCLK,                        --                      .SCLK
			o_spi_export_SS_n                        => CONNECTED_TO_o_spi_export_SS_n                         --                      .SS_n
		);

