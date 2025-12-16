-- ============================================================
-- File: spi.vhd
-- Desc: SPI Slave to Avalon-ST interface based IP wrapper.
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
library altera_mf;

use coproc.intrinsics.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use altera_mf.all;

entity spi_slave is
	port (
		i_stsinkvalid       : in std_logic                    := '0';   --   avalon_streaming_sink.valid
		i_stsinkdata        : in t_spi_word := (others => '0');             --                        .data
		o_stsinkready       : out std_logic;                            --                        .ready
		i_stsourceready     : in std_logic                    := '0';   -- avalon_streaming_source.ready
		o_stsourcevalid     : out std_logic;                            --                        .valid
		o_stsourcedata      : out t_spi_word := (others => '0');        --                        .data
		i_sysclk            : in std_logic                    := '0';   --              clock_sink.clk
		i_nreset            : in std_logic                    := '0';   --        clock_sink_reset.reset_n
		i_mosi              : in std_logic                    := '0';   --                export_0.mosi
		i_nss               : in std_logic                    := '0';   --                        .nss
		io_miso             : inout std_logic                 := '0';   --                        .miso
		i_sclk              : in std_logic                    := '0'    --                        .sclk
	);
end entity;

architecture vendor of spi_slave is
	component SPIPhy is
		generic (
			SYNC_DEPTH : integer := 2
		);
		port (
			sysclk        : in    std_logic                    := 'X';             -- clk
			nreset        : in    std_logic                    := 'X';             -- reset_n
			mosi          : in    std_logic                    := 'X';             -- export
			nss           : in    std_logic                    := 'X';             -- export
			miso          : inout std_logic                    := 'X';             -- export
			sclk          : in    std_logic                    := 'X';             -- export
			stsourceready : in    std_logic                    := 'X';             -- ready
			stsourcevalid : out   std_logic;                                       -- valid
			stsourcedata  : out   std_logic_vector(7 downto 0);                    -- data
			stsinkvalid   : in    std_logic                    := 'X';             -- valid
			stsinkdata    : in    std_logic_vector(7 downto 0) := (others => 'X'); -- data
			stsinkready   : out   std_logic                                        -- ready
		);
	end component SPIPhy;
begin
	SPIPHY_Inst : component SPIPhy
		generic map (
			SYNC_DEPTH => 3
		)
		port map (
			sysclk        => i_sysclk,        --              clock_sink.clk
			nreset        => i_nreset,        --        clock_sink_reset.reset_n
			mosi          => i_mosi,          --                export_0.export
			nss           => i_nss,           --                        .export
			miso          => io_miso,         --                        .export
			sclk          => i_sclk,          --                        .export
			stsourceready => i_stsourceready, -- avalon_streaming_source.ready
			stsourcevalid => o_stsourcevalid, --                        .valid
			stsourcedata  => o_stsourcedata,  --                        .data
			stsinkvalid   => i_stsinkvalid,   --   avalon_streaming_sink.valid
			stsinkdata    => i_stsinkdata,    --                        .data
			stsinkready   => o_stsinkready    --                        .ready
		);
end architecture;
