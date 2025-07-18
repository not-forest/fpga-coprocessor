-- ============================================================
-- File: spi_tb.vhd
-- Desc: testbench for spi slave interface.
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

use coproc.spi_slave;
use coproc.tb.all;
use coproc.intrinsics.all;
use ieee.std_logic_1164.all;

entity spi_tb is
    type tb_dut is record
        in_reset     : std_logic;
        i_cpol       : std_logic;
        i_cpha       : std_logic;
        i_rx_enable  : std_logic;
        i_tx         : t_bus;
        o_rx         : t_bus;
        o_busy       : std_logic;

        i_sclk       : std_logic;
        in_ss        : std_logic;
        i_mosi       : std_logic;
        o_miso       : std_logic;
    end record;
end entity;

architecture behavioral of spi_tb is
    signal sigs : tb_dut := (
        in_reset     => '1',
        i_cpol       => '0',
        i_cpha       => '0',
        i_rx_enable  => '0',
        i_tx         => (others => '0'),
        o_rx         => (others => '0'),
        o_busy       => '0',

        i_sclk       => '0',
        in_ss        => '1',
        i_mosi       => '0',
        o_miso       => '0'
    );

    -- Helper function to convert baud to period.
    function baudToPeriod(baud : real) return time is
    begin
        return 1 sec / baud;
    end function;

    -- Transmit and receive word over SPI (full-duplex)
    procedure transferWord(
        signal s      : inout tb_dut;
        constant tx   : t_bus;
        variable rx   : out t_bus;
        constant baud : real
    ) is
        constant period : time := baudToPeriod(baud);
        variable temp_rx : t_bus := (others => '0');
        constant cpol : std_logic := s.i_cpol;
        constant cpha : std_logic := s.i_cpha;
        constant N : integer := t_bus'length;
    begin
        s.i_sclk <= cpol;
        s.i_mosi <= '0';
        s.in_ss <= '1';
        wait for period;

        s.in_ss <= '0';
        wait for period;

        for i in N-1 downto 0 loop
            if cpha = '0' then
                s.i_mosi <= tx(i);
                s.i_sclk <= not cpol;
                wait for period / 2;
                temp_rx := temp_rx(N-2 downto 0) & s.o_miso;
                s.i_sclk <= cpol;
                wait for period / 2;
            else
                s.i_sclk <= not cpol;
                wait for period / 2;
                s.i_mosi <= tx(i);
                wait for period / 2;
                s.i_sclk <= cpol;
                temp_rx := temp_rx(N-2 downto 0) & s.o_miso;
            end if;
        end loop;

        s.in_ss <= '1';
        s.i_mosi <= '0';
        s.i_sclk <= cpol;
        rx := temp_rx;
        wait for period;
    end procedure;
    
    -- Defines several baud rates for SPI communication.
    signal baud1 : real := 1.000e6;
    signal baud2 : real := 5.000e6;
    signal baud3 : real := 10.000e6;
    signal baud4 : real := 20.000e6;
begin
    -- DUT mapping.
    SPI_Inst : entity spi_slave
    port map (
        in_reset     => sigs.in_reset,
        i_cpol       => sigs.i_cpol,
        i_cpha       => sigs.i_cpha,
        i_rx_enable  => sigs.i_rx_enable,
        i_tx         => sigs.i_tx,
        o_rx         => sigs.o_rx,
        o_busy       => sigs.o_busy,

        i_sclk       => sigs.i_sclk,
        in_ss        => sigs.in_ss,
        i_mosi       => sigs.i_mosi,
        o_miso       => sigs.o_miso
    );

        p_MAIN : process
        variable received : t_bus;
    begin
        report "Enter p_MAIN";

        sigs.in_reset <= '0';
        wait for 100 ns;
        sigs.in_reset <= '1';
        wait for 100 ns;

        sigs.i_tx <= x"AB";
        wait for 20 ns;

        transferWord(sigs, x"55", received, baud1);
        report "Received: " & to_hstring(received);

        sigs.i_tx <= x"F0";
        wait for 50 ns;

        transferWord(sigs, x"0F", received, baud2);
        report "Received: " & to_hstring(received);

        stop_clock(baud1);
        wait;
    end process;
end architecture;