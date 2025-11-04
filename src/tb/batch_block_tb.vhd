-- ============================================================
-- File: batch_block_tb.vhd
-- Desc: Buffer that will be filled by NIOS V processor and sequenced to systolic array. Testing batch block is a 4x4 RAM block.
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
use std.textio.all;
use coproc.intrinsics.all;
use coproc.batch_block;
use coproc.tb.all;

entity batch_block_tb is
    type tb_dut is record
        na_clr    : std_logic;                                       
        i_wr_clk  : std_logic; 
        i_wr   : std_logic;                                       
        i_wr_row  : std_logic_vector(1 downto 0);   
        i_wr_col  : std_logic_vector(1 downto 0);   
        i_data    : t_word;                                                 
        i_rd_clk  : std_logic; 
        i_rd_row  : std_logic_vector(1 downto 0);           
        i_rd_col  : std_logic_vector(1 downto 0);
        o_sticky  : std_logic_vector(0 to 3);
        o_data    : t_word;                         
    end record;
end entity;

architecture behavioral of batch_block_tb is
    signal sigs : tb_dut := (
        na_clr   => '1',   
        i_wr_clk => '0',
        i_wr  => '1',   
        i_wr_row => (others => '0'),   
        i_wr_col => (others => '0'),   
        i_data   => (others => '0'),          
        i_rd_clk => '0',
        i_rd_row => (others => '0'),          
        i_rd_col => (others => '0'),          
        o_sticky => (others => '0'),
        o_data   => (others => '0')                       
    );

    -- Clock frequency generation for different domains.
    signal freq_nios   : real := 100.000e6;
    signal freq_coproc : real := 400.000e6;

    type t_dummy_matrix is array (natural range 0 to 3) of t_word_array(0 to 3);
begin 
    BATCH_BLOCK_Inst : entity batch_block
    generic map (
        g_DIMENSION => 4
                )
    port map (
        na_clr   => sigs.na_clr,
        i_wr_clk => sigs.i_wr_clk,
        i_wr  => sigs.i_wr,
        i_wr_row => sigs.i_wr_row,
        i_wr_col => sigs.i_wr_col,
        i_data   => sigs.i_data,
        i_rd_clk => sigs.i_rd_clk,
        i_rd_row => sigs.i_rd_row,
        i_rd_col => sigs.i_rd_col,
        o_data   => sigs.o_data,
        o_sticky => sigs.o_sticky
    );

    -- Simulates input clocks.
    p_EX_CLOCK_1 : tick(sigs.i_wr_clk, freq_nios);
    p_EX_CLOCK_2 : tick(sigs.i_rd_clk, freq_coproc);

    -- Simulates writing procedure from NIOS V.
    p_MAIN_NIOSV : process is
        variable dummy : t_dummy_matrix := (
            (x"01", x"02", x"03", x"04"), 
            (x"05", x"06", x"07", x"00"), 
            (x"08", x"09", x"00", x"00"), 
            (x"0A", x"00", x"00", x"00")
        );
    begin
        report "Enter p_MAIN_NIOS.";

        sigs.i_wr <= '1';
        -- Filling data in a certain pattern required by PE elements.
        for i in 0 to 3 loop
            for j in 0 to 3 loop
                sigs.i_wr_row <= std_logic_vector(to_unsigned(i, 2));
                sigs.i_wr_col <= std_logic_vector(to_unsigned(j, 2));
                sigs.i_data <= dummy(i)(j);
                report "Wrote: " & to_hstring(dummy(i)(j));

                wait until rising_edge(sigs.i_wr_clk);
            end loop;
        end loop;
        sigs.i_wr <= '0';

        report "Done p_MAIN_NIOS.";
        stop_clock(freq_nios);
        wait;
    end process;

    -- Simulates read procedure from systolic array.
    p_MAIN_SYST : process is
        variable obtained : line := null;
    begin
        report "Enter p_MAIN_SYST.";

        wait until rising_edge(sigs.i_rd_clk);

        for i in 0 to 3 loop
            for j in 0 to 3 loop
                sigs.i_rd_row <= std_logic_vector(to_unsigned(i, 2));
                sigs.i_rd_col <= std_logic_vector(to_unsigned(j, 2));

                wait until rising_edge(sigs.i_rd_clk);

                -- Never read something that is being rewritten.
                if sigs.o_sticky(i) = '0' then
                    report "STICKY";
                    wait until sigs.o_sticky(i) = '1';
                end if;
                
                -- RAM timeout. 
                wait until rising_edge(sigs.i_rd_clk);
                wait until rising_edge(sigs.i_rd_clk);

                report "Read: " & to_hstring(sigs.o_data);
                write(obtained, to_hstring(sigs.o_data));
                if j < 3 then
                    write(obtained, string'(", "));
                else
                    write(obtained, LF);
                end if;
            end loop;
        end loop;

        report "Obtained " & LF & "[" & LF & obtained.all & "]";

        report "Done p_MAIN_SYST.";
        stop_clock(freq_coproc);
        wait;
    end process;
end architecture;
