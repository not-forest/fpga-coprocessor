-- ============================================================
-- File: sipo.vhd
-- Desc: Word shifting memory block for systolic array inputs. Shifts upcoming word of data and flushes the entire
--      previous batch on each clock cycle simultaneously. Internally acts as a SIPO block of N registers.
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
use coproc.intrinsics.all;

entity word_shifter is
    generic (
        g_LENGTH : natural      -- Describes how many words can be held in this shifter.
            );
    port (
        ni_clr  : in std_logic := '1';      -- Synchronous clear (Active low).
        i_clk   : in std_logic := '1';      -- Clock input. Shifts and pushes elements at the same time.
        i_write : in std_logic := '1';      -- Starts writing procedure.
        i_data  : in t_word;                -- Data input. One value at a time.
        o_full  : out std_logic;            -- Sets when batch if fully filled with words.
        o_batch : out t_word_array(g_LENGTH - 1 downto 0)          -- Batch output. Data from each register is always seen.
    );
end entity;

library altera_mf;
use altera_mf.all;

-- Architecture is based on `altshift_taps` component for reducing the amount of logic elements used for shifting.
architecture vendor of word_shifter is
    component altshift_taps
        generic (
            intended_device_family : string := "unused";
            number_of_taps : natural;
            power_up_state : string := "CLEARED";
            tap_distance : natural;
            width : natural;
            lpm_hint : string := "UNUSED";
            lpm_type : string := "altshift_taps"
        );
        port (
            aclr        : in std_logic := '0';
            clken       : in std_logic := '1';
            clock       : in std_logic;
            shiftin     : in std_logic_vector(width - 1 downto 0);
            shiftout    : out std_logic_vector(width - 1 downto 0);
            taps        : out std_logic_vector(width * number_of_taps - 1 downto 0)
        );
    end component;

    signal r_batchfull : std_logic := '0';          -- Says whether the full batch is written into the SIPO and ready to be flushed.
    signal w_taps : std_logic_vector(g_LENGTH * t_word'length - 1 downto 0) := (others => '0');
    signal r_write_latency : std_logic := '0';      -- Latency of one clock cycle for i_write signal.
begin
    -- Detects whether batch is full.
    process (all) is 
        variable cnt : natural := 0;
    begin
        if rising_edge(i_clk) then
            if r_write_latency = '1' then
                if r_batchfull = '1' then
                    r_batchfull <= '0';
                end if;

                if cnt < g_LENGTH - 1 then
                   cnt := cnt + 1;
                else
                    cnt := 0;
                    r_batchfull <= '1';
                end if;
            else
                r_batchfull <= '0';
            end if;

            r_write_latency <= i_write;
        end if;
    end process;

    ALTSHIFT_TAPS_Inst : altshift_taps
    generic map (
        intended_device_family => "Cyclone IV E",
        number_of_taps => g_LENGTH,
        tap_distance => 1,
        width => t_word'length,
        lpm_hint => "RAM_BLOCK_TYPE=M9K"
    )
    port map (
        aclr => not ni_clr,
        clken => i_write,
        clock => i_clk,
        shiftin => i_data,
        shiftout => open,
        taps => w_taps
    );

    o_full <= r_batchfull;

    g_BATCHMAP: for i in 0 to o_batch'length - 2 generate
        -- Splitting big taps vector into array of words. For some reason taps output from altshift_taps is shifted to left by one.
        o_batch(i + 1) <= w_taps((g_LENGTH - i) * t_word'length - 1 downto (g_LENGTH - i - 1) * t_word'length);
    end generate;
    o_batch(0) <= w_taps(t_word'length - 1 downto 0);
end architecture;
