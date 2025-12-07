-- ============================================================
-- File: pe_fifo_tb.vhd
-- Desc: Regular FIFO queue used to feed rows and columns of systolic array.
-- Warn: Vendor specific content ahead. This file is compatible with Quartus Prime software.
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
use ieee.numeric_std.all;
use coproc.intrinsics.all;
use coproc.tb.all;
use coproc.pe_fifo;

entity pe_fifo_tb is
    type tb_dut is record
        na_clr          : std_logic;
        i_clk           : std_logic;

        i_data          : t_word;
        o_data          : t_word;

        i_tx_ready      : std_logic;
        i_rx_ready      : std_logic;
        o_tx_ready      : std_logic;
        o_rx_ready      : std_logic;
    end record;
end entity;

architecture behavioral of pe_fifo_tb is
    signal sigs : tb_dut := (
        na_clr       => '1',
        i_clk        => '1',

        i_data       => (others => '0'),
        o_data       => (others => '0'),

        i_tx_ready   => '0',
        i_rx_ready   => '0',
        o_tx_ready   => '0',
        o_rx_ready   => '0'
    );

    signal freq : real := 100.000e6;
begin
    PE_FIFO_Inst : entity pe_fifo
    generic map (
        g_BLOCK_SIZE => 16
    )
    port map (
        na_clr => sigs.na_clr,
        i_clk => sigs.i_clk,
        i_data => sigs.i_data,
        o_data => sigs.o_data,
        i_tx_ready => sigs.i_tx_ready,
        i_rx_ready => sigs.i_rx_ready,
        o_tx_ready => sigs.o_tx_ready,
        o_rx_ready => sigs.o_rx_ready
    );

    -- Simulates input clocks from both sides.
    p_EX_CLOCK : tick(sigs.i_clk, freq);

    -- Main producer thread.
    p_MAIN_PROD : process is
        variable counter : natural := 0;
    begin
        report "Enter p_MAIN_PROD.";
        wait for 10 ns;

        for i in 0 to 10 loop
            if sigs.o_tx_ready /= '1' then
                wait until sigs.o_tx_ready;
                wait until rising_edge(sigs.i_clk);
            end if;

            counter := counter + 1;
            sigs.i_data <= t_word(to_signed(counter, t_word'length));
            sigs.i_tx_ready <= '0';

            report "Written: " & integer'image(counter);
            
            wait until rising_edge(sigs.i_clk);
            sigs.i_tx_ready <= '1';
            wait until rising_edge(sigs.i_clk);
        end loop;
        sigs.i_tx_ready <= '0';

        report "Done: p_MAIN_PROD";
        wait;
    end process;

    -- Main consumer thread.
    p_MAIN_CONS : process begin
        report "Enter p_MAIN_CONS.";
        wait for 25 ns;

        for i in 0 to 10 loop
            if sigs.o_rx_ready /= '1' then
                wait until sigs.o_rx_ready;
                wait until rising_edge(sigs.i_clk);
            end if;
   
            sigs.i_rx_ready <= '1';
            wait until rising_edge(sigs.i_clk);
            report "Read: " & integer'image(to_integer(signed(sigs.o_data)));
            sigs.i_rx_ready <= '0';
            wait until rising_edge(sigs.i_clk);
        end loop;

        report "Done: p_MAIN_CONS";
        stop_clock(freq);
        wait;
    end process;
end architecture;
