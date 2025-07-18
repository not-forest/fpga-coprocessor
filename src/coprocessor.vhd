-- ============================================================
-- File: coprocessor.vhd
-- Desc: Top level entity of the FPGA Coprocessor implementation. Coprocessor allows to handle a parallel inputs of
--  N-bit values, defined by g_BUS_WIDTH generic, which are shifted to the systolic array for further computations.
--  The selected operation is defined by the first entry word, which also define the size of matrixes and it's type.
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
use coproc.systolic_arr;
use coproc.spi_slave;
use coproc.pll;

entity coprocessor is
    port (
        i_clk       : in std_logic := '0';              -- External FPGA Oscillator.
        i_rst       : in std_logic := '0';              -- Hard reset button.
        
        i_sclk       : in  std_logic;                   -- SPI clock
        in_ss        : in  std_logic;                   -- Slave select (active low)
        i_mosi       : in  std_logic;                   -- Master Out Slave In
        o_miso       : out std_logic                    -- Master In Slave Out
         );
end entity;

architecture structured of coprocessor is
    signal w_clk : std_logic := '1';                    -- PLL clock wire signal.
begin
    -- Global coprocessor clock source.
    PLL_Inst : entity pll
    port map(
        i_clk0 => i_clk,
        ni_sleep => '1',
        o_clk0 => open,
        o_clk1 => open,
        o_clk2 => o_cstatus(0)
    );

    -- SPI slave module acting as an interface between coprocessor and master microcontroller.
    SPI_Inst : entity spi_slave
    port map (
        in_reset     => open,
        i_cpol       => open,
        i_cpha       => open,
        i_rx_enable  => open,
        i_tx         => open,
        o_rx         => open,
        o_busy       => open,

        i_sclk       => i_sclk,
        in_ss        => in_ss,
        i_mosi       => i_mosi,
        o_miso       => o_miso
    );
end architecture;
