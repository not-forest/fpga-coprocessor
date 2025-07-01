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
    constant c_WIDTH : natural := 8;
    -- Test PE block is a 8-bit MAD unit.
    -- Expected behavior:
    -- - perform the following mathematical operation: Yout = Yout + Yin + Wi * Xin;
    -- - Forward the X input synthed with Y input: Xout = Xin;
    -- - Clear when 'ni_clr' is set LOW;
    type tb_dut is record
        ni_clr : std_logic;
        i_clk : t_clock;
        i_xin : t_bus;
        i_yin : t_bus;
        o_xout : t_bus;
        o_yout : t_bus;
    end record;
end entity;

architecture behavioral of pe_tb is
    signal sigs : tb_dut := (
        ni_clr => '1',
        i_clk => '0',
        i_xin => (others => '0'),
        i_yin => (others => '0'),
        o_xout => (others => '0'),
        o_yout => (others => '0')
    );

    -- Used to assert the PE element, by providing the Xin, Yin and expected Yout values.
    procedure assert_pe (
        signal s : inout tb_dut;
        constant yin : in integer;
        constant xin : in integer;
        constant yout : in integer
    ) is begin
        assert sigs.ni_clr = '1'
        report "Unexpected procedure usage. The procedure is expected to be used with non-cleared PE"
            severity error;

        s.i_xin <= t_bus(to_signed(xin, sigs.i_xin'length));
        s.i_yin <= t_bus(to_signed(yin, sigs.i_yin'length));

        wait until falling_edge(sigs.i_clk);
        assert sigs.o_xout = sigs.i_xin
        report "Implementation error. Expected Xout = Xin = " & integer'image(xin) &
            ", found: " & integer'image(to_integer(signed(sigs.o_xout)))
            severity error;

        assert sigs.o_yout = t_bus(to_signed(yout, sigs.o_yout'length))
        report "Implementation error. Expected Yout = " & integer'image(yout) &
            ", found: " & integer'image(to_integer(signed(sigs.o_yout)))
            severity error;

        report "Passed!";
    end procedure;

    -- Test is performed with 1MHz clock.
    signal freq : real := 1.000e6;
begin
    PE_Inst : entity pe
        port map(
            ni_clr => sigs.ni_clr,
            i_clk => sigs.i_clk,
            i_xin => sigs.i_xin,
            i_yin => sigs.i_yin,
            o_xout => sigs.o_xout,
            o_yout => sigs.o_yout
        );

    -- Simulates input clock.
    p_EX_CLOCK : tick(sigs.i_clk, freq);

    p_MAIN : process begin
        report "Enter p_MAIN.";

        wait for 1 ms;
        assert_pe(sigs, 1, 1, 2);

        report "Done: p_MAIN";
        stop_clock(freq);
        wait;
    end process;
end architecture;