-- ============================================================
-- File: pe.vhd
-- Desc: Defines a single representation of a PE (Processing Element) block, used within the systolic
--  array for parallel computations. This unit is runtime configurable, as it is used to perform different
--  operations within a single block based on the upcoming operation.
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
        ni_clr : in std_logic := '1'; -- Clear PE's accumulator (Active low)
        i_clk : in std_logic := '0'; -- Clock signal.
        i_xin : in t_bus; -- Input data from vector X. N-bit width.
        i_yin : in t_bus; -- Input data from vector Y. N-bit width.

        o_xout : out t_bus; -- Pipelined output data X. N-bit width.
        o_yout : out t_bus -- Pipelined output data Y. N-bit width.
    );
end entity;

architecture rtl of pe is
    signal r_weight : t_weight := (others => '0');
begin
    process (i_clk) is
        variable xin : signed(i_xin'range);
        variable yin : signed(i_yin'range);
        variable wi : signed(r_weight'range);
        variable yout : signed(o_yout'range);
    begin
        if falling_edge(i_clk) then
            if ni_clr = '0' then
                r_weight <= (others => '0');
            else
                -- Assignment
                xin := signed(i_xin);
                yin := signed(i_yin);
                wi := signed(r_weight);
                yout := (others => '0');
                -- Execution.
                yout := yin + wi * xin;

                o_yout <= std_logic_vector(yout);
                o_xout <= i_xin;
            end if;
        end if;
    end process;
end architecture;