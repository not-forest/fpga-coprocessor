-- ============================================================
-- File: avalon_batch_block.vhd
-- Desc: Avalon MM Slave interface wrapper for batch block component.
-- Warn: Vendor specific content ahead. This file is compatible with Quartus Prime software.
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
use coproc.batch_block;

entity avalon_batch_block is
    generic (
        g_PORTA_ADDR_SIZE   : natural := 6;
        g_PORTB_ADDR_SIZE   : natural := 3;
        g_BATCH_SIZE        : natural := 8
            );
    port (
        i_clk   : in std_logic;                                 -- Input clock (NIOS Domain).
        ni_clr  : in std_logic;                                 -- Synchronous reset (Active Low).
        
        -- Avalon-MM Slave interface
        av_address      : in  std_logic_vector(g_PORTA_ADDR_SIZE - 1 downto 0); -- Only port A is expected to be exposed for NIOS V.
        av_write        : in  std_logic;                                        -- Write flag. Shall only be set when writing.
        av_read         : in  std_logic;                                        -- Ignored.
        av_writedata    : in  t_word;                                           -- Input data word.
        av_readdata     : out t_word;                                           -- Always only zeroes.
        av_waitrequest  : out std_logic;                                        -- Always enabled to writing.

        -- Exported conduits.
        i_rd_clk        : in std_logic;
        i_rd_row        : in std_logic_vector(g_PORTB_ADDR_SIZE - 1 downto 0);
        o_data          : out std_logic_vector(g_BATCH_SIZE * t_word'length - 1 downto 0);
        o_rd_ready      : out std_logic
    );
end entity;

architecture avalon of avalon_batch_block is
begin
    BATCH_BLOCK_Inst : entity batch_block
    generic map (
        g_PORTA_ADDR_SIZE => g_PORTA_ADDR_SIZE,
        g_PORTB_ADDR_SIZE => g_PORTB_ADDR_SIZE,
        g_BATCH_SIZE => g_BATCH_SIZE
                )
    port map (
        na_clr   => ni_clr,
        i_wr_clk => i_clk,
        i_wr     => av_write,
        i_wr_row => av_address(g_PORTA_ADDR_SIZE - 1 downto g_PORTA_ADDR_SIZE / 2),
        i_wr_col => av_address(g_PORTA_ADDR_SIZE / 2 - 1 downto 0),
        i_data   => av_writedata, -- adjust width as needed
        i_rd_clk => i_rd_clk,
        i_rd_row => i_rd_row,
        o_data => o_data
             );

    av_waitrequest <= '0';          -- Always ready for writing.
    av_readdata <= (others => '0'); -- Writing has no use for the current wrapper.
end architecture;
