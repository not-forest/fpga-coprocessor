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
    generic (
        g_LATENCY_CYCLES : natural := 0             -- Amount of latency cycles before reset.
            );
    port (
        na_clr : in std_logic := '1';               -- Asynchronous clear (Active low).
        i_clr : in std_logic := '0';                -- Synchronous clear.
        i_clk : in std_logic := '1';                -- Clock signal.
        i_en  : in std_logic := '1';                -- Clock enable signal. Stalls the PE when unset.

        i_iterations : in t_word := (others => '0');    -- Iterations amount, before first PE00 will be ready.
        i_iterations_write : std_logic := '0';          -- Iterations amount write enable flag.

        i_xin : in t_word;                          -- Input data from vector X. N-bit width.
        i_win : in t_word;                          -- Input data from vector W. N-bit width.

        o_xout : out t_word;                        -- Pipelined output data X. N-bit width.
        o_wout : out t_word;                        -- Pipelined output data W. N-bit width.
        o_aout : out t_word                         -- Accumulator output for reading.
    );
end entity;

architecture rtl of pe is
    signal r_x, r_w     : t_word := (others => '0');    -- Data and weight forwarding register.
    signal r_a          : t_word := (others => '0');    -- Accumulator register.
    signal r_iterations : t_word := (others => '0');    -- Holds current amount of iterations.
    signal r_itdelay    : natural := 0;                 -- Iterations delay, after which the PE shall be reset.
begin
    process (i_clk, na_clr) is
        variable xin    : signed(t_word'length-1 downto 0);
        variable win    : signed(t_word'length-1 downto 0);
        variable prod   : signed((t_word'length * 2) - 1 downto 0);
        variable sum    : signed((t_word'length * 2) downto 0); -- 33 bits to prevent overflow
        
        -- 16-bit signed numbers limits.
        constant MAX_VAL : signed(t_word'length-1 downto 0) := to_signed(32767, t_word'length);
        constant MIN_VAL : signed(t_word'length-1 downto 0) := to_signed(-32768, t_word'length);
    begin
        if na_clr = '0' then
            r_a <= (others => '0');
            r_x <= (others => '0');
            r_w <= (others => '0');
            r_itdelay <= 0;
        elsif rising_edge(i_clk) then
            if i_clr = '1' then
                r_a <= (others => '0');
                r_x <= (others => '0');
                r_w <= (others => '0');
                r_itdelay <= 0;
            end if;

            -- Writing new amount of iterations when new command appears.
            if i_iterations_write = '1' then
                r_iterations <= i_iterations;
                r_itdelay <= to_integer(unsigned(r_iterations)) + g_LATENCY_CYCLES + 2;
            -- Clearing PEs accumulator on timeout.
            elsif i_en = '1' then

                xin  := signed(i_xin);
                win  := signed(i_win);

                prod := xin * win;
                if r_itdelay = 0 then
                    r_a <= (others => '0');
                    r_itdelay <= to_integer(unsigned(r_iterations)) + g_LATENCY_CYCLES + 2;
                    sum  := resize(prod, sum'length);
                else
                    sum  := resize(signed(r_a), sum'length) + resize(prod, sum'length);
                    r_itdelay <= r_itdelay - 1;
                end if;

                    -- Saturation logic for 16-bit output
                if sum > resize(MAX_VAL, sum'length) then
                    r_a <= std_logic_vector(MAX_VAL);
                elsif sum < resize(MIN_VAL, sum'length) then
                    r_a <= std_logic_vector(MIN_VAL);
                else
                    r_a <= std_logic_vector(resize(sum, t_word'length));
                end if;

                r_x <= i_xin;
                r_w <= i_win;
            end if;
        end if;
    end process;

    o_aout <= r_a;
    o_xout <= r_x;
    o_wout <= r_w;
end architecture;
