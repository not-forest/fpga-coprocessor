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
    constant PARALLEL_BUS_WIDTH : natural := 8;

    -- The width of the upcoming data.
    subtype t_bus is std_logic_vector(PARALLEL_BUS_WIDTH - 1 downto 0);
    -- Subtype representing PE's weight. All weights are always 8-bit wide.
    subtype t_weight is std_logic_vector(7 downto 0);

    type t_command_type is      -- Used to parse the current command type between all available ones. 
        -- Communication related commands:
        -- INIT (Used to prepare the FPGA coprocessor before sending proper commands.)
        -- ACK  (Used to acknowledge the FPGA's ACK request within the status line)
        -- WAKE (Forces the coprocessor to exit sleep mode.)
        --
        -- Computational commands:
        -- MUL (Performs matrix multiplication. Expects next two bytes to be the size of the expected output matrix.)
        (INIT, ACK, WAKE, MUL);

    type t_status is            -- Used to provide the current status of FPGA for the master microcontroller.
        -- UNDEF (Undefined state of the coprocessor. It can have some trash within and must be reinitialized first.)
        -- SLEEP (Coprocessor is put in low power sleep mode, to not loose cycles for nothing. Must be woke up first.)
        -- IDLE (Waiting for the new command.)
        -- PROC (Performing tasks.)
        -- ACK (Waiting for ACK command.)
        (UNDEF, SLEEP, IDLE, PROC, ACK);

    -- Defines a parallel bus to interface the master microcontroller. 
    type t_ParallelBus is record
        d_in        : std_logic_vector(PARALLEL_BUS_WIDTH - 1 downto 0);
        cmd         : std_logic;
        d_out       : std_logic_vector(PARALLEL_BUS_WIDTH - 1 downto 0);
        c_status    : t_status; 
    end record;

    -- Default initialization values of the parallel bus.
    constant C_PBUS_INIT : t_ParallelBus := (
        d_in => (others => '0'),
        d_out => (others => '0'),
        c_status => UNDEF,
        cmd => '0'
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
