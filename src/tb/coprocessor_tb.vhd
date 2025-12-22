-- ============================================================
-- File: coprocessor_tb.vhd
-- Desc: Testbench for whole coprocessor unit acting as a master microcontroller that communicates with it via
--      SPI interface.
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
use coproc.tb.all;

entity coprocessor_tb is
    type tb_dut is record
        i_clk   : std_logic;
        ni_rst  : std_logic;
        
        i_sclk  : std_logic;
        ni_ss   : std_logic;
        i_mosi  : std_logic;
        io_miso : std_logic;
        o_ready : std_logic;
    end record;
end entity;

architecture behavioral of coprocessor_tb is

    signal sigs : tb_dut := (
        i_clk   => '1',
        ni_rst  => '1',
        i_sclk  => '1',  
        ni_ss   => '1',
        i_mosi  => '0',
        io_miso => 'Z',
        o_ready => '0'
    );

    signal freq1 : real := 50.0e6;  -- SPI clock frequency
    signal freq2 : real := 200.0e6; -- Coprocessor PLL clock frequency

    constant ZERO_PREAMBLE_COUNT : natural := 8;

    type t_spi_word_array is array (natural range <>) of t_spi_word;

    constant SPI_SEQUENCE : t_spi_word_array := (
        x"AA", x"AA",
        x"0D", x"F0",
        x"AD", x"DE",
        x"EF", x"BE",
        x"AF", x"FA",
        x"02", x"00",
        x"02", x"00",
        x"01", x"00",
        x"05", x"00",
        x"00", x"00",
        x"00", x"00",
        x"02", x"00",
        x"07", x"00",
        x"03", x"00",
        x"06", x"00",
        x"00", x"00",
        x"00", x"00",
        x"04", x"00",
        x"08", x"00",
        x"00", x"00",
        x"00", x"00"
    );

    -- Procedure to communicate via SPI (full-duplex).
    procedure spi_transfer_byte (
        signal mosi : out std_logic;
        constant tx : in  t_spi_word;
        variable rx : out t_spi_word
    ) is
    begin
        for i in t_spi_word'length - 1 downto 0 loop
            wait until falling_edge(sigs.i_sclk);
            mosi <= tx(i);  -- Output bit on falling edge (CPHA=1)

            wait until rising_edge(sigs.i_sclk);
            rx(i) := sigs.io_miso; -- Sample bit on rising edge
        end loop;
    end procedure;

    signal clk_stall : std_logic := '1';
begin
    COPROCESSOR_Inst : entity coproc.coprocessor
        generic map (
            g_OMD => 2
        )
        port map (
            i_clk   => sigs.i_clk,
            ni_rst  => sigs.ni_rst,
            i_sclk  => sigs.i_sclk or clk_stall,
            ni_ss   => sigs.ni_ss,
            i_mosi  => sigs.i_mosi,
            io_miso => sigs.io_miso,
            o_ready => sigs.o_ready
        );

    p_EX_CLOCK1 : tick(sigs.i_sclk, freq1); -- SPI clock
    p_EX_CLOCK2 : tick(sigs.i_clk,  freq2); -- system clock

    p_MAIN : process
        variable rx_word : t_spi_word;
    begin
        report "Enter p_MAIN.";

        sigs.ni_rst <= '0';
        wait for 200 ns;
        sigs.ni_rst <= '1';
        wait for 200 ns;

        sigs.ni_ss <= '0';
        wait until rising_edge(sigs.i_sclk);
        clk_stall <= '0';

        -- Just garbage on the line before proper usage.
        for i in 0 to ZERO_PREAMBLE_COUNT - 1 loop
            spi_transfer_byte(sigs.i_mosi, x"00", rx_word);
            report "RX: 0x" & to_hstring(rx_word);
        end loop;

        -- Synchronization sequence + command + data.
        for i in SPI_SEQUENCE'range loop
            if sigs.o_ready = '1' then
                report "READY";
            end if;

            spi_transfer_byte(sigs.i_mosi, SPI_SEQUENCE(i), rx_word);
            report "RX: 0x" & to_hstring(rx_word);
        end loop;

        -- Waiting for ready bit and read data.
        for i in 0 to 8 loop
            if sigs.o_ready = '1' then
                report "READY";
            end if;

            spi_transfer_byte(sigs.i_mosi, x"00", rx_word);
            report "RX: 0x" & to_hstring(rx_word);
        end loop;

        wait until rising_edge(sigs.i_sclk);
        clk_stall <= '1';
        sigs.ni_ss <= '1';
        sigs.i_mosi <= '0';

        report "Done: p_MAIN";

        stop_clock(freq1);
        stop_clock(freq2);
        wait;
    end process;

end architecture;

