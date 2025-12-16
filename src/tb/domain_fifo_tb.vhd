-- ============================================================
-- File: domain_fifo_tb.vhd
-- Desc: Testbench for two duplex FIFO queues working in pair. Performs an echo between two differently clocked
-- parts of the system. Dummy words from SPI dimension shall be queued to system dimension and then
-- echoed back without loosing any data.
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
use coproc.domain_fifo;

entity domain_fifo_tb is
    -- Dual clocked FIFO testbench.
    -- Expected behavior:
    -- Messages shall be transfer with different clock domains.
    type tb_dut is record
        ni_clr : std_logic;
        i_clk_producer  : std_logic;
        i_clk_consumer  : std_logic;

        i_tx            : t_spi_word;
        o_rx            : t_word;

        i_tx_ready      : std_logic;
        i_rx_ready      : std_logic;
        o_tx_ready      : std_logic;
        o_rx_ready      : std_logic; 
    end record;
end entity;

architecture behavioral of domain_fifo_tb is
    signal fifo0 : tb_dut := (
        ni_clr => '1',
        i_clk_producer => '1',
        i_clk_consumer => '1',
        i_tx => (others => '0'),
        o_rx => (others => '0'),
        i_tx_ready => '0',
        i_rx_ready => '0',
        o_tx_ready => '0',
        o_rx_ready => '0' 
    );

    type t_spi_word_array is array (natural range <>) of t_spi_word;

    signal freq1 : real := 1.000e6;    -- Slow clock (10 MHz).
    signal freq2 : real := 10.000e6;   -- Fast clock (100 MHz).
    signal clk1 : std_logic := '1';     -- With frequency of 10 MHz.
    signal clk2 : std_logic := '1';     -- With frequency of 100 MHz.

    signal semaphore0, semaphore1 : std_logic := '0';
begin
    DOMAIN_FIFO_Inst : entity domain_fifo
    generic map (
        g_LENGTH => 64,
        g_INPUT_DATA_SIZE => 8,
        g_OUTPUT_DATA_SIZE => 32
                )
    port map (
        ni_clr => fifo0.ni_clr,
        i_clk_producer => fifo0.i_clk_producer,
        i_clk_consumer => fifo0.i_clk_consumer,
        i_tx => fifo0.i_tx,
        o_rx => fifo0.o_rx,
        i_tx_ready => fifo0.i_tx_ready,
        i_rx_ready => fifo0.i_rx_ready,
        o_tx_ready => fifo0.o_tx_ready,
        o_rx_ready => fifo0.o_rx_ready 
             );

    -- Simulates input clocks from both sides.
    p_EX_CLOCK_1 : tick(clk1, freq1);
    p_EX_CLOCK_2 : tick(clk2, freq2);

    fifo0.i_clk_producer <= clk1;
    fifo0.i_clk_consumer <= clk2;

    -- Main worker on SPI side.
    p_MAIN_SPI : process is 
        variable v_spi_dummy : t_spi_word_array(0 to 15) := (
            x"00", x"01", x"02", x"03", 
            x"04", x"05", x"06", x"07",
            x"08", x"09", x"0A", x"0B",
            x"0C", x"0D", x"0E", x"0F"
        );
    begin
        report "[SPI DOMAIN]: Enter p_MAIN_SPI.";

        wait for 10 ns;

        for i in 0 to v_spi_dummy'length - 1 loop
            if fifo0.o_tx_ready = '0' then
                wait until fifo0.o_tx_ready;
                wait until rising_edge(fifo0.i_clk_producer);
            end if;

            fifo0.i_tx_ready <= '1';
            fifo0.i_tx <= v_spi_dummy(i);
            report "Writing byte: " & to_hstring(v_spi_dummy(i));
            wait until rising_edge(fifo0.i_clk_producer);
            fifo0.i_tx_ready <= '0';
            wait until rising_edge(fifo0.i_clk_producer);
        end loop;

        report "[SPI DOMAIN]: Done: p_MAIN_SPI";
        semaphore0 <= '1';
        wait;
    end process;

    -- Main worker on system side.
    p_MAIN_SYS : process is 
        variable v_sys_dummy : t_word_array(0 to 3) := (others => (others => '0'));
        variable v_sys_check : t_word_array(0 to 3) := (x"03020100", x"07060504", x"0B0A0908", x"0F0E0D0C"); 
    begin
        report "[SYS DOMAIN]: Enter p_MAIN_SYS.";
        
        wait for 10 ns;

        for i in 0 to v_sys_dummy'length - 1 loop
            if fifo0.o_rx_ready = '0' then
                wait until fifo0.o_rx_ready;
                wait until rising_edge(fifo0.i_clk_consumer);
            end if;

            fifo0.i_rx_ready <= '1';
            wait until rising_edge(fifo0.i_clk_consumer);
            wait until rising_edge(fifo0.i_clk_consumer);
            v_sys_dummy(i) := fifo0.o_rx;
            report "Reading word: " & to_hstring(v_sys_dummy(i));
            assert v_sys_dummy(i) = v_sys_check(i)
                report "Obtained word mismatch" severity error;
            fifo0.i_rx_ready <= '0';
            wait until rising_edge(fifo0.i_clk_consumer);
        end loop;

        report "[SYS DOMAIN]: Done: p_MAIN_SYS";
        semaphore1 <= '1';
        wait;
    end process;

    p_END : process begin
        if semaphore0 = '0' then
            wait until semaphore0 = '1';
        end if;
        if semaphore1 = '0' then
            wait until semaphore1 = '1';
        end if;
        report "Done p_END";
        stop_clock(freq1);
        stop_clock(freq2);
        wait;
    end process;
end architecture;
