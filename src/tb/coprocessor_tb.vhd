-- ============================================================
-- File: coprocessor_tb.vhd
-- Desc: Testbench for whole coprocessor unit acting as a master microcontroller that communicates with it via
--      SPI interface. The below code tests different coprocessor commands with different data size.
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

    -- 2x2 matrix multiplication. (Compatible with g_OMD >= 2):
    --
    -- | 1  2 | X | 5  6 | = | 19  43 |
    -- | 3  4 |   | 7  8 |   | 22  50 |
    constant c_COPROC_MULT_2X2 : t_word_array := (
        -- Synchronization / Header
        x"AAAA", x"F00D", x"DEAD", x"BEEF", 
        -- Command words.
        x"FAAF", x"0002", x"0002", 
        -- Payload.
        x"0000", x"0000", 
        x"0001", x"0005", 
        x"0003", x"0006", 
        x"0002", x"0007",
        x"0004", x"0008", 
        x"0000", x"0000", 
        -- +1 Padding.
        x"0000", x"0000"
    );

    -- 1x4 * 4x1 matrix multiplication. (Compatible with g_OMD >= 1);
    --                  | 255 |
    -- | 1  1  1  1 | X | 255 | = | 1020 |
    --                  | 255 |
    --                  | 255 |
    constant c_COPROC_MULT_4X1X4 : t_word_array := (
        -- Synchronization / Header
        x"AAAA", x"F00D", x"DEAD", x"BEEF", 
        -- Command words.
        x"FAAF", x"0004", x"0001", 
        -- Payload.
        x"0001", x"00FF",
        x"0001", x"00FF",
        x"0001", x"00FF",
        x"0001", x"00FF",
        -- +1 Padding.
        x"0000", x"0000"
    );

    -- 3x3 matrix multiplication. (Compatible with g_OMD >= 3):
    --
    -- | 1  2  3 |   | 1  0  0 |   | 1  2  3 |
    -- | 4  5  6 | X | 0  1  0 | = | 4  5  6 |
    -- | 7  8  9 |   | 0  0  1 |   | 7  8  9 |
    constant c_COPROC_MULT_3X3 : t_word_array := (
        -- Synchronization / Header
        x"AAAA", x"F00D", x"DEAD", x"BEEF", 
        -- Command words.
        x"FAAF", x"0003", x"0003", 
        -- Payload number one..
        x"0000", x"0000",
        x"0000", x"0000",
        x"0001", x"0001",
        x"0000", x"0000",
        x"0004", x"0000",
        x"0002", x"0000",
        x"0007", x"0000",
        x"0005", x"0001",
        x"0003", x"0000",
        x"0008", x"0000",
        x"0006", x"0000",
        x"0000", x"0000",
        x"0009", x"0001",
        x"0000", x"0000",
        x"0000", x"0000",

        -- Payload number two..
        x"0000", x"0000",
        x"0000", x"0000",
        x"0001", x"0001",
        x"0000", x"0000",
        x"0004", x"0000",
        x"0002", x"0000",
        x"0007", x"0000",
        x"0005", x"0001",
        x"0003", x"0000",
        x"0008", x"0000",
        x"0006", x"0000",
        x"0000", x"0000",
        x"0009", x"0001",
        x"0000", x"0000",
        x"0000", x"0000",
        
        -- +1 Padding.
        x"0000", x"0000"
    );

    -- Procedure to communicate via SPI (full-duplex) for CPHA=1, CPOL=1.
    procedure spi_transfer_byte (
        signal sclk     : in  std_logic;
        signal miso     : in  std_logic;
        signal mosi     : out std_logic;
        constant tx     : in  t_spi_word;
        variable rx     : out t_spi_word
    ) is
    begin
        for i in t_spi_word'length - 1 downto 0 loop
            wait until falling_edge(sclk);
            mosi <= tx(i);

            wait until rising_edge(sclk);
            rx(i) := miso;
        end loop;
    end procedure;

    -- Helper procedure to produce one proper SPI communication cycle.
    procedure run_coproc_test (
        constant words       : in  t_word_array;
        constant timeout     : in  natural;
        signal ss_line       : out std_logic;
        signal stall_line    : out std_logic;
        signal mosi_line     : out std_logic;
        signal sclk_line     : in  std_logic;
        signal miso_line     : inout  std_logic;
        signal ready_flag    : in  std_logic
    ) is
        variable rx_byte : t_spi_word := (others => '0');
        variable tx_byte : t_spi_word := (others => '0');
    begin
        wait until rising_edge(sclk_line);
        ss_line <= '0';
        stall_line <= '0';

        -- Synchronization sequence + command + data.
        for i in words'range loop
            if ready_flag = '1' then
                report "READY";
            end if;

            -- Low Byte
            tx_byte := words(i)(7 downto 0);
            spi_transfer_byte(sclk_line, miso_line, mosi_line, tx_byte, rx_byte);
            report to_hstring(rx_byte);

            if ready_flag = '1' then
                report "READY";
            end if;

            -- High Byte
            tx_byte := words(i)(15 downto 8);
            spi_transfer_byte(sclk_line, miso_line, mosi_line, tx_byte, rx_byte); 
            report to_hstring(rx_byte);
        end loop;

        -- Slack timeout.
        for i in 0 to timeout loop
            if ready_flag = '1' then
                report "READY";
            end if;

            spi_transfer_byte(sclk_line, miso_line, mosi_line, x"00", rx_byte);
            report to_hstring(rx_byte);
        end loop;

        ss_line <= '1';
        mosi_line <= '0';
        stall_line <= '1';
        wait until rising_edge(sclk_line);
    end procedure;

    signal clk_stall : std_logic := '1';
begin
    COPROCESSOR_Inst : entity coproc.coprocessor
        generic map (
            g_OMD => 3
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
    begin
        report "Enter p_MAIN.";

        sigs.ni_rst <= '0';
        wait for 200 ns;
        sigs.ni_rst <= '1';
        wait for 200 ns;

        report "MULT 2x2";
        -- 2x2 multiplication.
        run_coproc_test(
            words       => c_COPROC_MULT_2X2,
            timeout     => 8,
            ss_line     => sigs.ni_ss,
            stall_line  => clk_stall,
            mosi_line   => sigs.i_mosi,
            sclk_line   => sigs.i_sclk,
            miso_line   => sigs.io_miso,
            ready_flag  => sigs.o_ready
        );

        wait for 100 ns;

        report "MULT 2x2";
        -- 2x2 multiplication.
        run_coproc_test(
            words       => c_COPROC_MULT_4X1X4,
            timeout     => 0,
            ss_line     => sigs.ni_ss,
            stall_line  => clk_stall,
            mosi_line   => sigs.i_mosi,
            sclk_line   => sigs.i_sclk,
            miso_line   => sigs.io_miso,
            ready_flag  => sigs.o_ready
        );

        wait for 100 ns;

        report "MULT 3x3 (Pipelined X2)";
        -- 3x3 multiplication.
        run_coproc_test(
            words       => c_COPROC_MULT_3X3,
            timeout     => 48,
            ss_line     => sigs.ni_ss,
            stall_line  => clk_stall,
            mosi_line   => sigs.i_mosi,
            sclk_line   => sigs.i_sclk,
            miso_line   => sigs.io_miso,
            ready_flag  => sigs.o_ready
        );

        report "Done: p_MAIN";

        stop_clock(freq1);
        stop_clock(freq2);
        wait;
    end process;
end architecture;
