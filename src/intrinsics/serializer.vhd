-- ============================================================
-- File: serializer.vhd
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
use coproc.intrinsics.all;

entity serializer is
    generic (
        g_OMD : natural             -- Operating matrix dimensions.
    );
    port (
        i_clk   : in std_logic := '1';                      -- Input clock source.
        na_clr  : in std_logic := '1';                      -- Asynchronous clear (Active Low).
        
        i_accs  : in t_acc_mat(0 to g_OMD - 1, 0 to g_OMD - 1);     -- Input matrix of PE's accumulators.
        i_read  : in std_logic := '0';                      -- Starts reading procedure when set.
        i_clr   : in std_logic := '0';                      -- Synchronous clear. Clears the state machine.
        o_acc   : out t_acc                                 -- Output word.
    );
end entity;

architecture rtl of serializer is
    type t_direction is (UR, DL);
    signal r_dir : t_direction := UR;
    signal r_i, r_j : natural := 0; 

begin
    process (all) is 
        -- Resets the state machine after last element and dirung asynchronous/synchronous resets.
        procedure serializer_reset is begin
            r_dir <= UR;
            r_i <= 0;
            r_j <= 0;
        end procedure;
    begin
        if na_clr = '0' then
            serializer_reset;
        elsif falling_edge(i_clk) then
            if i_clr = '1' then
                serializer_reset;
            else
                if i_read = '1' then
                    if r_dir = UR then
                        if r_j = g_OMD - 1 then
                            r_i <= r_i + 1;
                            r_dir <= DL;
                        elsif r_i = 0 then
                            r_j <= r_j + 1;
                            r_dir <= DL;
                        else
                            r_i <= r_i - 1;
                            r_j <= r_j + 1;
                        end if;
                    else
                        if r_i = g_OMD - 1 then
                            r_j <= r_j + 1;
                            r_dir <= UR;
                        elsif r_j = 0 then
                            r_i <= r_i + 1;
                            r_dir <= UR;
                        else
                            r_i <= r_i + 1;
                            r_j <= r_j - 1;
                        end if;
                    end if;

                    -- Reset when finished.
                    if r_i = g_OMD - 1 and r_j = g_OMD - 1 then
                        serializer_reset; 
                    end if;
                end if;
            end if;
        end if;
    end process;

    o_acc <= i_accs(r_i, r_j);
end architecture;
