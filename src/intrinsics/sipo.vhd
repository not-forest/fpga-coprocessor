-- ============================================================
-- File: sipo.vhd
-- Desc: Word shifting memory block for systolic array inputs. Shifts upcoming word of data and flushes the entire
--      previous batch on each clock cycle simultaneously. Internally acts as a SIPO block of N registers.
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

entity word_shifter is
    generic (
        g_LENGTH : natural      -- Describes how many words can be held in this shifter.
            );
    port (
        na_clr  : in std_logic := '1';                                      -- Asynchronous clear (Active low).
        i_clk   : in std_logic := '1';                                      -- Clock input. Shifts and pushes elements at the same time.
        i_write : in std_logic := '1';                                      -- Starts writing procedure.
        i_batch_length : std_logic_vector(log2(g_LENGTH) - 1 downto 0);    --
        i_data  : in t_word;                -- Data input. One value at a time.
        o_full  : out std_logic;            -- Sets when batch if fully filled with words.
        o_batch : out t_word_array(0 to g_LENGTH - 1)   -- Batch output. Data from each register is always seen.
    );
end entity;

library altera_mf;
use altera_mf.all;

architecture rtl of word_shifter is
    signal r_batch_mat : t_word_array(0 to g_LENGTH - 1) := (others => (others => '0'));

    signal r_cnt       : natural range 0 to g_LENGTH := 0;
    signal r_full      : std_logic := '0';
begin
    -- Shifting process.
    process(i_clk) begin
        if na_clr = '0' then
            r_batch_mat <= (others => (others => '0'));
            r_cnt       <= 0;
            r_full      <= '0';
        elsif rising_edge(i_clk) then
            if i_write = '1' then
                r_batch_mat(0) <= i_data;
                for i in 1 to to_integer(unsigned(i_batch_length)) loop
                    r_batch_mat(i) <= r_batch_mat(i-1);
                end loop;

                if r_cnt >= to_integer(unsigned(i_batch_length)) then
                    r_cnt  <= 0;
                    r_full <= '1';
                else
                    r_cnt  <= r_cnt + 1;
                    r_full <= '0';
                end if;
            else
                r_full <= '0';
            end if;
        end if;
    end process;

    o_batch <= r_batch_mat;
    o_full  <= r_full;
end architecture;
