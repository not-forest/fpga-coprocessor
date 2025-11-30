	component coproc_soft_cpu is
		port (
			i_clk_clk                              : in  std_logic                     := 'X';             -- clk
			i_clr_reset_n                          : in  std_logic                     := 'X';             -- reset_n
			o_data_batch_export_i_rd_clk           : in  std_logic                     := 'X';             -- i_rd_clk
			o_data_batch_export_i_rd_row           : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- i_rd_row
			o_data_batch_export_o_data             : out std_logic_vector(7 downto 0);                     -- o_data
			o_data_batch_export_i_rd_col           : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- i_rd_col
			o_data_batch_export_o_sticky           : out std_logic_vector(7 downto 0);                     -- o_sticky
			o_serializer_export_i_acc              : in  std_logic_vector(31 downto 0) := (others => 'X'); -- i_acc
			o_serializer_export_o_clr              : out std_logic;                                        -- o_clr
			o_serializer_export_i_rx_ready         : in  std_logic                     := 'X';             -- i_rx_ready
			o_serializer_export_o_iterations       : out std_logic_vector(31 downto 0);                    -- o_iterations
			o_serializer_export_o_iterations_write : out std_logic;                                        -- o_iterations_write
			o_serializer_export_o_rx_ready         : out std_logic;                                        -- o_rx_ready
			o_spi_export_MISO                      : out std_logic;                                        -- MISO
			o_spi_export_MOSI                      : in  std_logic                     := 'X';             -- MOSI
			o_spi_export_SCLK                      : in  std_logic                     := 'X';             -- SCLK
			o_spi_export_SS_n                      : in  std_logic                     := 'X';             -- SS_n
			o_weight_batch_export_i_rd_clk         : in  std_logic                     := 'X';             -- i_rd_clk
			o_weight_batch_export_i_rd_row         : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- i_rd_row
			o_weight_batch_export_o_data           : out std_logic_vector(7 downto 0);                     -- o_data
			o_weight_batch_export_i_rd_col         : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- i_rd_col
			o_weight_batch_export_o_sticky         : out std_logic_vector(7 downto 0)                      -- o_sticky
		);
	end component coproc_soft_cpu;

	u0 : component coproc_soft_cpu
		port map (
			i_clk_clk                              => CONNECTED_TO_i_clk_clk,                              --                 i_clk.clk
			i_clr_reset_n                          => CONNECTED_TO_i_clr_reset_n,                          --                 i_clr.reset_n
			o_data_batch_export_i_rd_clk           => CONNECTED_TO_o_data_batch_export_i_rd_clk,           --   o_data_batch_export.i_rd_clk
			o_data_batch_export_i_rd_row           => CONNECTED_TO_o_data_batch_export_i_rd_row,           --                      .i_rd_row
			o_data_batch_export_o_data             => CONNECTED_TO_o_data_batch_export_o_data,             --                      .o_data
			o_data_batch_export_i_rd_col           => CONNECTED_TO_o_data_batch_export_i_rd_col,           --                      .i_rd_col
			o_data_batch_export_o_sticky           => CONNECTED_TO_o_data_batch_export_o_sticky,           --                      .o_sticky
			o_serializer_export_i_acc              => CONNECTED_TO_o_serializer_export_i_acc,              --   o_serializer_export.i_acc
			o_serializer_export_o_clr              => CONNECTED_TO_o_serializer_export_o_clr,              --                      .o_clr
			o_serializer_export_i_rx_ready         => CONNECTED_TO_o_serializer_export_i_rx_ready,         --                      .i_rx_ready
			o_serializer_export_o_iterations       => CONNECTED_TO_o_serializer_export_o_iterations,       --                      .o_iterations
			o_serializer_export_o_iterations_write => CONNECTED_TO_o_serializer_export_o_iterations_write, --                      .o_iterations_write
			o_serializer_export_o_rx_ready         => CONNECTED_TO_o_serializer_export_o_rx_ready,         --                      .o_rx_ready
			o_spi_export_MISO                      => CONNECTED_TO_o_spi_export_MISO,                      --          o_spi_export.MISO
			o_spi_export_MOSI                      => CONNECTED_TO_o_spi_export_MOSI,                      --                      .MOSI
			o_spi_export_SCLK                      => CONNECTED_TO_o_spi_export_SCLK,                      --                      .SCLK
			o_spi_export_SS_n                      => CONNECTED_TO_o_spi_export_SS_n,                      --                      .SS_n
			o_weight_batch_export_i_rd_clk         => CONNECTED_TO_o_weight_batch_export_i_rd_clk,         -- o_weight_batch_export.i_rd_clk
			o_weight_batch_export_i_rd_row         => CONNECTED_TO_o_weight_batch_export_i_rd_row,         --                      .i_rd_row
			o_weight_batch_export_o_data           => CONNECTED_TO_o_weight_batch_export_o_data,           --                      .o_data
			o_weight_batch_export_i_rd_col         => CONNECTED_TO_o_weight_batch_export_i_rd_col,         --                      .i_rd_col
			o_weight_batch_export_o_sticky         => CONNECTED_TO_o_weight_batch_export_o_sticky          --                      .o_sticky
		);

