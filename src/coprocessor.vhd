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
use ieee.numeric_std.all;
use coproc_soft_cpu.all;
use coproc.systolic_arr;
use coproc.word_shifter;

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
            o_weight_batch_export_i_rd_clk      : in std_logic := 'X';
            o_weight_batch_export_i_rd_row      : in std_logic_vector(2 downto 0) := (others => 'X');
            o_weight_batch_export_i_rd_col      : in std_logic_vector(2 downto 0) := (others => 'X');
            o_weight_batch_export_o_data        : out std_logic_vector(t_word'length - 1 downto 0);
            o_weight_batch_export_o_sticky      : out std_logic_vector(0 to 7);

            -- DATA_BATCH
            o_data_batch_export_i_rd_clk      : in std_logic := 'X';
            o_data_batch_export_i_rd_row      : in std_logic_vector(2 downto 0) := (others => 'X');
            o_data_batch_export_i_rd_col      : in std_logic_vector(2 downto 0) := (others => 'X');
            o_data_batch_export_o_data        : out std_logic_vector(t_word'length - 1 downto 0);
            o_data_batch_export_o_sticky      : out std_logic_vector(0 to 7);

            -- SERIALIZER
            o_serializer_export_i_acc  : in t_niosv_word := (others => 'X');
            o_serializer_export_o_clr  : out std_logic; 
            o_serializer_export_o_rx_ready : out std_logic;
            o_serializer_export_i_rx_ready : in std_logic;
            o_serializer_export_o_iterations : out t_niosv_word;
            o_serializer_export_o_iterations_write : out std_logic
        );
    end component;

    -- Interconnect signals.
    signal wbe_i_rd_clk     : std_logic;
    signal wbe_i_rd_row     : std_logic_vector(2 downto 0);
    signal wbe_i_rd_col     : std_logic_vector(2 downto 0);
    signal wbe_o_data       : std_logic_vector(t_word'length - 1 downto 0);
    signal wbe_o_sticky     : std_logic_vector(0 to 7);

    signal dbe_i_rd_clk     : std_logic;
    signal dbe_i_rd_row     : std_logic_vector(2 downto 0);
    signal dbe_i_rd_col     : std_logic_vector(2 downto 0);
    signal dbe_o_data       : std_logic_vector(t_word'length - 1 downto 0);
    signal dbe_o_sticky     : std_logic_vector(0 to 7);

    signal se_i_acc         : t_acc;
    signal se_o_clr         : std_logic;
    signal se_o_rx_ready    : std_logic;
    signal se_i_rx_ready    : std_logic;
    signal se_o_iterations  : t_niosv_word;
    signal se_o_iterations_write : std_Logic;

    signal r_systolic_write : std_logic := '0';
begin
    -- Synchronizing batch blocks inputs.
    process (all) is 
        variable i, j: natural := 0;
    begin
        if falling_edge(i_clk) then
            dbe_i_rd_row <= std_logic_vector(to_unsigned(i, dbe_i_rd_row'length));
            dbe_i_rd_col <= std_logic_vector(to_unsigned(j, dbe_i_rd_col'length));
            wbe_i_rd_row <= std_logic_vector(to_unsigned(i, wbe_i_rd_row'length));
            wbe_i_rd_col <= std_logic_vector(to_unsigned(j, wbe_i_rd_col'length)); 

            -- If both batches are ready, starting to fill into both X, W word shifters.
            if wbe_o_sticky(i) = '1' and dbe_o_sticky(i) = '1' then
                r_systolic_write <= not r_systolic_write;
            end if;

            if r_systolic_write = '1' then
                if i < 3 then
                    if j < 3 then
                        j := j + 1;
                    else
                        j := 0;
                        i := i + 1;
                    end if;
                else
                    i := 0;
                    j := 0;
                end if;
            end if;
        end if;
    end process;

    -- Generating internal NIOS V/m soft CPU core to parse upcoming SPI traffic
    COPROC_SOFT_CPU_Inst : coproc_soft_cpu
    port map (
        i_clk_clk => i_clk,
        i_clr_reset_n => ni_rst,
        o_spi_export_SS_n => ni_ss,
        o_spi_export_SCLK => i_sclk,
        o_spi_export_MOSI => i_mosi,
        o_spi_export_MISO => o_miso,

        o_weight_batch_export_i_rd_clk => wbe_i_rd_clk,
        o_weight_batch_export_i_rd_row => wbe_i_rd_row,
        o_weight_batch_export_i_rd_col => wbe_i_rd_col,
        o_weight_batch_export_o_data => wbe_o_data,
        o_weight_batch_export_o_sticky => wbe_o_sticky,

        o_data_batch_export_i_rd_clk => dbe_i_rd_clk,
        o_data_batch_export_i_rd_row => dbe_i_rd_row,
        o_data_batch_export_i_rd_col => dbe_i_rd_col,
        o_data_batch_export_o_data => dbe_o_data,
        o_data_batch_export_o_sticky => dbe_o_sticky,

        o_serializer_export_i_acc(23 downto 0) => se_i_acc,
        o_serializer_export_o_clr => se_o_clr,
        o_serializer_export_o_rx_ready => se_o_rx_ready,
        o_serializer_export_i_rx_ready => se_i_rx_ready,
        o_serializer_export_o_iterations => se_o_iterations,
        o_serializer_export_o_iterations_write => se_o_iterations_write
             );

    SYSTOLIC_ARR_Inst : entity systolic_arr
    generic map (
        g_OMD => 8
                )
    port map (
        ni_clr => ni_rst,
        i_clk => i_clk,
        i_write => r_systolic_write,
    
        i_se_clr => se_o_clr,
        i_se_iterations => se_o_iterations,
        i_se_iterations_write => se_o_iterations_write,

        i_rx_ready => se_i_rx_ready,
        o_rx_ready => se_o_rx_ready,

        i_dataX => dbe_o_data,
        i_dataW => wbe_o_data,
        o_dataA => se_i_acc
             );
end architecture;
