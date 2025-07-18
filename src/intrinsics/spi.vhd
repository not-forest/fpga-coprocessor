-- ============================================================
-- File: spi.vhd
-- Desc: SPI slave interface implementation for comunicating with master microcontroller.
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
use ieee.std_logic_arith.all;
use coproc.intrinsics.all;

entity spi_slave is
    port (
        in_reset     : in  std_logic;                   -- Asynchronous active-low reset
        i_cpol       : in  std_logic;                   -- Clock polarity mode
        i_cpha       : in  std_logic;                   -- Clock phase mode
        i_sclk       : in  std_logic;                   -- SPI clock
        in_ss        : in  std_logic;                   -- Slave select (active low)
        i_mosi       : in  std_logic;                   -- Master Out Slave In
        o_miso       : out std_logic;                   -- Master In Slave Out
        i_rx_enable  : in  std_logic;                   -- Enable signal to wire rxbuffer to outside
        i_tx         : in  t_bus;                       -- Data to transmit
        o_rx         : out t_bus := (others => '0');    -- Data received
        o_busy       : out std_logic := '0'             -- Slave busy signal
    );
end spi_slave;

architecture rtl of spi_slave is
    signal mode         : std_logic;                                 -- According to CPOL and CPHA
    signal internal_clk : std_logic;
    signal bit_counter  : integer range 0 to t_bus'length := 0;      -- Bit counter
    signal rxbuffer     : t_bus := (others => '0');
    signal txbuffer     : t_bus := (others => '0');
begin
    o_busy <= not in_ss;

    mode <= i_cpol xor i_cpha;

    -- Generate internal clock depending on SPI mode
    process (mode, in_ss, i_sclk)
    begin
        if in_ss = '1' then
            internal_clk <= '0';
        else
            if mode = '1' then
                internal_clk <= i_sclk;
            else
                internal_clk <= not i_sclk;
            end if;
        end if;
    end process;

    -- Bit counter
    process (in_ss, internal_clk)
    begin
        if in_ss = '1' or in_reset = '0' then
            bit_counter <= 0;
        elsif rising_edge(internal_clk) then
            if bit_counter < t_bus'length then
                bit_counter <= bit_counter + 1;
            end if;
        end if;
    end process;

    -- Receive/transmit logic
    process (in_ss, internal_clk, i_rx_enable, in_reset)
    begin
        -- Receive MOSI
        if in_reset = '0' then
            rxbuffer <= (others => '0');
        elsif falling_edge(internal_clk) and bit_counter < t_bus'length then
            rxbuffer <= rxbuffer(t_bus'length - 2 downto 0) & i_mosi;
        end if;

        -- Output received data
        if in_reset = '0' then
            o_rx <= (others => '0');
        elsif in_ss = '1' and i_rx_enable = '1' then
            o_rx <= rxbuffer;
        end if;

        -- Load TX register or shift it
        if in_reset = '0' then
            txbuffer <= (others => '0');
        elsif in_ss = '1' then
            txbuffer <= i_tx;
        elsif rising_edge(internal_clk) and bit_counter < t_bus'length then
            txbuffer <= txbuffer(t_bus'length - 2 downto 0) & txbuffer(t_bus'length - 1);
        end if;

        -- Drive MISO
        if in_ss = '1' or in_reset = '0' then
            o_miso <= 'Z';
        elsif rising_edge(internal_clk) then
            o_miso <= txbuffer(t_bus'length - 1);
        end if;
    end process;
end architecture;