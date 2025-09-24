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
    constant WORD_LENGTH : natural := 8;
    constant SPI_WORD_LENGTH : natural := 8;

    -- Words of data moving within the system atomically.
    subtype t_word is std_logic_vector(WORD_LENGTH - 1 downto 0);
    -- Words of data on SPI bus.
    subtype t_bus is std_logic_vector(SPI_WORD_LENGTH - 1 downto 0);
    -- Subtype representing PE's weight. All weights are always 8-bit wide.
    subtype t_weight is std_logic_vector(7 downto 0);

    -- Enum state that each PE holds.
    --
    -- It provides information to the PE about which operation it shall perform with the
    -- currently obtained data and where the data flow shall continue on going. 
    type t_pe_command is (
        -- When PE elements holds this command, it will be cleared on the next clock cycle.
        CLEAR, 
        -- Next data coming from X data bus shall be loaded into internal weight register.
        WEIGHT,
        -- Next obtained values shall be added together.
        ADD
    );

    -- Custom pipelining procedure, to pipeline any type of data for one clock cycle. 
    procedure pipeline (
        signal i_clk            : in std_logic;
        signal i_data           : in std_logic_vector;
        signal o_data           : out std_logic_vector
                       );
end package;

package body intrinsics is

    -- Custom pipelining procedure, to pipeline any type of data for one clock cycle. 
    procedure pipeline (
        signal i_clk            : in std_logic;
        signal i_data           : in std_logic_vector;
        signal o_data           : out std_logic_vector
    ) is begin
        if falling_edge(i_clk) then
            o_data <= i_data;
        end if;
    end procedure;
end package body;
