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
use ieee.std_logic_arith.all;
use coproc.intrinsics.pipeline;

entity pe is
    generic (
        g_BUS_WIDTH : natural   -- Width of the PE bus (allows NxN bit operations).
            );
    port (
        ni_clr      : in std_logic := '1';                      -- Clear PE's accumulator (Active low) 
        i_clk       : in std_logic := '0';                      -- Clock signal.
        i_datax     : in unsigned(g_BUS_WIDTH - 1 downto 0);    -- Input data from vector X
        i_datay     : in unsigned(g_BUS_WIDTH - 1 downto 0);    -- Input data from vector Y
        o_data      : out unsigned(g_BUS_WIDTH - 1 downto 0)    -- Pipelined output data.
         );
end entity;

architecture rtl of pe is
    signal n_psize : natural := g_BUS_WIDTH;
    signal r_mac : std_logic_vector(g_BUS_WIDTH - 1 downto 0) := (others => '0');       -- MAC result.
    signal w_mpipe : std_logic_vector(g_BUS_WIDTH - 1 downto 0) := (others => '0');     -- Multiplication pipeline wire. 
begin
    process (all) is
        variable x : unsigned(i_datax'range)  := (others => '0');
        variable y : unsigned(i_datay'range)  := (others => '0');
        variable o : unsigned(o_data'range)   := (others => '0');
    begin
        x := i_datax;
        y := i_datay;

        if ni_clr = '0' then
            r_mac <= (others => '0');
        elsif falling_edge(i_clk) then
            o := x * y;
            w_mpipe <= std_logic_vector(o);
        end if;
    end process;

    pipeline(n_psize, i_clk, w_mpipe, r_mac);

    o_data <= o_data + unsigned(r_mac); 
end architecture;
