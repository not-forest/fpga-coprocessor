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
use ieee.numeric_std.all;

entity coprocessor is
    generic (
        g_OMD       : natural := 8              -- Operating matrix dimensions.
    );
    port (
        i_clk       : in std_logic := '0';      -- Stable PLL clock input.
        ni_rst      : in std_logic := '1';      -- Hard reset signal.
        
        i_sclk      : in  std_logic;            -- SPI clock
        ni_ss       : in  std_logic;            -- Slave select (active low)
        i_mosi      : in  std_logic;            -- Master Out Slave In
        o_miso      : out std_logic             -- Master In Slave Out
         );
end entity;

architecture structured of coprocessor is 
begin
    SPI_SLAVE_Inst : entity coproc.spi_slave
    port map (
		i_stsinkvalid => ,
		i_stsinkdata => ,
		o_stsinkready => ,
		i_stsourceready => ,
		o_stsourcevalid => ,
		o_stsourcedata => ,
		i_sysclk => ,
		i_nreset => ,
		i_mosi => ,
		i_nss => ,
		io_miso => ,
		i_sclk => ,
             );

    --SYSTOLIC_ARR_Inst : entity systolic_arr
    --generic map (
    --    g_OMD => g_OMD
    --            )
    --port map (
    --    ni_clr => ni_rst,
    --    i_clk => i_clk,
    --    i_write => open,
    --
    --    i_se_clr => open,
    --    i_se_iterations => open,
    --    i_se_iterations_write => open,

    --    i_rx_ready => open,
    --    o_rx_ready => open,

    --    i_dataX => open,
    --    i_dataW => open,
    --    o_dataA => open
    --         );
end architecture;
