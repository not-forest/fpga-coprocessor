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
library coproc_soft_cpu;
library ieee;

use ieee.std_logic_1164.all;
use coproc.intrinsics.all;
use coproc_soft_cpu.all;

entity coprocessor is
    port (
        i_clk       : in std_logic := '0';      -- Stable PLL clock input.
        ni_rst      : in std_logic := '1';      -- Hard reset signal.
        
        i_sclk      : in  std_logic;            -- SPI clock
        ni_ss       : in  std_logic;            -- Slave select (active low)
        i_mosi      : in  std_logic;            -- Master Out Slave In
        o_miso      : out std_logic             -- Master In Slave Out
         );
end entity;

architecture structured of coprocessor is 
    component coproc_soft_cpu is
        port (
            i_clk_clk               : in    std_logic := '0';
            i_clr_reset_n           : in    std_logic := '0';
			
            -- -- Conduit Exports. -- --

            -- SPI_0
            o_spi_export_MISO       : out std_logic;
			o_spi_export_MOSI       : in  std_logic := 'X';
			o_spi_export_SCLK       : in  std_logic := 'X';
			o_spi_export_SS_n       : in  std_logic := 'X'; 

            -- WEIGHT_BATCH
            o_batch_weight_export_conduit_i_rd_clk      : in std_logic := 'X';
            o_batch_weight_export_conduit_i_rd_row      : in std_logic_vector(2 downto 0) := (others => 'X');
            o_batch_weight_export_conduit_o_data        : out std_logic_vector(8 * t_word'length - 1 downto 0);
            o_batch_weight_export_conduit_o_rd_ready    : out std_logic;

            -- DATA_BATCH
            o_batch_data_export_conduit_i_rd_clk      : in std_logic := 'X';
            o_batch_data_export_conduit_i_rd_row      : in std_logic_vector(2 downto 0) := (others => 'X');
            o_batch_data_export_conduit_o_data        : out std_logic_vector(8 * t_word'length - 1 downto 0);
            o_batch_data_export_conduit_o_rd_ready    : out std_logic;

            -- SERIALIZER
            o_serializer_export_i_acc  : in t_niosv_word := (others => 'X');
            o_serializer_export_o_clr  : out std_logic; 
            o_serializer_export_o_read : out std_logic 
        );
    end component;

    -- Interconnect signals.
    signal wbe_i_rd_clk     : std_logic;
    signal wbe_i_rd_row     : std_logic_vector(2 downto 0);
    signal wbe_o_data       : std_logic_vector(8 * t_word'length - 1 downto 0);
    signal wbe_o_rd_ready   : std_logic;

    signal dbe_i_rd_clk     : std_logic;
    signal dbe_i_rd_row     : std_logic_vector(2 downto 0);
    signal dbe_o_data       : std_logic_vector(8 * t_word'length - 1 downto 0);
    signal dbe_o_rd_ready   : std_logic;

    signal se_i_acc     : t_acc;
    signal se_o_clr     : std_logic;
    signal se_o_read    : std_logic;
begin
    -- Generating internal NIOS V/m soft CPU core to parse upcoming SPI traffic
    COPROC_SOFT_CPU_Inst : coproc_soft_cpu
    port map (
        i_clk_clk => i_clk,
        i_clr_reset_n => ni_rst,
        o_spi_export_SS_n => ni_ss,
        o_spi_export_SCLK => i_sclk,
        o_spi_export_MOSI => i_mosi,
        o_spi_export_MISO => o_miso,

        o_batch_weight_export_conduit_i_rd_clk => wbe_i_rd_clk,
        o_batch_weight_export_conduit_i_rd_row => wbe_i_rd_row,
        o_batch_weight_export_conduit_o_data => wbe_o_data,
        o_batch_weight_export_conduit_o_rd_ready => wbe_o_rd_ready,

        o_batch_data_export_conduit_i_rd_clk => dbe_i_rd_clk,
        o_batch_data_export_conduit_i_rd_row => dbe_i_rd_row,
        o_batch_data_export_conduit_o_data => dbe_o_data,
        o_batch_data_export_conduit_o_rd_ready => dbe_o_rd_ready,

        o_serializer_export_i_acc(23 downto 0) => se_i_acc,
        o_serializer_export_o_clr => se_o_clr,
        o_serializer_export_o_read => se_o_read
             );

    -- Converts accumulated PE's output to serial stream of values for NIOS V to read.
    SERIALIZER_Inst : entity coproc.serializer
    generic map (
        g_OMD => 64
                )
    port map (
        i_clk => i_clk,
        na_clr => ni_rst,
        i_clr => se_o_clr,
        o_acc => se_i_acc,
        i_read => se_o_read,
        i_accs => (others => (others => (others => '0')))   -- Temp
             );
end architecture;
