-- ============================================================
-- File: serializer_tb.vhd
-- Desc: Allows to read accumulator values from the systolic array by providing required
--  id value. RTL of this component is basically a multiplexer for matrix of accumulators, where
--  higher id's provides next value in zigzag matter, corresponding to the way how PEs are filled
--  within the systolic array.
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
use coproc.tb.all;
use coproc.intrinsics.all;
use coproc.serializer;

entity serializer_tb is
    type tb_dut is record
        i_clk   : std_logic;                 
        na_clr  : std_logic;                 
        
        i_accs  : t_word_mat(0 to 2, 0 to 2);
        i_se_iterations : t_word;
        i_se_iterations_write : std_logic;
        i_batch_sampled : std_logic;
        i_rx_ready : std_logic;
        o_rx_ready : std_logic;
        i_clr   : std_logic;                 
        o_acc  : t_word;
    end record;
end entity;

architecture behavioral of serializer_tb is
    -- Assertion procedure.
    procedure assert_output (
        constant expected : in t_word;
        constant actual   : in t_word;
        constant msg      : in string := "Mismatch in serializer output."
    ) is
        variable ret : boolean := false;
    begin
        ret := actual = expected;

        if ret then
            report "Passed: " & to_hstring(expected) & " = " & to_hstring(actual);
        end if;

        assert ret
        report msg & " Expected: " & to_hstring(expected) & " Got: " & to_hstring(actual)
        severity error;
    end procedure;

    -- Virtual PE's output.
    constant c_VIRTUAL_PE_MATRIX : t_word_mat(0 to 2, 0 to 2) := (
        (x"000001", x"000002", x"000003"),
        (x"000004", x"000005", x"000006"),
        (x"000007", x"000008", x"000009")
    );
    type t_word_array is array (natural range 0 to 8) of t_word;
    -- Expected sequence from serializer.
    constant c_EXPECTED_ARRAY : t_word_array := 
        (x"000001", x"000002", x"000004", x"000007", x"000005", x"000003", x"000006", x"000008", x"000009"); 

    signal sigs : tb_dut := (
        i_clk  => '0',                 
        na_clr => '1',                 
        i_accs => (others => (others => (others => '0'))),
        i_se_iterations => (others => '0'),
        i_se_iterations_write => '0',
        i_batch_sampled => '0',
        i_rx_ready => '0',
        o_rx_ready => '0',
        i_clr  => '0',                 
        o_acc => (others => '0')
    );

    -- Test is performed with 1MHz clock.
    signal freq : real := 1.000e6;
begin
    SERIALIZER_Inst : entity serializer 
    generic map (
        g_OMD => 3
                )
    port map (
        i_clk  => sigs.i_clk,                 
        na_clr => sigs.na_clr,                 
        i_accs => sigs.i_accs,

        i_iterations => sigs.i_se_iterations,
        i_iterations_write => sigs.i_se_iterations_write,
        i_batch_sampled => sigs.i_batch_sampled,
        i_rx_ready => sigs.i_rx_ready,
        o_rx_ready => sigs.o_rx_ready,

        i_clr  => sigs.i_clr,                 
        o_acc => sigs.o_acc
             );

    -- Connecting to our dummy matrix.
    g_CONNI_MATRIX : for i in 0 to 2 generate
        g_CONNJ_MATRIX : for j in 0 to 2 generate
            sigs.i_accs(i, j) <= c_VIRTUAL_PE_MATRIX(i, j);
        end generate;
    end generate;

    -- Simulates input clock.
    p_EX_CLOCK : tick(sigs.i_clk, freq);

    -- Side task for systolic array.
    p_SYST : process begin 
        report "Enter p_SYST.";
        wait for 15 ns;

        sigs.i_se_iterations <= x"00000003";    -- Preparing iteration value beforehand.
        sigs.i_se_iterations_write <= '1';
        wait until falling_edge(sigs.i_clk);

        for i in 0 to 3 loop
            wait until falling_edge(sigs.i_clk);
            sigs.i_batch_sampled <= '1';
            wait until falling_edge(sigs.i_clk);
            sigs.i_batch_sampled <= '0';
        end loop;

        report "Done: p_SYST";
        wait;
    end process;

    -- Simulation main.
    p_MAIN : process begin
        report "Enter p_MAIN.";

        for i in 0 to 8 loop
            if sigs.o_rx_ready /= '1' then
                wait until sigs.o_rx_ready = '1';
                wait until falling_edge(sigs.i_clk);
            end if;

            sigs.i_rx_ready <= '1';
            wait until falling_edge(sigs.i_clk);
            assert_output(c_EXPECTED_ARRAY(i), sigs.o_acc, "Output error. Wrong expected value.");
            sigs.i_rx_ready <= '0';
            wait until falling_edge(sigs.i_clk);
        end loop;

        report "Done: p_MAIN";
        stop_clock(freq);
        wait;
    end process;
end architecture;
