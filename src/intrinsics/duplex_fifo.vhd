-- ============================================================
-- File: dcfifo.vhd
-- Desc: Two dual-clock FIFO queues used to separate coprocessor's SPI interface and internal elements.
--      This element ensures isolation between two areas with different clock frequencies, and ensures that
--      data is being forwarded properly in both direction.
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

library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.all;

library coproc;
use coproc.intrinsics.all;

entity duplex_fifo is
    port (
        ni_clr : in std_logic := '1',    -- Asynchronous clear (Active low).
        -- SPI domain.
        i_clk_spi       : in std_logic := '1', -- SPI clock input.
        i_spi_rx_ready  : in std_logic := '0', -- Set high as soon as SPI reads first word.
        i_spi_tx_ready  : in std_logic := '0', -- Set high when SPI's master starts clocking out bits.
        i_rx_spi        : in t_word,           -- Data from SPI RX
        o_tx_spi        : out t_word,          -- Data to SPI TX.

        -- System domain.
        i_clk_sys       : in std_logic := '1', -- System clock input. Shall be the same as the internall PLL.
        i_sys_rx_ready  : in std_logic := '0', -- Set high when systolic array is ready to consume next byte.
        i_sys_tx_ready  : in std_logic := '0', -- Set high when systolic array produces a result word.
        o_rx_sys        : out t_word,          -- Data to system RX.
        i_tx_sys        : in t_word            -- Data from system TX.

    );
end entity;

architecture vendor of duplex_fifo is
    -- Handshake Communication Wires.
    signal w_wrreq_rx, w_wrreq_tx : std_logic := '0';
    signal w_rdreq_rx, w_rdreq_tx : std_logic := '0';
    signal w_wrfull_rx, w_wrfull_tx : std_logic := '0';
    signal w_rdempty_rx, w_rdempty_tx : std_logic := '0';

    -- Vendor specific dual-clock FIFO. This entity uses two such queues to provide duplex communication.
	component dcfifo
	generic (
		intended_device_family		: string;
		lpm_hint		            : string;
		lpm_numwords		        : natural;
		lpm_showahead		        : string;
		lpm_type		            : string;
		lpm_width		            : natural;
		lpm_widthu		            : natural;
		overflow_checking		    : string;
		rdsync_delaypipe		    : natural;
		read_aclr_synch		        : string;
		underflow_checking		    : string;
		use_eab		                : string;
		write_aclr_synch		    : string;
		wrsync_delaypipe		    : natural
	);
	port (
			aclr : in std_logic ;
			data : in t_word;
			rdclk : in std_logic ;
			rdreq : in std_logic ;
			wrclk : in std_logic ;
			wrreq : in std_logic ;
			q : out t_word;
			rdempty : out std_logic ;
			wrfull : out std_logic 
	);
	end component;
begin 
    w_wrreq_rx <= '1' when w_wrfull_rx & i_spi_rx_ready = "01" else '0';
    w_rdreq_rx <= '1' when w_rdempty_rx & i_sys_rx_ready = "01" else '0';

    -- One way FIFO RX (SPI -> System)
	DCFIFO_Inst0 : dcfifo
	GENERIC MAP (
		intended_device_family => "Cyclone IV E",
		lpm_hint => "RAM_BLOCK_TYPE=M9K",
		lpm_numwords => 512,
		lpm_showahead => "OFF",
		lpm_type => "dcfifo",
		lpm_width => 8,
		lpm_widthu => 9,
        rdsync_delaypipe => 4,
        wrsync_delaypipe => 4,
        use_eab => "ON",
		overflow_checking => "ON",
		read_aclr_synch => "OFF",
		underflow_checking => "ON",
		write_aclr_synch => "OFF"
	)
	PORT MAP (
		aclr => not ni_clr,
		data => i_rx_spi,
		rdclk => i_clk_sys,
		rdreq => w_rdreq_rx,
		wrclk => i_clk_spi,
		wrreq => w_wrreq_rx,
		q => o_rx_sys,
		rdempty => w_rdempty_rx,
		wrfull => w_wrfull_rx
	);

    w_wrreq_tx <= '1' when w_wrfull_tx & i_sys_tx_ready = "01" else '0';
    w_rdreq_tx <= '1' when w_rdempty_tx & i_spi_tx_ready = "01" else '0';

    -- One way FIFO TX (System -> SPI)
	DCFIFO_Inst1 : dcfifo
	GENERIC MAP (
		intended_device_family => "Cyclone IV E",
		lpm_hint => "RAM_BLOCK_TYPE=M9K",
		lpm_numwords => 512,
		lpm_showahead => "OFF",
		lpm_type => "dcfifo",
		lpm_width => 8,
		lpm_widthu => 9,
        rdsync_delaypipe => 4,
        wrsync_delaypipe => 4,
        use_eab => "ON",
		overflow_checking => "ON",
		read_aclr_synch => "OFF",
		underflow_checking => "ON",
		write_aclr_synch => "OFF"
	)
	PORT MAP (
		aclr => not ni_clr,
		data => i_tx_sys,
		rdclk => i_clk_spi,
		rdreq => w_rdreq_tx,
		wrclk => i_clk_sys,
		wrreq => w_wrreq_tx,
		q => o_tx_spi,
		rdempty => w_rdempty_tx,
		wrfull => w_wrfull_tx
	);
end architecture;
