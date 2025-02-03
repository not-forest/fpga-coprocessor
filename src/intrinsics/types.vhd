-- ============================================================
-- File: types.vhd
-- Desc: Defines all local datatypes and structures used within the coprocessor implementation
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

package intrinsics is
    type t_command_type is  -- Used to parse the current command type between all available ones. 
        (ADD, SUB, MUL, TRAN, CONV);

    type t_Command is record
        ctype : t_command_type;
    end record;

    -- Custom pipelining procedure, to pipeline any type of data for one clock cycle. 
    procedure pipeline (
        signal g_BUS_WIDTH      : in natural;
        signal i_clk            : in std_logic := '0';
        signal i_data           : in std_logic_vector(g_BUS_WIDTH - 1 downto 0);
        signal o_data           : out std_logic_vector(g_BUS_WIDTH - 1 downto 0)
                       );
end package;

package body intrinsics is

    -- Custom pipelining procedure, to pipeline any type of data for one clock cycle. 
    procedure pipeline (
        signal g_BUS_WIDTH      : in natural;
        signal i_clk            : in std_logic := '0';
        signal i_data           : in std_logic_vector(g_BUS_WIDTH - 1 downto 0);
        signal o_data           : out std_logic_vector(g_BUS_WIDTH - 1 downto 0)
    ) is begin
        if falling_edge(i_clk) then
            o_data <= i_data;
        end if;
    end procedure;

end package body;
