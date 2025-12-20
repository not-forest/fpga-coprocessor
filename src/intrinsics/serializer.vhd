-- ============================================================
-- File: serializer.vhd
-- Desc: Allows to read accumulator values from the systolic array by providing required
--  id value. Internal state machine samples diagonals of PE elements once they become ready
--  in a wave-like manner and pushes them into FIFO. This allows to sample out proper outputs
--  without the need of stalling the entire systolic array pipeline.
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
    constant C_DIAGS : natural := 2 * g_OMD - 1;

    signal lc         : natural := 0;
    signal iters      : natural := 0;

    signal d_sample   : natural range 0 to C_DIAGS := 0;
    signal armed      : std_logic := '0';

    signal r_i, r_j   : natural range 0 to g_OMD-1 := 0;
    signal r_subclk   : std_logic := '0';

    signal w_acc      : t_word := (others => '0');

    signal wo_tx_ready, wi_tx_ready : std_logic := '0';

    type t_state is (IDLE, START_DIAG, WALK_DIAG);
    signal state : t_state := IDLE;

begin

    ----------------------------------------------------------------------------
    -- LC and iteration tracking
    ----------------------------------------------------------------------------
    process(i_clk, na_clr)
    begin
        if na_clr = '0' then
            lc <= 0;
            iters <= 0;
        elsif rising_edge(i_clk) then
            if i_clr = '1' then
                lc <= 0;
            elsif i_batch_sampled = '1' then
                lc <= lc + 1;
            end if;

            if i_iterations_write = '1' then
                iters <= to_integer(unsigned(i_iterations));
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Armed flag to enable FSM only after valid batch sampling
    ----------------------------------------------------------------------------
    process(i_clk, na_clr)
    begin
        if na_clr = '0' then
            armed <= '0';
        elsif rising_edge(i_clk) then
            if i_clr = '1' then
                armed <= '0';
            elsif i_batch_sampled = '1' then
                armed <= '1';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Diagonal sampling FSM on rising edge
    ----------------------------------------------------------------------------
    process(i_clk, na_clr)
    begin
        if na_clr = '0' then
            state <= IDLE;
            d_sample <= 0;
            r_i <= 0;
            r_j <= 0;
            wi_tx_ready <= '0';
        elsif falling_edge(i_clk) then
            if r_subclk = '0' then
                if state = WALK_DIAG then
                    wi_tx_ready <= '1';
                end if;
            end if;
        elsif rising_edge(i_clk) then
            r_subclk <= not r_subclk;

            if r_subclk = '1' then
                wi_tx_ready <= '0';
                case state is
                    when IDLE =>
                        if armed = '1' and d_sample < C_DIAGS and lc >= iters + d_sample then
                            state <= START_DIAG;
                        end if;

                    when START_DIAG =>
                    -- Calculate start of diagonal indexes
                        if d_sample > g_OMD - 1 then
                            r_i <= d_sample - (g_OMD - 1);
                            r_j <= g_OMD - 1;
                        else
                            r_i <= 0;
                            r_j <= d_sample;
                        end if;
                        state <= WALK_DIAG;

                    when WALK_DIAG =>
                        if wo_tx_ready = '1' then
                            if r_i = g_OMD - 1 or r_j = 0 then
                                d_sample <= d_sample + 1;
                                state <= IDLE;
                            else
                                r_i <= r_i + 1;
                                r_j <= r_j - 1;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Data selection for FIFO input
    ----------------------------------------------------------------------------
    w_acc <= i_accs(r_i, r_j);

    ----------------------------------------------------------------------------
    -- FIFO instance
    ----------------------------------------------------------------------------
    DOMAIN_FIFO_Inst : entity coproc.domain_fifo
        generic map (
            g_LENGTH => c_DFIFO_S2M_SIZE,
            g_INPUT_DATA_SIZE => t_word'length,
            g_OUTPUT_DATA_SIZE => t_spi_word'length,
            g_OUTPUT_DELTA_SLACK => FALSE
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
