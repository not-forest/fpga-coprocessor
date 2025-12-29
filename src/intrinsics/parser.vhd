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
        i_clr : in std_logic := '0';    -- Synchronous clear.

        io_cmd : inout t_command;       -- Current coprocessor command.

        o_new_cmd : out std_logic;         -- Only set for one clock cycles, when new command is parsed. 
        
        i_dataR : in t_word;            -- Raw unparsed input data.
        i_dataR_ready : in std_logic;   -- Flag which informs that new data is ready.
        o_dataR_ready : out std_logic;  -- Flag which informs that parser is ready to read new raw data.

        o_dataX : buffer t_word;        -- Output data.
        o_dataW : buffer t_word;        -- Output word.
        o_data_ready : buffer std_logic -- Signal when data is ready to be sent for word shifters.
         );
end entity;

architecture rtl of parser is
    -- Plain synchronization preamble, used before setting a new command.
    constant c_SYNC_PREAMBLE : t_word_array(0 to 3) := (
        x"AAAA", x"F00D", x"DEAD", x"BEEF"
    );

    signal r_ready : std_logic := '0';
    signal r_parsed : std_logic := '0';     -- Set when a command is properly parsed.
begin
    -- Based on current command, parses upcoming data as either widths or data.
    process (all) is
        -- Simple counter-based 
        variable preamble_counter : natural := 0;   -- Counter for preamble synchronization sequence.
        variable state : t_state := UNKNOWN;        -- Internal state machine.
    begin
        if na_clr = '0' then
            state := UNKNOWN;
            io_cmd <= c_UDEFCMD;
            r_ready <= '0';
            r_parsed <= '0';
        elsif falling_edge(i_clk) then
            o_data_ready <= '0';

            if i_clr = '1' then
                state := UNKNOWN;
                io_cmd <= c_UDEFCMD;
                r_ready <= '0';
                r_parsed <= '0';

            -- Communicating with external FIFO queue.
            elsif i_dataR_ready = '1' then
                r_ready <= not r_ready;
                r_parsed <= '0';

                if r_ready = '1' then
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
                                preamble_counter := 0;
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
                            io_cmd.m <= t_word(unsigned(i_dataR) - 1); 
                            r_parsed <= '1';        -- Writes new amount of iterations.
                            state := DATA;
                        -- Next input word is expected to be width.
                        when DATA => 
                            o_dataW <= i_dataR;
                            state := WEIGHT; 

                        -- Next input word is expected to be data.
                        when WEIGHT => 
                            o_dataX <= i_dataR;
                            o_data_ready <= '1';
                            state := DATA;

                        when SLEEP => -- Does nothing during sleep.
                        when others => state := UNKNOWN; -- Undefined.
                    end case;
                end if;
            end if;
        end if;
    end process;

    o_dataR_ready <= r_ready;
    o_new_cmd <= r_parsed;
end architecture;
