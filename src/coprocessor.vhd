-- ============================================================
-- File: coprocessor.vhd
-- Desc: Top level entity of the FPGA Coprocessor implementation. Coprocessor allows to handle a parallel inputs of
--  N-bit values, defined by g_BUS_WIDTH generic, which are shifted to the systolic array for further computations.
--  The selected operation is defined by the first entry word, which also define the size of matrixes and it's type.
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

use coproc.intrinsics.all;
use ieee.std_logic_1164.all;

entity coprocessor is
    generic (
        g_BUS_WIDTH : natural                                                           -- Width of the co-processor's data bus.
            );
    port (
        i_clk   : in std_logic := '0';                                                  -- External FPGA clock.
        i_data  : in std_logic_vector(g_BUS_WIDTH - 1 downto 0) := (others => '0');     -- Data in from Raspberry Pi.
        o_data  : out std_logic_vector(g_BUS_WIDTH - 1 downto 0) := (others => '0')     -- Data out to Raspberry Pi.
         );
end entity;

architecture structured of coprocessor is
begin
end architecture;
