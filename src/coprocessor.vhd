-- ============================================================
-- File: coprocessor.vhd
-- Desc: Top level entity of the FPGA Coprocessor implementation.
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
library coproc_soft_cpu;
library ieee;

use ieee.std_logic_1164.all;
use coproc.intrinsics.all;
use coproc_soft_cpu.all;

entity coprocessor is
    port (
        i_clk       : in std_logic := '0';            -- Stable PLL clock input.
        ni_rst      : in std_logic := '1';            -- Hard reset signal.
        
        i_sclk      : in  std_logic;                  -- SPI clock
        ni_ss       : in  std_logic;                  -- Slave select (active low)
        i_mosi      : in  std_logic;                  -- Master Out Slave In
        o_miso      : inout std_logic                 -- Master In Slave Out
         );
end entity;

architecture structured of coprocessor is 
    component coproc_soft_cpu is
        port (
            i_clk_clk                                                    : in    std_logic := '0';
            i_clr_reset_n                                                : in    std_logic := '0';
            o_spi_export_mosi_to_the_spislave_inst_for_spichain          : in    std_logic := '0';
            o_spi_export_nss_to_the_spislave_inst_for_spichain           : in    std_logic := '0';
            o_spi_export_miso_to_and_from_the_spislave_inst_for_spichain : inout std_logic := '0';
            o_spi_export_sclk_to_the_spislave_inst_for_spichain          : in    std_logic := '0' 
        );
    end component;
begin
    -- Generating internal NIOS2 V/m soft CPU core to parse upcoming SPI traffic
    COPROC_SOFT_CPU_Inst : coproc_soft_cpu
    port map (
        i_clk_clk => i_clk,
        i_clr_reset_n => not ni_rst,
        o_spi_export_nss_to_the_spislave_inst_for_spichain => ni_ss,
        o_spi_export_sclk_to_the_spislave_inst_for_spichain => i_sclk,
        o_spi_export_mosi_to_the_spislave_inst_for_spichain => i_mosi,
        o_spi_export_miso_to_and_from_the_spislave_inst_for_spichain => o_miso
             );
end architecture;
