-- ============================================================
-- File: pe.vhd
-- Desc: Defines a single representation of a PE (Processing Element) block, used within the systolic
--  array for parallel computations. PE units only provide MAC operation and must be used properly to
--  obtain required output of different operations.
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

entity pe is
    port (
        ni_clr : in std_logic := '1';           -- Clear PE's accumulator (Active low)
        i_clk : in std_logic := '1';            -- Clock signal.
        i_en  : in std_logic := '1';            -- Clock enable signal. Stalls the PE when unset.

        i_xin : in t_word;                      -- Input data from vector X. N-bit width.
        i_win : in t_word;                      -- Input data from vector W. N-bit width.

        o_xout : out t_word;                    -- Pipelined output data X. N-bit width.
        o_wout : out t_word;                    -- Pipelined output data W. N-bit width.
        o_aout : out t_acc                      -- Accumulator output for reading.
    );
end entity;

architecture rtl of pe is
    signal r_x, r_w : t_word := (others => '0');
    signal r_a      : t_acc := (others => '0');
begin
    process (all) is
        variable xin : signed(i_xin'range);
        variable win : signed(i_win'range);
        variable acc : signed(o_aout'range);
        variable aout : integer;

        constant MAX_ACC : integer := 2 ** (t_acc'length - 1) - 1;
        constant MIN_ACC : integer := -2 ** (t_acc'length - 1);
    begin
        if falling_edge(i_clk) then
            if ni_clr = '0' then
                r_a <= (others => '0');
            elsif i_en = '1' then
                -- Assignment
                xin := signed(i_xin);
                win := signed(i_win);
                acc := signed(r_a);
                aout := 0;

                -- MAC
                aout := to_integer(acc + resize(xin, t_acc'length) * resize(win, t_acc'length));

                -- Saturating on both sides.
                if aout > MAX_ACC then
                    aout := MAX_ACC;
                elsif aout < MIN_ACC then
                    aout := MIN_ACC;
                end if;

                r_x <= i_xin;                                            -- X inputs forwarded horizontally.
                r_w <= i_win;                                            -- W inputs forwarded vertically.
                r_a <= std_logic_vector(to_signed(aout, t_acc'length));  -- Accumulator output forwarded diagonally.
            end if;
        end if;
    end process;

    o_aout <= r_a;
    o_xout <= r_x;
    o_wout <= r_w;
end architecture;
