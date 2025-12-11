-- ============================================================
-- File: coprocessor.vhd
-- Desc: Top level entity of the FPGA Coprocessor implementation.
-- ============================================================
--
-- BSD 2-Clause 
--
-- Copyright (c) 2025, notforest.
--
-- Redistribution and use in source and binary forms, with or without modification, are permitted 
-- provided that the following conditions are met:
--
--  1. Redistributions of source code must retain the above copyright notice, this list of conditions 
-- and the following disclaimer.
--  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
-- and the following disclaimer in the documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
-- INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
-- SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
-- STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN 
-- IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

library coproc;
library ieee;

use ieee.std_logic_1164.all;
use coproc.intrinsics.all;
use ieee.numeric_std.all;

entity coprocessor is
    generic (
        g_OMD       : natural := 8              -- Operating matrix dimensions.
    );
    port (
        i_clk       : in std_logic := '0';      -- Stable PLL clock input.
        ni_rst      : in std_logic := '1';      -- Hard reset signal.
        
        i_sclk      : in  std_logic;            -- SPI clock
        ni_ss       : in  std_logic;            -- Slave select (active low)
        i_mosi      : in  std_logic;            -- Master Out Slave In
        io_miso     : inout std_logic           -- Master In Slave Out
         );
end entity;

architecture structured of coprocessor is 
    signal r_cmd : t_command := c_UDEFCMD;                  -- Internally stored coprocessor command.
    signal w_writew, w_writex : std_logic := '0';           -- Word shift enable signals.
    signal w_dataW, w_dataX : t_word := (others => '0');    -- Data and weight signals.

    signal w_spi_sink : t_spi_word := (others => '0');                      -- SPI sink data lane.
    signal w_spi_sink_i_ready, w_spi_sink_o_ready : std_logic := '0';       -- SPI sink FIFO communication signals.
    signal w_spi_source : t_spi_word := (others => '0');                    -- SPI source data lane.
    signal w_spi_source_i_ready, w_spi_source_o_ready : std_logic := '0';   -- SPI source FIFO communication signals.
begin
    -- SPI slave controller IP wrapper.
    SPI_SLAVE_Inst : entity coproc.spi_slave
    port map (
		i_stsinkvalid => w_spi_sink_o_ready,
		i_stsinkdata => w_spi_sink,
		o_stsinkready => w_spi_sink_i_ready,
		i_stsourceready => w_spi_source_i_ready,
		o_stsourcevalid => w_spi_source_o_ready,
		o_stsourcedata => w_spi_source,
		i_sysclk => i_clk,
		i_nreset => ni_rst,
		i_mosi => i_mosi,
		i_nss => ni_ss,
		io_miso => io_miso,
		i_sclk => i_sclk
             );

    -- Sequencer block for input parsing and reshaping.
    SEQUENCER_Inst : entity coproc.sequencer
    port map (
        i_sclk => i_sclk,
        i_clk => i_clk,
        na_clr => ni_rst,
        io_cmd => r_cmd,
        o_dataW => w_dataW,
        o_dataX => w_dataX,
        o_shiftX_ready => w_writex, 
        o_shiftW_ready => w_writew, 
        o_read_ready => w_spi_sink_o_ready,  
        i_read_ready => w_spi_sink_i_ready,
        i_read => w_spi_sink
             );

    -- Main systolic array computational block.
    SYSTOLIC_ARR_Inst : entity coproc.systolic_arr
    generic map (
        g_OMD => g_OMD
                )
    port map (
        ni_clr => ni_rst,
        i_clk => i_clk,
        i_writex => w_writex,
        i_writew => w_writew,
    
        i_se_clr => open,
        i_se_iterations => open,
        i_se_iterations_write => open,

        i_rx_ready => open,
        o_rx_ready => open,

        i_dataX => w_dataX,
        i_dataW => w_dataW,
        o_dataA => open
             );
end architecture;
