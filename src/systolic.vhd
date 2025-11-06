-- ============================================================
-- File: systolic.vhd
-- Desc: Implementation of the systolic array based on PEs (Processing Elements) for parallel computing.
--       All parallel logic is abstracted within the architecture, while entity itself provides easy to
--       use serial inputs and outputs, which can be connected to the rest of the coprocessor architecture.
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
use coproc.intrinsics.all;
use coproc.pe;
use coproc.word_shifter;
use coproc.pe_fifo;

entity systolic_arr is
    generic (
        g_OMD   : natural;  -- Operating matrix dimension. 
        g_BATCH : natural   -- Parallel input batch size.
    );
    port (
        i_clk   : in std_logic := '1';  -- Clock signal.
        ni_clr  : in std_logic := '1';  -- Global reset. (Active low).

        i_dataX : in t_word;                                -- Serial input X.
        i_dataW : in t_word;                                -- Serial input W.
        o_dataA : out t_acc_mat(0 to g_OMD, 0 to g_OMD)     -- Serial data output A.
    );

    type t_forward_mesh is array (0 to g_OMD) of t_word_array(0 to g_OMD);  -- X/W values traverse horizontally/vertically and stop at the lest PE element.
    type t_diagonal_mesh is array (0 to g_OMD, 0 to g_OMD) of t_acc;        -- Accumulator outputs.

end entity;

architecture structured of systolic_arr is
    signal w_tempX_array, w_tempW_array : t_word_array(0 to g_OMD) := (others => (others => '0'));
    signal w_dataX_matrix, w_dataW_matrix : t_forward_mesh := (others => (others => (others => '0')));  -- Connection wires between PE elements for X and W inputs.
    signal w_dataA_matrix : t_diagonal_mesh := (others => (others => (others => '0')));                 -- Accumulator values wires. Forwarded diagonally.

    -- FIFO control signals for columns and rows.
    signal w_tx_ready_ic, w_rx_ready_ic, w_tx_ready_oc, w_rx_ready_oc : std_logic_vector(0 to g_OMD) := (others => '0');
    signal w_tx_ready_ir, w_rx_ready_ir, w_tx_ready_or, w_rx_ready_or : std_logic_vector(0 to g_OMD) := (others => '0');
begin
    -- Word shifter instance for X inputs.
    WORD_SHIFT_X_Inst : entity word_shifter
    generic map (
        g_LENGTH => g_OMD
                )
    port map (
        ni_clr => ni_clr,
        i_clk => i_clk,
        i_data => i_dataX,
        o_batch => w_tempX_array
             );

    -- Maps SIPO shift register output to each PE row via FIFO block.
    g_ROW_FIFOS : for i in 0 to g_OMD generate
        PE_FIFO_Inst : entity pe_fifo
        generic map (
            g_BLOCK_SIZE => g_OMD
                    )
        port map (
            i_clk => i_clk,
            na_clr => ni_clr,
            i_data => w_tempX_array(i),
            o_data => w_dataX_matrix(0)(i),
            i_tx_ready => w_tx_ready_ir(i),
            i_rx_ready => w_rx_ready_ir(i),
            o_tx_ready => w_tx_ready_or(i),
            o_rx_ready => w_rx_ready_or(i)
                 );
    end generate;

    -- Word shifter instance for W inputs.
    WORD_SHIFT_W_Inst : entity word_shifter
    generic map (
        g_LENGTH => g_OMD
                )
    port map (
        ni_clr => ni_clr,
        i_clk => i_clk,
        i_data => i_dataW,
        o_batch => w_tempW_array
             );

    -- Maps SIPO shift register output to each PE column via FIFO block.
    g_COL_FIFOS : for i in 0 to g_OMD generate
        PE_FIFO_Inst : entity pe_fifo
        generic map (
            g_BLOCK_SIZE => g_OMD
                    )
        port map (
            i_clk => i_clk,
            na_clr => ni_clr,
            i_data => w_tempW_array(i),
            o_data => w_dataW_matrix(i)(0),
            i_tx_ready => w_tx_ready_ic(i),
            i_rx_ready => w_rx_ready_ic(i),
            o_tx_ready => w_tx_ready_oc(i),
            o_rx_ready => w_rx_ready_oc(i)
                 );
    end generate;

    -- Generates g_OMD^2 interconnected PE elements for systolic processing.
    g_SystolicGenI : for i in 0 to g_OMD - 1 generate
        g_SystolicGenJ : for j in 0 to g_OMD - 1 generate 
            PE_Inst : entity pe
            port map (
                ni_clr => ni_clr,
                i_clk => i_clk,
                
                i_xin => w_dataX_matrix(i)(j),
                i_win => w_dataW_matrix(i)(j),

                o_xout => w_dataX_matrix(i)(j + 1),     -- Forward vector [0, 1]
                o_wout => w_dataW_matrix(i + 1)(j),     -- Forward vector [1, 0]
                o_aout => w_dataA_matrix(i, j)          -- Accumulator outputs.
            );
        end generate;
    end generate;
end architecture;

