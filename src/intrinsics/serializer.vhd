-- ============================================================
-- File: serializer.vhd
-- Desc: Allows to read accumulator values from the systolic array by providing required
--  id value. RTL of this component is basically a multiplexer for matrix of accumulators, where
--  higher id's provides next value in zigzag matter, corresponding to the way how PEs are filled
--  within the systolic array.
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

entity serializer is
    generic (
        g_OMD : natural             -- Operating matrix dimensions.
    );
    port (
        i_clk       : in std_logic := '1';                          -- Systolic array domain clock signal.
        i_spi_clk   : in std_logic := '1';                          -- SPI domain clock signal
        na_clr  : in std_logic := '1';                              -- Asynchronous clear (Active Low).

        i_batch_sampled : in std_logic := '0';                      -- Signal that shall notify about that next batch is sampled.
        i_iterations_write: in std_logic := '0';                    -- Write signal to write iterations value.
        i_iterations : in t_word := (others => '0');                -- Iterations that correspond to amount of iterations needed until PE(00) is ready.
        
        i_accs  : in t_word_mat(0 to g_OMD - 1, 0 to g_OMD - 1);    -- Input matrix of PE's accumulators.
        i_clr   : in std_logic := '0';                              -- Synchronous clear. Clears the state machine.
        i_rx_ready : in std_logic := '0';                           -- FIFO read ready input.
        o_rx_ready : out std_logic;                                 -- FIFO read ready output.
        o_acc   : out t_spi_word                                    -- Byte-sized output word for SPI sending.
    );
end entity;

architecture rtl of serializer is
    type t_direction is (UR, DL);                           
    signal r_dir : t_direction := UR;                       -- State machine for zig-zag directions.
    signal r_i, r_j : natural := 0;                         -- Local indexes of systolic array accumulators.
    signal r_read : std_logic := '0';                       -- When set, local state machine progresses.
    signal r_iterations : t_word := (others => '0');  -- Contains the length of input vector for PE(00).

    signal w_acc : t_word := (others => '0');
    signal wo_tx_ready, wi_tx_ready : std_logic := '0';
    signal lc : natural := 0;
begin
    process (i_clk, na_clr, i_clr, r_read) is 
        -- Resets the state machine after last element and dirung asynchronous/synchronous resets. This does not clear iterations.
        procedure serializer_reset is begin
            r_dir <= UR;
            r_i <= 0;
            r_j <= 0;
            r_read <= '0';
            lc <= 0;
        end procedure;
    begin
        -- Main state machine behavior.
        if na_clr = '0' then
            serializer_reset;
            r_iterations <= (others => '0');
        elsif falling_edge(i_clk) then
            if i_clr = '1' then
                serializer_reset;
            else
                -- Data shall be prepared for sampling to FIFO when `wi_tx_ready` gets high.
                if r_read = '1' and wi_tx_ready = '0' then
                    if r_dir = UR then
                        if r_j = g_OMD - 1 then
                            r_i <= r_i + 1;
                            r_dir <= DL;
                        elsif r_i = 0 then
                            r_j <= r_j + 1;
                            r_dir <= DL;
                        else
                            r_i <= r_i - 1;
                            r_j <= r_j + 1;
                        end if;
                    else
                        if r_i = g_OMD - 1 then
                            r_j <= r_j + 1;
                            r_dir <= UR;
                        elsif r_j = 0 then
                            r_i <= r_i + 1;
                            r_dir <= UR;
                        else
                            r_i <= r_i + 1;
                            r_j <= r_j - 1;
                        end if;
                    end if;

                    -- Reset when finished.
                    if r_i = g_OMD - 1 and r_j = g_OMD - 1 then
                        serializer_reset; 
                    end if;
                end if;
            end if;

            -- Starts the state machine after the first PE(00) is filled with proper data.
            if i_iterations_write = '1' then
                r_iterations <= i_iterations;
            else
                if i_batch_sampled = '1' then
                    if lc < to_integer(unsigned(r_iterations)) then
                        lc <= lc + 1;
                    else
                        r_read <= '1';
                        lc <= 0;
                    end if;
                end if;
            end if;
        end if;

        -- When in read state, always ready to buffer data into FIFO queue.
        if rising_edge(i_clk) then
            if wo_tx_ready = '1' and r_read = '1' then
                wi_tx_ready <= not wi_tx_ready;
            end if;
        end if;
    end process;

    w_acc <= i_accs(r_i, r_j) when r_read = '1' else (others => '0');

    DOMAIN_FIFO_Inst : entity coproc.domain_fifo
    generic map (
        g_LENGTH => c_DFIFO_S2M_SIZE,
        g_INPUT_DATA_SIZE => t_word'length,
        g_OUTPUT_DATA_SIZE => t_spi_word'length
                )
    port map (
        ni_clr => na_clr,
        i_clk_producer => i_clk,
        i_clk_consumer => i_spi_clk,
        
        i_tx => w_acc,
        o_rx => o_acc,

        i_rx_ready => i_rx_ready,
        i_tx_ready => wi_tx_ready,
        o_rx_ready => o_rx_ready,
        o_tx_ready => wo_tx_ready
             );
end architecture;
