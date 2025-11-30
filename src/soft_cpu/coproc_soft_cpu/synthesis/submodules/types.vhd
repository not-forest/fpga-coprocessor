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

    -- Subtype for NIOS V soft CPU word.
    subtype t_niosv_word is std_logic_vector(31 downto 0);
    -- Words of data moving within the system atomically.
    subtype t_word is std_logic_vector(WORD_LENGTH - 1 downto 0);
    -- Accumulated value forwarded within the systolic array structure. 
    subtype t_acc is std_logic_vector(23 downto 0);

    -- Resizable array of coprocessor words.
    type t_word_array is array (natural range <>) of t_word;
    -- Resizable array of coprocessor accumulators.
    type t_acc_array is array (natural range <>) of t_acc;
    -- Matrix of accumulators from PE elements.
    type t_acc_mat is array (natural range <>, natural range <>) of t_acc;

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

    -- Helper function to retrieve log2 of natural value for generics.
    function log2(n : natural) return natural;

    -- Custom procedure to ensure timing constrains for FIFO interfaces.
    -- 
    -- Both read and write requests must be asserted for one clock cycle only. This procedure ensures,
    -- that both producer and consumer can hold their READY lines high as long as they won't, because it
    -- will only fire one request per rising edge.
    procedure delta_ready (
        signal ni_clr       : in std_logic;     -- Synchronous clear (Active low).
        signal i_clk        : in std_logic;     -- Input clock from the required domain.
        signal i_condition  : in std_logic;     -- Condition, under which the request will be asserted together with the request.
        signal i_ready      : in std_logic;     -- Ready request from the domain side.
        signal io_dt        : inout std_logic;  -- Delta logic semaphore to clock requests only for one clock cycle.
        signal o_req        : out std_logic     -- Wire to FIFO's request inputs.
    );

    -- Custom pipelining procedure, to pipeline any type of data for one clock cycle. 
    procedure pipeline (
        signal i_clk            : in std_logic;
        signal i_data           : in std_logic_vector;
        signal o_data           : out std_logic_vector
                       );
end package;

package body intrinsics is
    function log2(n : natural) return natural is
        variable x : natural := 0;
        variable y : natural := n - 1;
    begin
        while y > 0 loop
            y := y / 2;
            x := x + 1;
        end loop;
        return x;
    end function;

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

    -- Custom procedure to ensure timing constrains for FIFO interfaces.
    -- 
    -- Both read and write requests must be asserted for one clock cycle only. This procedure ensures,
    -- that both producer and consumer can hold their READY lines high as long as they won't, because it
    -- will only fire one request per rising edge.
    procedure delta_ready (
        signal ni_clr       : in std_logic;     -- Synchronous clear (Active low).
        signal i_clk        : in std_logic;     -- Input clock from the required domain.
        signal i_condition  : in std_logic;     -- Condition, under which the request will be asserted together with the request.
        signal i_ready      : in std_logic;     -- Ready request from the domain side.
        signal io_dt        : inout std_logic;  -- Delta logic semaphore to clock requests only for one clock cycle.
        signal o_req        : out std_logic     -- Wire to FIFO's request inputs.
    ) is begin
        if falling_edge(i_clk) then
            -- On each TX ready signal, putting the write request for one clock cycle.
            if ni_clr = '0' then
                o_req <= '0';
                io_dt <= '0';
            else
                o_req <= (i_ready and i_condition and not io_dt);
                io_dt <= i_ready;
            end if;
        end if;
    end procedure;
end package body;
