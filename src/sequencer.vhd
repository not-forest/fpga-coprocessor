-- ============================================================
-- File: sequencer.vhd
-- Desc: Primary block for obtaining and reshaping input data for feeeding it to the systolic array afterwards.
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
use coproc.intrinsics.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sequencer is
    port (
        i_sclk          : in std_logic := '1';      -- SPI domain clock.
        i_clk           : in std_logic := '1';      -- System clock.
        ni_ss           : in std_logic := '1';      -- SPI SS line.
        na_clr          : in std_logic := '1';      -- Asynchronous clear (Active Low).

        io_cmd : inout t_command;                   -- Coprocessor command bus.

        o_dataW : out t_word;                       -- Output parsed word for serial weight.
        o_dataX : out t_word;                       -- Output parsed word for serial data.
        o_shift_ready : buffer std_logic := '0';    -- Activates data shifters.
        o_new_cmd : out std_logic := '0';           -- Set when new command is properly parsed.

        o_read_ready    : out std_logic;            -- Read ready flag from SPI slave inteface. 
        i_read_ready    : in std_logic;             -- Read ready flag from inner fifo (not full).
        i_read          : in t_spi_word             -- Input SPI word.
         );
end entity;

architecture structured of sequencer is
    signal w_parser_raw_data    : t_word := (others => '0');    -- Raw data forwarded from sequencer FIFO for further parsing.
    signal w_parser_i_rx_ready  : std_logic := '0';             -- Ready flag from parser.
    signal w_parser_o_rx_ready  : std_logic := '0';             -- Ready flag to parser.
begin
    -- FIFO holds several SPI words for synchronization.
    --
    -- Coprocessor works in slave mode in the SPI network, therefore has zero control
    -- over SCLK line. Domain FIFO allows to obtain SPI data, separating two clock
    -- domains. Data is also buffered into 32-bit words. This mandates 4-byte alignment
    -- for SPI transfer from the master side.
    DOMAIN_FIFO_Inst : entity coproc.domain_fifo
    generic map (
        g_LENGTH => 64,
        g_INPUT_DATA_SIZE => t_spi_word'length,
        g_OUTPUT_DATA_SIZE => t_word'length,
        g_INPUT_DELTA_SLACK => FALSE
                )
    port map (
        ni_clr => na_clr,
        i_clk_producer => i_sclk,
        i_clk_consumer => i_clk,
        i_tx => i_read,
        o_rx => w_parser_raw_data,
        i_tx_ready => i_read_ready,
        o_tx_ready => o_read_ready,
        i_rx_ready => w_parser_i_rx_ready,
        o_rx_ready => w_parser_o_rx_ready 
             );

    -- Parser is responsible to synchronize transfer between master and slave (coprocessor)
    -- and store new command for further processing.
    PARSER_Inst : entity coproc.parser
    port map (
        i_clk  => i_clk, 
        na_clr => na_clr,
        i_clr => ni_ss,
        io_cmd => io_cmd,    
        o_data_ready => o_shift_ready,
        i_dataR => w_parser_raw_data,          
        i_dataR_ready => w_parser_o_rx_ready, 
        o_dataR_ready => w_parser_i_rx_ready,
        o_new_cmd => o_new_cmd,
        o_dataX => o_dataX,
        o_dataW => o_dataW 
             );
end architecture;
