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

        i_tx            : t_word;
        o_rx            : t_word;

        i_tx_ready      : std_logic;
        i_rx_ready      : std_logic;
        o_tx_ready      :  std_logic;
        o_rx_ready      :  std_logic; 
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

    signal fifo1 : tb_dut := (
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

    signal freq1 : real := 10.000e6;    -- Slow clock (10 MHz).
    signal freq2 : real := 100.000e6;   -- Fast clock (100 MHz).
    signal clk1 : std_logic := '1';     -- With frequency of 10 MHz.
    signal clk2 : std_logic := '1';     -- With frequency of 100 MHz.

    -- Dummy messages for assertion.
    type t_dummy is array (natural range 0 to 5) of t_word;
    constant C_DUMMY : t_dummy := (x"AA", x"BB", x"CC", x"DD", x"EE", x"FF");

    -- Waits until the FIFO is not full and writes new data.
    --
    -- Procedure exists the loop when all dummy words are written.
    procedure write_queue (
        variable i_dummy : in t_dummy;
        signal o_queue_tx : out t_word;
        signal o_queue_tx_ready : out std_logic;
        signal i_queue_tx_ready : in std_logic
    ) is begin
        for i in 0 to 5 loop
            if i_queue_tx_ready /= '1' then
                wait until i_queue_tx_ready;
            end if;

            o_queue_tx_ready <= '0';
            o_queue_tx <= i_dummy(i);
            report "Writing word to queue: " & to_hstring(i_dummy(i));
            wait for 1 us;
            o_queue_tx_ready <= '1';
            wait for 1 us;
        end loop;
    end procedure;

    -- Reads the FIFO queue until it is empty.
    procedure read_queue (
        variable o_dummy : out t_dummy;
        signal i_queue_rx : in t_word;
        signal o_queue_rx_ready : out std_logic;
        signal i_queue_rx_ready : in std_logic
    ) is begin
        for i in 0 to 5 loop
            if i_queue_rx_ready /= '1' then
                wait until i_queue_rx_ready;
            end if;
            o_queue_rx_ready <= '1';
            wait for 1 us;
            o_queue_rx_ready <= '0';
            o_dummy(i) := i_queue_rx;
            report "Reading word from queue: " & to_hstring(o_dummy(i));
            wait for 1 us;
        end loop;
    end procedure;

    -- Synchronization semaphore flags (Symulation purposes only).
    signal semaphore0 : std_logic := '0';
    signal semaphore1 : std_logic := '0';
begin
    DF0_Inst : entity domain_fifo
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

    DF1_Inst : entity domain_fifo
    port map (
        ni_clr => fifo1.ni_clr,
        i_clk_producer => fifo1.i_clk_producer,
        i_clk_consumer => fifo1.i_clk_consumer,
        i_tx => fifo1.i_tx,
        o_rx => fifo1.o_rx,
        i_tx_ready => fifo1.i_tx_ready,
        i_rx_ready => fifo1.i_rx_ready,
        o_tx_ready => fifo1.o_tx_ready,
        o_rx_ready => fifo1.o_rx_ready 
             );

    -- Simulates input clocks from both sides.
    p_EX_CLOCK_1 : tick(clk1, freq1);
    p_EX_CLOCK_2 : tick(clk2, freq2);

    fifo0.i_clk_consumer <= clk1;
    fifo0.i_clk_producer <= clk2;
    fifo1.i_clk_consumer <= clk1;
    fifo1.i_clk_producer <= clk2;

    -- Main worker on SPI side.
    p_MAIN_SPI : process is 
        variable v_spi_dummy : t_dummy := C_DUMMY;
    begin
        report "[SPI DOMAIN]: Enter p_MAIN_SPI.";

        report "[SPI DOMAIN]: Sending dummy sequence to the FIFO queue.";
        -- Making sure FIFO0 is not full and synchronizing the first read with our clock.
        write_queue(v_spi_dummy, fifo0.i_tx, fifo0.i_tx_ready, fifo0.o_tx_ready);

        semaphore0 <= '1';
        v_spi_dummy := (others => x"00");
        report "[SPI DOMAIN]: Done sending. Releasing the semaphore, waiting for echo...";

        wait until semaphore1;

        report "[SYS DOMAIN]: Reading echoed sequence from the FIFO queue.";
        
        read_queue(v_spi_dummy, fifo1.o_rx, fifo1.i_rx_ready, fifo1.o_rx_ready);

        -- Checking whether we have obtained proper data from FIFO.
        assert v_spi_dummy = C_DUMMY report "Wrong data obtained from FIFO queue." severity error;

        semaphore0 <= '0';

        report "[SPI DOMAIN]: Done: p_MAIN_SPI";
        stop_clock(freq1);
        wait;
    end process;

    -- Main worker on system side.
    p_MAIN_SYS : process is 
        variable v_sys_dummy : t_dummy := (others => x"00");    -- Starting as 0x00 to be overwritten from system.
    begin
        report "[SYS DOMAIN]: Enter p_MAIN_SYS.";

        wait until semaphore0;  -- Starting to read when whole dummy sequence is written by SPI domain.
        report "[SYS DOMAIN]: Reading dummy sequence from the FIFO queue.";

        read_queue(v_sys_dummy, fifo0.o_rx, fifo0.i_rx_ready, fifo0.o_rx_ready);

        -- Checking whether we have obtained proper data from FIFO.
        assert v_sys_dummy = C_DUMMY report "Wrong data obtained from FIFO queue." severity error;

        report "[SYS DOMAIN]: Echoing obtained sequence back to the FIFO queue.";

        write_queue(v_sys_dummy, fifo1.i_tx, fifo1.i_tx_ready, fifo1.o_tx_ready);

        semaphore1 <= '1';

        wait until semaphore0 = '0';

        report "[SYS DOMAIN]: Done: p_MAIN_SYS";
        stop_clock(freq2);
        wait;
    end process;
end architecture;
