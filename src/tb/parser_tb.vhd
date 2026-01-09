-- ============================================================
-- File: parser_tb.vhd
-- Desc: Parses upcoming data streams for synchronization, command switching and data multiplexing.
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
use coproc.tb.all;

use coproc.parser;

entity parser_tb is
    -- DUT for parser module.
    type tb_dut is record
        i_clk : std_logic; 
        na_clr : std_logic;

        io_cmd : t_command;    

        o_data_ready : std_logic;
        
        i_dataR : t_word;          
        i_dataR_ready : std_logic; 
        o_dataR_ready : std_logic;

        o_dataX : t_word;
        o_dataW : t_word; 
    end record;
end entity;

architecture behavioral of parser_tb is
    signal sigs : tb_dut := (
        i_clk  => '1', 
        na_clr => '1',
        io_cmd => (
            ctype => UNDEFINED,
            n => (others => '0'),
            m => (others => '0')
        ),    
        o_data_ready => '0',
        i_dataR => (others => '0'),          
        i_dataR_ready => '0', 
        o_dataR_ready => '0',
        o_dataX => (others => '0'),
        o_dataW => (others => '0') 
    );

    -- Test is performed with 100MHz clock.
    signal freq : real := 100.000e6;
begin
    -- Parser instance.
    PARSER_Inst : entity parser
    port map (
        i_clk  => sigs.i_clk, 
        na_clr => sigs.na_clr,
        io_cmd => sigs.io_cmd,    
        o_data_ready => sigs.o_data_ready,
        i_dataR => sigs.i_dataR,          
        i_dataR_ready => sigs.i_dataR_ready, 
        o_dataR_ready => sigs.o_dataR_ready,
        o_dataX => sigs.o_dataX,
        o_dataW => sigs.o_dataW 
             );

    -- Simulates input clock.
    p_EX_CLOCK : tick(sigs.i_clk, freq);

    p_MAIN : process is 
        constant c_SPI_UPCOMING_WORDS : t_word_array := (
            -- Synchronizing SHA256 sequence.
            x"AAAA", 
            x"F00D", 
            x"DEAD", 
            x"BEEF",
            -- Command write (Matrix multiplication, Dimensions: 200x100).
            c_MATRIX_MULT_VAL, w(200), w(100)
        );
    begin
        report "Enter p_MAIN.";

        wait for 15 ns;

        -- Assuming that data will always be ready since stable FIFO queue.
        sigs.i_dataR_ready <= '1';

        -- Simulating FIFO that sends new raw data words.
        for i in 0 to c_SPI_UPCOMING_WORDS'length - 1 loop
            wait until sigs.o_dataR_ready = '1';
            sigs.i_dataR <= c_SPI_UPCOMING_WORDS(i);
        end loop;

        wait until falling_edge(sigs.i_clk);
        wait until falling_edge(sigs.i_clk);

        assert sigs.io_cmd.ctype = cmd2enum(c_MATRIX_MULT_VAL) 
            report "Wrong command parsed. Expected: " & to_hstring(c_MATRIX_MULT_VAL) & ", got: " & to_hstring(enum2cmd(sigs.io_cmd.ctype)) 
            severity error;
        assert sigs.io_cmd.n = w(200) 
            report "Wrong N parsed. Expected: " & to_hstring(w(200)) & ", got: " & to_hstring(sigs.io_cmd.n) 
            severity error;
        assert sigs.io_cmd.m = w(99) 
            report "Wrong M parsed. Expected: " & to_hstring(w(100))  & ", got: " & to_hstring(sigs.io_cmd.M)
            severity error; 

        report "Done: p_MAIN";
        stop_clock(freq);
        wait;
    end process;
end architecture;
