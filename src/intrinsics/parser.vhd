-- ============================================================
-- File: parser.vhd
-- Desc: Parses upcoming data streams for synchronization, command switching and data multiplexing.
--       Before providing the command, a set of events must be done beforehand:
--       - Master shall be in sync with the internal state machine of the coprocessor, by sending 
--         a synchronization sequence preamble;
--       - Command is provided and stored within the coprocessor's internal registers;
--       - Based on the command, next raw words are treated as weights or data and forwarded to the
--         systolic array for further processing. 
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

entity parser is
    port (
        i_clk : in std_logic := '1';    -- System clock.
        na_clr : in std_logic := '1';   -- Asynchronous clear (Active low).

        io_cmd : inout t_command;       -- Current coprocessor command.

        o_dataX_ready : buffer std_logic;  -- Signal for filling next data word.
        o_dataW_ready : buffer std_logic;  -- Signal for filling next weight word.
        o_new_cmd : out std_logic;         -- Only set for one clock cycles, when new command is parsed. 
        
        i_dataR : in t_word;            -- Raw unparsed input data.
        i_dataR_ready : in std_logic;   -- Flag which informs that new data is ready.
        o_dataR_ready : out std_logic;  -- Flag which informs that parser is ready to read new raw data.

        o_dataX : buffer t_word;        -- Output data.
        o_dataW : buffer t_word         -- Output word.
         );
end entity;

architecture rtl of parser is
    -- Plain synchronization preamble, used before setting a new command.
    constant c_SYNC_PREAMBLE : t_word_array(0 to 3) := (
        x"AAAAAAAA", x"F00DCAFE", x"DEADBEEF", x"10000001"
    );

    signal r_ready : std_logic := '0';
    signal r_parsed : std_logic := '0';     -- Set when a command is properly parsed.
begin
    -- Based on current command, parses upcoming data as either widths or data.
    process (all) is
        -- Simple counter-based 
        variable preamble_counter : natural := 0;
        variable state : t_state := UNKNOWN;
    begin
        if na_clr = '0' then
            state := UNKNOWN;
            r_ready <= '0';
            r_parsed <= '0';
        elsif falling_edge(i_clk) then
            -- Communicating with external FIFO queue.
            if i_dataR_ready = '1' then
                r_ready <= not r_ready;

                if r_ready = '1' then
                    o_dataW_ready <= '0';
                    o_dataX_ready <= '0';

                    -- Behavior differs based on currently used command.
                    case state is
                        -- Trying to synchronize with preamble.
                        when UNKNOWN => 
                            if i_dataR = c_SYNC_PREAMBLE(preamble_counter) then
                                preamble_counter := preamble_counter + 1;
                            else 
                                preamble_counter := 0;
                            end if;

                            if preamble_counter >= c_SYNC_PREAMBLE'length then
                                state := CMDLISTENA;
                            end if;
                        -- Three step command acquiring.
                        when CMDLISTENA => 
                            io_cmd.ctype <= cmd2enum(i_dataR);
                            state := CMDLISTENB;
                        when CMDLISTENB => 
                            io_cmd.n <= i_dataR; 
                            state := CMDLISTENC;
                        when CMDLISTENC => 
                            io_cmd.m <= i_dataR; 
                            r_parsed <= '1';
                            state := DATA;
                        -- Next input word is expected to be width.
                        when DATA => 
                            state := WEIGHT; 
                            o_dataW <= i_dataR;
                            o_dataW_ready <= '1';
                        -- Next input word is expected to be data.
                        when WEIGHT => 
                            state := DATA; 
                            o_dataX <= i_dataR;
                            o_dataX_ready <= '1';
                        when SLEEP => -- Does nothing during sleep.
                                      -- Undefined.
                        when others => state := UNKNOWN;
                    end case;
                end if;
            end if;
        end if;
    end process;

    o_dataR_ready <= r_ready;
    o_new_cmd <= r_parsed;
end architecture;
