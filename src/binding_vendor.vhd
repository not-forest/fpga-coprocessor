-- ============================================================
-- File: binding_vendor.vhd
-- Desc: Additional bindings to the FPGA board. This module separates overall design from vendor-specific software/
--      configuration/structures.
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
use coproc.intrinsics.all;
use coproc.coprocessor;
use coproc.pll;

entity binding_vendor is
    port (
        i_pCLK        : in std_logic;               -- External FPGA Oscillator.
        ni_pRST       : in std_logic;               -- Hard reset button (Active Low).
        
        i_pSCLK       : in  std_logic;              -- SPI clock
        ni_pSS        : in  std_logic;              -- Slave select (active low)
        i_pMOSI       : in  std_logic;              -- Master Out Slave In
        o_pMISO       : out std_logic               -- Master In Slave Out
         );
end entity;

architecture structured of binding_vendor is
    signal w_clk50MHz  : std_logic := '1';          -- Lowest 50 MHz clock.
    signal w_clk100MHz : std_logic := '1';          -- Moderate frequency used for NIOS V Core.
    signal w_clk475Mhz : std_logic := '1';          -- Fastest 475 MHz clock.
begin
    -- Global coprocessor clock source.
    PLL_Inst : entity pll
    port map(
        i_clk0 => i_pCLK,
        i_rst => not ni_pRST,
        o_clk0 => open,
        o_clk1 => w_clk100MHz,
        o_clk2 => w_clk475Mhz
    );

    -- SPI slave module acting as an interface between coprocessor and master microcontroller.
    COPROCESSOR_Inst : entity coprocessor
    port map(
        i_clk  => w_clk100MHz,
        ni_rst => ni_pRST,
        
        i_sclk => i_pSCLK,
        ni_ss  => ni_pSS,
        i_mosi => i_pMOSI,
        o_miso => o_pMISO
    );
end architecture;
