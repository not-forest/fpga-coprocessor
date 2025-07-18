-- ============================================================
-- File: pll_tb.vhd
-- Desc: Test bench file for PLL entity. 
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

use coproc.pll;
use coproc.tb.all;
use ieee.std_logic_1164.all;

entity pll_tb is
    -- PLL is expected of generating three stable clock signals of different frequencies.
    type tb_dut is record
        i_clk       : t_clock;
        o_clk0      : std_logic; 
        o_clk1      : std_logic; 
        o_clk2      : std_logic; 
        ni_sleep    : std_logic;
        o_locked    : std_logic;
    end record;
end entity;

architecture behavioral of pll_tb is
    signal sigs : tb_dut := (
        i_clk       => '0',
        o_clk0      => 'X',
        o_clk1      => 'X',
        o_clk2      => 'X',
        ni_sleep    => '1',
        o_locked    => 'X'
    );

    -- Used FPGA includes 50MHz external crystal.
    signal freq : real := 50.000e6;
begin
    -- DUT mapping.
    PLL_Inst : entity pll
    port map (
        i_clk0 => sigs.i_clk,
        ni_sleep => sigs.ni_sleep,
        o_clk0 => sigs.o_clk0,
        o_clk1 => sigs.o_clk1,
        o_clk2 => sigs.o_clk2,
        o_locked => sigs.o_locked
    );

    -- Simulates external oscillator ticks.
    p_EX_CLOCK : tick(sigs.i_clk, freq);

    -- Main testing.
    p_MAIN : process begin
        report "Enter p_MAIN.";

        -- Locked PLL gives properly synchronized clocks.
        wait until sigs.o_locked = '1';
        
        -- Giving it time to produce clock edges.
        wait for 1 us;

        -- PLL clocks stop check.
        sigs.ni_sleep <= '0';
        wait for 1 us;

        -- Resuming PLL action.
        sigs.ni_sleep <= '1';
        wait for 1 us;

        report "Done: p_MAIN";
        stop_clock(freq);
        wait;
    end process;
end architecture;
