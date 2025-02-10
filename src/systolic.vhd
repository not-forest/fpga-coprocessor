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
use coproc.pe;

entity systolic_arr is
    generic (
        g_BUS_WIDTH : natural;  -- Width of PE buses.
        g_OMD       : natural   -- Operating matrix dimension. 
    );
    port (
        i_clk   : in std_logic := '0';                              -- Clock signal.
        i_datax : in std_logic_vector(g_BUS_WIDTH - 1 downto 0);    -- Input X data value.
        i_datay : in std_logic_vector(g_BUS_WIDTH - 1 downto 0);    -- Input Y data value.
        o_data  : out std_logic_vector(g_BUS_WIDTH - 1 downto 0)    -- Final output data from array.
    );
end entity;

architecture structured of systolic_arr is
    type t_src_array is array (1 to g_OMD) of std_logic_vector(g_BUS_WIDTH - 1 downto 0); 
    type t_conwires is array (0 to g_OMD, 0 to g_OMD) of std_logic_vector(g_BUS_WIDTH - 1 downto 0);

    signal r_vecx : t_src_array;  -- Shifted source vector X.
    signal r_vecy : t_src_array;  -- Shifted source vector Y.
    signal r_veco : t_src_array;  -- Output data vector.

    signal w_vecc_x : t_conwires;  -- Connection wires for X data between PEs.
    signal w_vecc_y : t_conwires;  -- Connection wires for Y data between PEs.
begin
    PE_Inst : entity coproc.pe
    generic map (
        g_BUS_WIDTH => g_BUS_WIDTH
                )
    port map (
        ni_clr => '1',
        i_clk  => i_clk, 
        i_xin  => r_vecx(1),         
        o_xout => w_vecc_x(1, 1),   
        i_yin  => r_vecy(1),
        o_yout => w_vecc_y(1, 1)     
             );

    PE_JF : for j in 2 to g_OMD generate
        PE_Inst : entity coproc.pe
        generic map (
            g_BUS_WIDTH => g_BUS_WIDTH
                    )
        port map (
            ni_clr => '1',
            i_clk  => i_clk, 
            i_xin  => r_vecx(j),         
            o_xout => w_vecc_x(1, j),   
            i_yin  => w_vecc_y(1, j - 1),
            o_yout => w_vecc_y(1, j)     
                 );
    end generate;

    PE_IF : for i in 2 to g_OMD generate
        PE_Inst : entity coproc.pe
        generic map (
            g_BUS_WIDTH => g_BUS_WIDTH
                    )
        port map (
            ni_clr => '1',
            i_clk  => i_clk, 
            i_xin  => w_vecc_x(i - 1, 1),
            o_xout => w_vecc_x(i, 1),
            i_yin  => r_vecy(i),         
            o_yout => w_vecc_y(i, 1)     
                 );
    end generate;

    -- Generates g_OMD² systolic array processing elements (PEs) -- 
    PE_I: for i in 2 to g_OMD - 1 generate
        PE_J: for j in 2 to g_OMD - 1 generate
            PE_Inst : entity coproc.pe
                generic map (
                    g_BUS_WIDTH => g_BUS_WIDTH
                )
                port map (
                    ni_clr => '1',
                    i_clk  => i_clk, 
                    i_xin  => w_vecc_x(i - 1, j),            -- First row gets input
                    o_xout => w_vecc_x(i, j),   -- Pass data to the next row. Last output data lines are leaked open.
                    i_yin  => w_vecc_y(i, j - 1),            -- First column gets input
                    o_yout => w_vecc_y(i, j)            -- Pass data to the next column
                );
        end generate;
    end generate;


end architecture;

