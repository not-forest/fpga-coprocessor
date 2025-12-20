-- ============================================================
-- File: systolic_tb.vhd
-- Desc: Testbench for systolic array implementation. Tests the array to perform different operations
--       based on the way how input data is provided within the systolic array.
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
use coproc.tb.all;
use coproc.systolic_arr;

entity systolic_tb is
    type tb_dut is record
        i_clk   : std_logic;
        i_spi_clk   : std_logic;
        ni_clr  : std_logic;
        i_shift_ready : std_logic;

        i_se_clr : std_logic;
        i_se_iterations : t_word;
        i_se_iterations_write : std_logic;

        i_rx_ready : std_logic; 
        o_rx_ready : std_logic;

        i_dataX : t_word;
        i_dataW : t_word;
        o_dataA : t_spi_word;
    end record;
end entity;

architecture behavioral of systolic_tb is
    signal sigs : tb_dut := (
        i_clk => '1',
        i_spi_clk => '1',
        ni_clr => '1',
        i_shift_ready => '0',
        i_se_clr => '0',
        i_se_iterations => (others => '0'),
        i_se_iterations_write => '0',
        i_rx_ready => '0', 
        o_rx_ready => '0',
        i_dataX => (others => '0'),
        i_dataW => (others => '0'),
        o_dataA => (others => '0')
    ); 

    type t_spi_word_array is array (natural range <>) of t_spi_word;

    -- Two different clock domains.
    signal freq1 : real := 200.000e6;
    signal freq2 : real := 50.000e6;
begin
    SYSTOLIC_ARR_Inst : entity systolic_arr 
    generic map (
        g_OMD => 2          -- Testing on 2x2 systolic array.
                )
    port map (
        ni_clr => sigs.ni_clr,
        i_clk => sigs.i_clk,
        i_spi_clk => sigs.i_spi_clk,
        i_shift_ready => sigs.i_shift_ready,
    
        i_se_clr => sigs.i_se_clr,
        i_se_iterations => sigs.i_se_iterations,
        i_se_iterations_write => sigs.i_se_iterations_write,

        i_rx_ready => sigs.i_rx_ready,
        o_rx_ready => sigs.o_rx_ready,

        i_dataX => sigs.i_dataX,
        i_dataW => sigs.i_dataW,
        o_dataA => sigs.o_dataA
             );

    -- Simulating two clocks.
    p_EX_CLOCK1 : tick(sigs.i_clk, freq1);
    p_EX_CLOCK2 : tick(sigs.i_spi_clk, freq2);

    -- Peforms matrix multiplication.
    p_MATRIX_MULTIPLICATION : process is
        constant c_AMOUNT : natural := 7;
        -- 2x2 Inputs padded with zeroes, where last zero padding is required for (n^2 + 4n + 1) + 1 additional cycle.
        --                                                                                          |this one|
        -- Last zero padding can be changed to next pipelined data if multiple operations with
        -- one operation mode is used.
        constant c_X : t_word_array(0 to c_AMOUNT - 1) := (w(01), w(00), w(02), w(03), w(00), w(04), w(00));
        constant c_W : t_word_array(0 to c_AMOUNT - 1) := (w(05), w(00), w(07), w(06), w(00), w(08), w(00));
        -- Here we multiply:
        -- | 1  2 | X | 5  6 | = | 19  43 |
        -- | 3  4 |   | 7  9 |   | 22  50 |
    begin
        report "Enter p_MATRIX_MULTIPLICATION.";

        -- Preparing iteration value.
        sigs.i_se_iterations <= w(2);
        sigs.i_se_iterations_write <= '1';
        wait until falling_edge(sigs.i_clk);
        sigs.i_se_iterations_write <= '0';
        wait until falling_edge(sigs.i_clk);

        sigs.i_shift_ready <= '1';
        for i in 0 to c_AMOUNT - 1 loop
            wait until falling_edge(sigs.i_clk);
            sigs.i_dataX <= c_X(i);
            sigs.i_dataW <= c_W(i);
        end loop;
        
        wait until falling_edge(sigs.i_clk);
        sigs.i_shift_ready <= '0';

        wait for 500 ns;

        report "Done: p_MATRIX_MULTIPLICATION.";
        stop_clock(freq1);
        wait;
    end process;

    -- Obtaining computed multiplication output.
    p_MAIN : process is 
        constant c_EXPECTED : t_spi_word_array := (
            x"13", x"00", 
            x"16", x"00",
            x"2B", x"00",
            x"32", x"00"
        ); 
    begin
        report "Enter p_MAIN.";

        for i in 0 to c_EXPECTED'length - 1 loop
            if sigs.o_rx_ready /= '1' then
                wait until sigs.o_rx_ready = '1';
                wait until falling_edge(sigs.i_spi_clk);
            end if;
            sigs.i_rx_ready <= '1';

            wait until falling_edge(sigs.i_spi_clk);
            wait until falling_edge(sigs.i_spi_clk);
            -- Outputs are expected to be little-endian 8-bit stream ready for SPI.
            assert sigs.o_dataA = c_EXPECTED(i) 
                report "Matrix multiplication error. Expected: " & to_hstring(c_EXPECTED(i)) & ", got: " & to_hstring(sigs.o_dataA) 
                severity error;
            report "Output: " & to_hstring(sigs.o_dataA);

            sigs.i_rx_ready <= '0';
            wait until falling_edge(sigs.i_spi_clk);
        end loop;

        report "Done: p_MAIN";

        stop_clock(freq2);
        wait;
    end process;
end architecture;
