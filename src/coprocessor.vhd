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
        io_miso     : inout std_logic;          -- Master In Slave Out
        o_ready     : out std_logic             -- Flags whether new data is ready to be read.
         );
end entity;

architecture structured of coprocessor is 
    signal r_cmd : t_command := c_UDEFCMD;                  -- Internally stored coprocessor command.
    signal w_shift_ready : std_logic := '0';                -- Goes high when new parsed data is ready to shift.
    signal w_dataW, w_dataX : t_word := (others => '0');    -- Data and weight signals.

    signal w_spi_sink : t_spi_word := (others => '0');                  -- SPI sink data lane.
    signal w_spi_sink_ready, w_spi_sink_valid : std_logic := '0';       -- SPI sink FIFO communication signals.
    signal w_spi_source : t_spi_word := (others => '0');                -- SPI source data lane.
    signal w_spi_source_ready, w_spi_source_valid : std_logic := '0';   -- SPI source FIFO communication signals.
    signal w_new_cmd : std_logic := '0';

    -- Declaring component for the ability to choose a configuration.
    component C_spi_slave is
        port (
		    i_stsinkvalid       : in std_logic                    := '0';
		    i_stsinkdata        : in t_spi_word := (others => '0');      
		    o_stsinkready       : out std_logic;                         
		    i_stsourceready     : in std_logic                    := '0';
		    o_stsourcevalid     : out std_logic;                         
		    o_stsourcedata      : out t_spi_word := (others => '0');     
		    i_sysclk            : in std_logic                    := '0';
		    i_nreset            : in std_logic                    := '0';
		    i_mosi              : in std_logic                    := '0';
		    i_nss               : in std_logic                    := '0';
		    io_miso             : inout std_logic                 := '0';
		    i_sclk              : in std_logic                    := '0' 
             );
    end component;
begin
    o_ready <= w_spi_sink_valid;
    -- SPI slave controller IP wrapper.
    SPI_SLAVE_Inst : entity coproc.spi_slave
    port map (
		i_stsinkvalid => w_spi_sink_valid,
		i_stsinkdata => w_spi_sink,
		o_stsinkready => w_spi_sink_ready,
		i_stsourceready => w_spi_source_ready,
		o_stsourcevalid => w_spi_source_valid,
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
        ni_ss => ni_ss,
        na_clr => ni_rst,
        io_cmd => r_cmd,
        o_dataW => w_dataW,
        o_dataX => w_dataX,
        o_shift_ready => w_shift_ready,
        o_new_cmd => w_new_cmd,
        o_read_ready => w_spi_source_ready,  
        i_read_ready => w_spi_source_valid,
        i_read => w_spi_source
             );

    -- Main systolic array computational block.
    SYSTOLIC_ARR_Inst : entity coproc.systolic_arr
    generic map (
        g_OMD => g_OMD
                )
    port map (
        na_clr => ni_rst,
        i_clk => i_clk,
        ni_ss => ni_ss,
        i_spi_clk => i_sclk,
        i_shift_ready => w_shift_ready,
    
        i_se_clr => '0',
        i_batch_length => r_cmd.m(log2(g_OMD) - 1 downto 0),
        i_se_iterations => r_cmd.n,
        i_se_iterations_write => w_new_cmd,

        i_rx_ready => w_spi_sink_ready,
        o_rx_ready => w_spi_sink_valid,

        i_dataX => w_dataX,
        i_dataW => w_dataW,
        o_dataA => w_spi_sink
             );
end architecture;

-- Additional configuration of SPI slave architecture (vendor/simulation(rtl)).
--configuration CoprocessorConfig of coprocessor is
--    for structured
--        for SPI_SLAVE_Inst : C_spi_slave
--            use entity coproc.spi_slave(rtl);
--        end for;
--    end for;
--end configuration;
