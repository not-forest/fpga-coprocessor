-- ============================================================
-- File: batch_block.vhd
-- Desc: Buffer that will be filled by NIOS V processor and sequenced to systolic array.
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
        g_DIMENSION : natural         -- Dimension defines the size of internal RAM block.
    );
    port (
        na_clr    : in  std_logic := '1';                                       -- Asynchronous clear (Active Low)
        i_wr      : in  std_logic := '0';                                       -- Write enable signal.

        -- Write port (Port A)
        i_wr_clk  : in  std_logic := '1';                                       -- Clock input for writing (NIOS V domain). 
        i_wr_row  : in  std_logic_vector(log2(g_DIMENSION) - 1 downto 0);       -- Row index.
        i_wr_col  : in  std_logic_vector(log2(g_DIMENSION) - 1 downto 0);       -- Column index.
        i_data    : in  t_word;                                                 -- Input data word.

        -- Read port (Port B)
        i_rd_clk  : in  std_logic := '1';                                       -- Clock input for reading (systolic array domain). 
        i_rd_row  : in  std_logic_vector(log2(g_DIMENSION) - 1 downto 0);       -- Row index.
        i_rd_col  : in  std_logic_vector(log2(g_DIMENSION) - 1 downto 0);       -- Column index.
        o_data    : out t_word;                                                 -- Output row. Flattened.
        o_sticky  : out std_logic_vector(0 to g_DIMENSION - 1)                  -- Sticky bit for each row that marks it as a proper read.
    );
end entity;

architecture vendor of batch_block is
    constant c_ADDR_LENGTH : natural := 2 * log2(g_DIMENSION);
    constant c_LAST_ADDR : natural :=  g_DIMENSION - 1;

    -- Helper function to check whether current index value is the last one.
    function is_last_idx (
        sig : std_logic_vector(log2(g_DIMENSION) - 1 downto 0) 
    ) return boolean is begin
        return to_integer(unsigned(sig)) = c_LAST_ADDR;
    end function;

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

    -- -- CDC signals -- --
    -- Toggles when row completed by writer
    signal wr_toggle       : std_logic_vector(0 to g_DIMENSION - 1) := (others => '0');

    -- Synchronizers for rd_toggle (ack)
    signal rd_sync1_wr     : std_logic_vector(0 to g_DIMENSION - 1) := (others => '0');
    signal rd_sync2_wr     : std_logic_vector(0 to g_DIMENSION - 1) := (others => '0');
    signal rd_sync2_wr_prev: std_logic_vector(0 to g_DIMENSION - 1) := (others => '0');

    -- Synchronizers for wr_toggle
    signal wr_sync1_rd     : std_logic_vector(0 to g_DIMENSION - 1) := (others => '0');
    signal wr_sync2_rd     : std_logic_vector(0 to g_DIMENSION - 1) := (others => '0');
    signal wr_sync2_rd_prev: std_logic_vector(0 to g_DIMENSION - 1) := (others => '0');

    -- Ack toggle (read -> write) - toggled when a row is consumed.
    signal rd_toggle       : std_logic_vector(0 to g_DIMENSION - 1) := (others => '0');

    -- Local sticky flags, which is exposed to outside read peripheral.
    signal r_sticky        : std_logic_vector(0 to g_DIMENSION - 1) := (others => '0');
