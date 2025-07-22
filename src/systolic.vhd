-- ============================================================
-- File: systolic.vhd
-- Desc: Implementation of the systolic array based on PEs (Processing Elements) for parallel
--  computations.
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
use coproc.intrinsics.all;
use coproc.pe;

entity systolic_arr is
    generic (
        g_OMD       : natural   -- Operating matrix dimension. 
    );
    port (
        i_clk   : in std_logic := '0';  -- Clock signal.
        ni_clr  : in std_logic := '1';  -- Global reset. (Active low).

        i_datax : in t_bus;             -- Serial input X.
        i_datay : in t_bus;             -- Serial input Y.
        o_data  : out t_bus             -- Final output data from array.
    );

    type t_systolic_row is array (natural range <>) of t_bus;
    type t_systolic_mat is array (natural range <>) of t_systolic_row;
end entity;

architecture structured of systolic_arr is
    signal w_datax_matrix : t_systolic_mat := (others => (others => (others => '0')));    -- Connection wires between PE elements on X axis.
    signal w_datay_matrix : t_systolic_mat := (others => (others => (others => '0')));    -- Connection wires between PE elements on Y axis. 
begin
    g_SystolicGenI : for i in 1 to g_OMD generate
        g_SystolicGenJ : for j in 1 to g_OMD generate 
            PE_Inst : entity pe
            port map (
                ni_clr => ni_clr,
                i_clk => i_clk,
                i_xin => w_datax_matrix(i)(j),
                i_yin => w_datay_matrix(i)(j),
                o_xout => w_datax_matrix(i)(j + 1),
                o_yout => w_datay_matrix(i + 1)(j)
            );
        end generate;
    end generate;
end architecture;

