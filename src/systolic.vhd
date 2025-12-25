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
use coproc.serializer;

entity systolic_arr is
    generic (
        g_OMD   : natural               -- Operating matrix dimension. 
    );
    port (
        i_clk       : in std_logic := '1';  -- Systolic array domain clock signal.
        i_spi_clk   : in std_logic := '1';  -- SPI domain clock signal
        ni_clr      : in std_logic := '1';  -- Global reset. (Active low).
    
        i_batch_length : in std_logic_vector(log2(g_OMD) - 1 downto 0);
        i_se_clr : in std_logic := '0';                         -- Clear flag for serializer block.
        i_se_iterations : in t_word := (others => '0');         -- Iterations word forwarded to serializer unit.
        i_se_iterations_write : in std_logic := '0';            -- Iteration write flag. 
        i_shift_ready : in std_logic := '0';                    -- Goes high when new parsed data is ready to being shifted.

        i_dataX : in t_word;            -- Serial input X.
        i_dataW : in t_word;            -- Serial input W.

        i_rx_ready : in std_logic := '0';   -- FIFO read ready input.
        o_rx_ready : out std_logic;         -- FIFO read ready output.
        o_dataA : out t_spi_word            -- Serial output of accumulators A converted to SPI bytes.
    );

    type t_forward_mesh is array (0 to g_OMD) of t_word_array(0 to g_OMD);  -- X/W values traverse horizontally/vertically and stop at the lest PE element.
end entity;

architecture structured of systolic_arr is
    signal w_tempX_array, w_tempW_array : t_word_array(0 to g_OMD - 1) := (others => (others => '0'));
    signal w_dataX_matrix, w_dataW_matrix : t_forward_mesh := (others => (others => (others => '0')));  
    signal w_dataA_matrix : t_word_mat(0 to g_OMD - 1, 0 to g_OMD - 1) := (others => (others => (others => '0')));
    -- Connection wires between PE elements for X and W inputs.

    -- Word shifter full booleans.
    signal w_full_x, w_full_w : std_logic := '0';
    signal w_syst_enable : std_logic := '0';        -- Enables when new parallel batch input is ready.
begin
    -- Synchronization process.
    process (all) begin
        if falling_edge(i_clk) then
            if (w_full_x and w_full_w) then
                w_syst_enable <= '1';
            else
                w_syst_enable <= '0';
            end if;
        end if;
    end process;

    -- Word shifter instance for X inputs.
    WORD_SHIFT_X_Inst : entity word_shifter
    generic map (
        g_LENGTH => g_OMD
                )
    port map (
        na_clr => ni_clr,
        i_clk => i_clk,
        i_data => i_dataX,
        i_write => i_shift_ready,
        o_full => w_full_x,
        i_batch_length => i_batch_length,
        o_batch => w_tempX_array
             );

    -- Maps X inputs vertically.
    g_XMAP : for i in 0 to g_OMD - 1 generate
        w_dataX_matrix(i)(0) <= w_tempX_array(i);
    end generate;

    -- Word shifter instance for W inputs.
    WORD_SHIFT_W_Inst : entity word_shifter
    generic map (
        g_LENGTH => g_OMD
                )
    port map (
        na_clr => ni_clr,
        i_clk => i_clk,
        i_data => i_dataW,
        i_write => i_shift_ready,
        o_full => w_full_w,
        i_batch_length => i_batch_length,
        o_batch => w_tempW_array
             );

    -- Maps W inputs horizontally.
    g_WMAP : for i in 0 to g_OMD - 1 generate
        w_dataW_matrix(0)(i) <= w_tempW_array(i);
    end generate;

    -- Generates g_OMD^2 interconnected PE elements for systolic processing.
    g_SystolicGenI : for i in 0 to g_OMD - 1 generate
        g_SystolicGenJ : for j in 0 to g_OMD - 1 generate 
            PE_Inst : entity pe
            port map (
                ni_clr => ni_clr,
                i_clk => i_clk,
                i_en => w_syst_enable,
                
                i_xin => w_dataX_matrix(i)(j),
                i_win => w_dataW_matrix(i)(j),

                o_xout => w_dataX_matrix(i)(j + 1),     -- Forward vector [0, 1]
                o_wout => w_dataW_matrix(i + 1)(j),     -- Forward vector [1, 0]
                o_aout => w_dataA_matrix(i, j)          -- Accumulator outputs.
            );
        end generate;
    end generate;

    -- Converts accumulated PE's output to serial stream of values for NIOS V to read.
    SERIALIZER_Inst : entity serializer
    generic map (
        g_OMD => g_OMD
                )
    port map (
        i_clk => i_clk,
        i_spi_clk => i_spi_clk,
        na_clr => ni_clr,
        i_clr => i_se_clr,
        o_acc => o_dataA,
        i_batch_length => i_batch_length,
        i_iterations => i_se_iterations,
        i_iterations_write => i_se_iterations_write,
        i_rx_ready => i_rx_ready,
        o_rx_ready => o_rx_ready,
        i_batch_sampled => w_syst_enable,
        i_accs => w_dataA_matrix
             );
end architecture;