begin
    -- Write-domain process: generate wr_toggle when the writer finishes a row, and synchronize ack 
    -- (rd_toggle) back into write domain.
    g_write_dom : process(i_wr_clk, na_clr) begin
        if na_clr = '0' then
            wr_toggle        <= (others => '0');
            rd_sync1_wr      <= (others => '0');
            rd_sync2_wr      <= (others => '0');
            rd_sync2_wr_prev <= (others => '0');
        elsif rising_edge(i_wr_clk) then
            -- Toggle the write indicator for the indexed row when last write element is written.
            if (i_wr = '1' and is_last_idx(i_wr_col)) then
                -- flip only the addressed bit
                wr_toggle(to_integer(unsigned(i_wr_row))) <= not wr_toggle(to_integer(unsigned(i_wr_row)));
            end if;

            -- Synchronize ack (rd_toggle) coming from read domain into write domain
            rd_sync1_wr <= rd_toggle;
            rd_sync2_wr <= rd_sync1_wr;

            -- (optional) detect ack edges on write side if you want to react there:
            rd_sync2_wr_prev <= rd_sync2_wr;
            -- Example usage (not modifying wr_toggle here): if rd_sync2_wr /= rd_sync2_wr_prev then ... end if;
            -- We intentionally don't clear wr_toggle on ack; wr_toggle is a toggle-based event source.
        end if;
    end process;

    -- Read-domain process: synchronize wr_toggle into read domain, detect edges, set r_sticky, and when the read 
    -- consumes the last element, clear r_sticky and toggle rd_toggle to acknowledge the read completion back to writer.
    g_read_dom : process(i_rd_clk, na_clr) is 
        variable edge_vec : std_logic_vector(0 to g_DIMENSION - 1);
    begin
        if na_clr = '0' then
            wr_sync1_rd      <= (others => '0');
            wr_sync2_rd      <= (others => '0');
            wr_sync2_rd_prev <= (others => '0');
            r_sticky         <= (others => '0');
            rd_toggle        <= (others => '0');
        elsif rising_edge(i_rd_clk) then
            -- Synchronize writer toggles into read domain (two-flop)
            wr_sync1_rd <= wr_toggle;
            wr_sync2_rd <= wr_sync1_rd;

            -- Any bit that changes means new data was posted for that row.
            -- Set sticky for those rows (sticky latch until read consumes).
            edge_vec := (others => '0');
            for i in 0 to g_DIMENSION - 1 loop
                if wr_sync2_rd(i) /= wr_sync2_rd_prev(i) then
                    edge_vec(i) := '1';
                else
                    edge_vec(i) := '0';
                end if;
            end loop;

            -- Latch sticky bits: set when new data detected
            for i in 0 to g_DIMENSION - 1 loop
                if edge_vec(i) = '1' then
                    r_sticky(i) <= '1';
                end if;
            end loop;

            -- If reader finishes a row (last element read), clear the sticky bit for that row
            -- and toggle the read-ack for that row so writer can see the consumption (synchronized back).
            if is_last_idx(i_rd_col) then
                -- Clear sticky for the currently read row (the reader has consumed it)
                r_sticky(to_integer(unsigned(i_rd_row))) <= '0';
                -- Toggle ack for the read row
                rd_toggle(to_integer(unsigned(i_rd_row))) <= not rd_toggle(to_integer(unsigned(i_rd_row)));
            end if;

            -- Updates previous copy for edge detection next cycle
            wr_sync2_rd_prev <= wr_sync2_rd;
        end if;
    end process;

    ALTSYNCRAM_Inst : altsyncram
        generic map (
            address_aclr_b         => "CLEAR1",
            address_reg_b          => "CLOCK1",
            clock_enable_input_a   => "BYPASS",
            clock_enable_input_b   => "BYPASS",
            clock_enable_output_b  => "BYPASS",
            intended_device_family => "Cyclone IV E",
            lpm_type               => "altsyncram",
            numwords_a             => g_DIMENSION * g_DIMENSION,
            numwords_b             => g_DIMENSION * g_DIMENSION,
            operation_mode         => "DUAL_PORT",
            outdata_aclr_b         => "CLEAR1",
            outdata_reg_b          => "CLOCK1",
            power_up_uninitialized => "FALSE",
            ram_block_type         => "M9K",
            widthad_a              => c_ADDR_LENGTH,
            widthad_b              => c_ADDR_LENGTH,
            width_a                => t_word'length,   
            width_b                => t_word'length,
            width_byteena_a        => 1
        )
        port map (
            aclr1     => not na_clr,
            address_a => i_wr_row & i_wr_col,
            address_b => i_rd_row & i_rd_col,
            clock0    => i_wr_clk,
            clock1    => i_rd_clk,
            data_a    => i_data,
            wren_a    => i_wr,
            q_b       => o_data
        );

    o_sticky <= r_sticky;
end architecture;
