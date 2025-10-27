-- ============================================================
-- File: batch_block.vhd
-- Desc: Buffer of upcoming sample batches with transaction ids.
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
library altera_mf;

use ieee.std_logic_1164.all;
use coproc.intrinsics.all;
use ieee.numeric_std.all;
use altera_mf.all;

entity batch_block is
    generic (
        g_PORTA_ADDR_SIZE : natural;       -- Size of the bus addressing from port A
        g_PORTB_ADDR_SIZE : natural;       -- Size of the bus addressing from port B
        g_BATCH_SIZE : natural             -- Batch of words. This is the size of parallel writes coming into the systolic array.
    );
    port (
        na_clr    : in  std_logic := '1';                                       -- Asynchronous clear (Active Low)
        i_wr      : in  std_logic := '0';                                       -- Write enable signal.

        -- Write port (Port A)
        i_wr_clk  : in  std_logic := '1';                                       -- Clock input for writing (NIOS V domain). 
        i_wr_row  : in  std_logic_vector(g_PORTA_ADDR_SIZE / 2 - 1 downto 0);   -- Row index.
        i_wr_col  : in  std_logic_vector(g_PORTA_ADDR_SIZE / 2 - 1 downto 0);   -- Column index.
        i_data    : in  t_word;                                                 -- Input data word.

        -- Read port (Port B)
        i_rd_clk  : in  std_logic := '1';                                       -- Clock input for reading (systolic array domain). 
        i_rd_row  : in  std_logic_vector(g_PORTB_ADDR_SIZE - 1 downto 0);       -- Row index.
        o_data    : out std_logic_vector(g_BATCH_SIZE * t_word'length  - 1 downto 0);   -- Output row. Flattened.
        o_rd_ready: out std_logic := '0'                                        -- Set when not in write mode.
    );
end entity;

architecture vendor of batch_block is
    constant c_ROW_WIDTH_BITS : natural := g_BATCH_SIZE * t_word'length;

    component altsyncram is
        generic (
            address_aclr_b          : string;
            address_reg_b           : string;
            clock_enable_input_a    : string;
            clock_enable_input_b    : string;
            clock_enable_output_b   : string;
            intended_device_family  : string;
            lpm_type                : string;
            numwords_a              : integer;
            numwords_b              : integer;
            operation_mode          : string;
            outdata_aclr_b          : string;
            outdata_reg_b           : string;
            power_up_uninitialized  : string;
            ram_block_type          : string;
            widthad_a               : integer;
            widthad_b               : integer;
            width_a                 : integer;
            width_b                 : integer;
            width_byteena_a         : integer
        );
        port (
            aclr1       : in  std_logic;
            address_a   : in  std_logic_vector(widthad_a-1 downto 0);
            address_b   : in  std_logic_vector(widthad_b-1 downto 0);
            clock0      : in  std_logic;
            clock1      : in  std_logic;
            data_a      : in  std_logic_vector(width_a-1 downto 0);
            wren_a      : in  std_logic;
            q_b         : out std_logic_vector(width_b-1 downto 0)
        );
    end component;
begin
    ALTSYNCRAM_Inst : altsyncram
        generic map (
            address_aclr_b         => "CLEAR1",
            address_reg_b          => "CLOCK1",
            clock_enable_input_a   => "BYPASS",
            clock_enable_input_b   => "BYPASS",
            clock_enable_output_b  => "BYPASS",
            intended_device_family => "Cyclone IV E",
            lpm_type               => "altsyncram",
            numwords_a             => 2 ** g_PORTA_ADDR_SIZE,
            numwords_b             => 2 ** g_PORTB_ADDR_SIZE,
            operation_mode         => "DUAL_PORT",
            outdata_aclr_b         => "CLEAR1",
            outdata_reg_b          => "CLOCK1",
            power_up_uninitialized => "FALSE",
            ram_block_type         => "M9K",
            widthad_a              => g_PORTA_ADDR_SIZE,
            widthad_b              => g_PORTB_ADDR_SIZE,
            width_a                => t_word'length,   
            width_b                => c_ROW_WIDTH_BITS,
            width_byteena_a        => 1
        )
        port map (
            aclr1     => not na_clr,
            address_a => i_wr_row & i_wr_col,
            address_b => i_rd_row,
            clock0    => i_wr_clk,
            clock1    => i_rd_clk,
            data_a    => std_logic_vector(i_data),
            wren_a    => i_wr,
            q_b       => o_data
        );

    o_rd_ready <= not i_wr;
end architecture;
