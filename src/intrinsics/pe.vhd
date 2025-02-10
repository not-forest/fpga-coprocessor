-- ============================================================
-- File: pe.vhd
-- Desc: Defines a single representation of a PE (Processing Element) block, used within the systolic
--  array for parallel computations.
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
use coproc.intrinsics.pipeline;

entity pe is
    generic (
        g_BUS_WIDTH : natural   -- Width of the PE bus (allows NxN bit operations).
            );
    port (
        ni_clr      : in std_logic := '1';                      -- Clear PE's accumulator (Active low)
        i_clk       : in std_logic := '0';                      -- Clock signal.
        i_xin       : in std_logic_vector(g_BUS_WIDTH - 1 downto 0);    -- Input data from vector X. N-bit width.
        i_yin       : in std_logic_vector(g_BUS_WIDTH - 1 downto 0);   -- Input data from vector Y. N-bit width.
        o_xout      : out std_logic_vector(g_BUS_WIDTH - 1 downto 0);   -- Pipelined output data X. N-bit width.
        o_yout      : buffer std_logic_vector(g_BUS_WIDTH - 1 downto 0)  -- Pipelined output data Y. N-bit width.
         );
end entity;

architecture rtl of pe is
    signal w_ypipein : std_logic_vector(g_BUS_WIDTH - 1 downto 0) := (others => '0');     -- Multiplication pipeline wire.
    signal w_xpipein : std_logic_vector(g_BUS_WIDTH - 1 downto 0) := (others => '0');     -- Forward pipeline wire.
    signal w_ypipeout : std_logic_vector(g_BUS_WIDTH - 1 downto 0) := (others => '0');
    signal w_xpipeout : std_logic_vector(g_BUS_WIDTH - 1 downto 0) := (others => '0');
begin
    process (i_clk) is
        variable xin : unsigned(i_xin'range) := (others => '0');
        variable yin : unsigned(i_yin'range) := (others => '0');
        variable xout : unsigned(o_xout'range) := (others => '0');
        variable yout : unsigned(2*g_BUS_WIDTH-1 downto 0) := (others => '0');  -- Double width for multiplication result
    begin
        xin := unsigned(i_xin);
        yin := unsigned(i_yin);  -- Corrected assignment

        if ni_clr = '0' then
            w_ypipein <= (others => '0');
            w_xpipein <= (others => '0');
        elsif falling_edge(i_clk) then
            xout := xin;
            yout := xin * yin;  -- Perform multiplication
            w_ypipein <= std_logic_vector(yout(g_BUS_WIDTH-1 downto 0) + unsigned(o_yout));
            w_xpipein <= std_logic_vector(xout);  -- Convert unsigned back to std_logic_vector
        end if;
    end process;

    -- Pipeline processes
    pipeline(i_clk, w_xpipein, w_xpipeout);
    pipeline(i_clk, w_ypipein, w_ypipeout);

    o_xout <= w_xpipeout;
    o_yout <= w_ypipeout;
end architecture;

