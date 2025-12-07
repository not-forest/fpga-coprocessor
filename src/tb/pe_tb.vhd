-- ============================================================
-- File: pll_tb.vhd
-- Desc: Test bench file for PE entity. This ensures that the PE block is performing
-- proper MAC operation and forwarding the pipelined data in just one cycle.
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
use coproc.pe;

entity pe_tb is
    -- Test PE block is a 8-bit MAD unit.
    -- Expected behavior:
    -- - Perform proper MAC operation and forward all parameters to their corresponding axes.
    -- - Prevent integer arithmetic overflows (saturate).
    type tb_dut is record
        ni_clr : std_logic;
        i_clk : t_clock;
        i_xin : t_word;
        i_win : t_word;
        i_ain : t_word;
        o_xout : t_word;
        o_wout : t_word;
        o_aout : t_word;
    end record;
end entity;

architecture behavioral of pe_tb is
    signal sigs : tb_dut := (
        ni_clr => '1',
        i_clk => '1',
        i_xin => (others => '0'),
        i_win => (others => '0'),
        i_ain => (others => '0'),
        o_xout => (others => '0'),
        o_wout => (others => '0'),
        o_aout => (others => '0')
    );

    -- Used to assert the PE element, by providing the Xin, Win and expected Aout values.
    procedure assert_pe (
        signal o_xin : out t_word;
        signal o_win : out t_word;
        constant xin : in integer;
        constant win : in integer;
        constant aout : in integer
    ) is 
        variable ret : boolean := false;
        variable acc : t_word := (others => '0');
    begin
        assert sigs.ni_clr = '1'
        report "Unexpected procedure usage. The procedure is expected to be used with non-cleared PE"
            severity error;

        o_xin <= t_word(to_signed(xin, sigs.i_xin'length));
        o_win <= t_word(to_signed(win, sigs.i_win'length));
        acc := sigs.o_aout;

        -- Performing one clock cycle.
        wait until falling_edge(sigs.i_clk);
        wait until rising_edge(sigs.i_clk);

        ret := sigs.o_xout = sigs.i_xin; 
        assert ret
        report "Implementation error. Expected Xout = Xin = " & integer'image(xin) &
            ", found: " & integer'image(to_integer(signed(sigs.o_xout)))
            severity error;

        ret := sigs.o_aout = t_word(to_signed(aout, sigs.o_aout'length));
        assert ret
        report "Implementation error. Expected Aout = " & integer'image(aout) &
            ", found: " & integer'image(to_integer(signed(sigs.o_aout)))
            severity error;

        if (ret) then
            report "Passed! " 
                & integer'image(to_integer(signed(acc))) 
                & " + " 
                & integer'image(xin) 
                & " * " 
                & integer'image(win) 
                & " = "
                & integer'image(to_integer(signed(sigs.o_aout))); 
        end if;
    end procedure;

    -- Test is performed with 1MHz clock.
    signal freq : real := 1.000e6;
begin
    PE_Inst : entity pe
        port map(
            ni_clr => sigs.ni_clr,
            i_clk => sigs.i_clk,
            i_xin => sigs.i_xin,
            i_win => sigs.i_win,
            o_xout => sigs.o_xout,
            o_wout => sigs.o_wout,
            o_aout => sigs.o_aout
        );

    -- Simulates input clock.
    p_EX_CLOCK : tick(sigs.i_clk, freq);

    p_MAIN : process begin
        report "Enter p_MAIN.";

        -- Default MAC calculations.
        assert_pe(sigs.i_xin, sigs.i_win, 2, 2, 4);
        assert_pe(sigs.i_xin, sigs.i_win, 1, 4, 8);
        assert_pe(sigs.i_xin, sigs.i_win, 6, 6, 44);
        assert_pe(sigs.i_xin, sigs.i_win, -7, -8, 100);
        assert_pe(sigs.i_xin, sigs.i_win, -1, 100, 0);
        assert_pe(sigs.i_xin, sigs.i_win, 127, 127, 127 * 127);

        report "Done: p_MAIN";
        stop_clock(freq);
        wait;
    end process;
end architecture;
