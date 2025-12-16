-- ============================================================
-- File: domain_fifo.vhd
-- Desc: Two dual-clock FIFO queue wrapper used to separate coprocessor's interfaces and internal elements.
--      This element ensures isolation between two different clock domains and provides proper data transfer.
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

entity domain_fifo is
    generic (
        g_LENGTH : natural := 64;                           -- Amount of words the FIFO can hold.
        g_INPUT_DATA_SIZE  : natural := t_spi_word'length;  -- Length of input data.
        g_OUTPUT_DATA_SIZE : natural := t_word'length       -- Length of output data.
            );
    port (
        ni_clr          : in std_logic := '1';      -- Asynchronous clear (Active low).
        i_clk_producer  : in std_logic := '1';      -- Internal clock for producer.
        i_clk_consumer  : in std_logic := '1';      -- Internal clock for producer.

        i_tx            : in std_logic_vector(g_INPUT_DATA_SIZE - 1 downto 0);
        o_rx            : out std_logic_vector(g_OUTPUT_DATA_SIZE - 1 downto 0);

        i_tx_ready      : in std_logic := '0';      -- Producer is ready to send some data to the FIFO.
        i_rx_ready      : in std_logic := '0';      -- Consumer is ready to get some data from the FIFO.
        o_tx_ready      : buffer std_logic;         -- FIFO is ready to obtain new data (not full.)
        o_rx_ready      : buffer std_logic          -- FIFO is ready to send some data (not empty.)
    );
end entity;

architecture vendor of domain_fifo is
    -- Handshake Communication Wires.
    signal r_wrreq      : std_logic := '0';
    signal r_rdreq      : std_logic := '0';
    signal w_wrfull     : std_logic := '0';
    signal w_rdempty    : std_logic := '0';

    signal r_write_dt : std_logic := '0';       -- Delta logic semaphore to lock write requests only for one clock cycle. 
    signal r_read_dt : std_logic := '0';        -- Delta logic semaphore to lock read requests only for one clock cycle. 

    -- Vendor specific dual-clock FIFO. This entity uses two such queues to provide duplex communication.
	component dcfifo_mixed_widths
	generic (
		intended_device_family		: string;
		lpm_hint		            : string;
		lpm_numwords		        : natural;
		lpm_showahead		        : string;
		lpm_type		            : string;
		lpm_width		            : natural;
		lpm_width_r 	            : natural;
		lpm_widthu		            : natural;
		lpm_widthu_r	            : natural;
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
			data : in std_logic_vector(g_INPUT_DATA_SIZE - 1 downto 0);
			rdclk : in std_logic ;
			rdreq : in std_logic ;
			wrclk : in std_logic ;
			wrreq : in std_logic ;
			q : out std_logic_vector(g_OUTPUT_DATA_SIZE - 1 downto 0);
			rdempty : out std_logic ;
			wrfull : out std_logic 
	);
	end component;
begin 
    -- Process for handling producer's and consumer's timing constraints.
    p_PROD_TIMINGS : delta_ready(ni_clr, i_clk_producer, o_tx_ready, i_tx_ready, r_write_dt, r_wrreq);
    p_CONS_TIMINGS : delta_ready(ni_clr, i_clk_consumer, o_rx_ready, i_rx_ready, r_read_dt, r_rdreq);

    -- Sending ready flags straight from FIFO interface.
    o_tx_ready <= not w_wrfull;
    o_rx_ready <= not w_rdempty;

	DCFIFO_Inst : dcfifo_mixed_widths
	GENERIC MAP (
		intended_device_family => "Cyclone IV E",
		lpm_hint => "RAM_BLOCK_TYPE=M9K",
		lpm_numwords => g_LENGTH,
		lpm_showahead => "OFF",
		lpm_type => "dcfifo_mixed_widths",
		lpm_width => g_INPUT_DATA_SIZE,
		lpm_width_r => g_OUTPUT_DATA_SIZE,
		lpm_widthu => log2(g_LENGTH),
		lpm_widthu_r => log2(g_LENGTH * g_INPUT_DATA_SIZE / g_OUTPUT_DATA_SIZE),
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
		data => i_tx,
        q => o_rx,
		rdclk => i_clk_consumer,
		wrclk => i_clk_producer,

        rdreq => r_rdreq,
		wrreq => r_wrreq,
		rdempty => w_rdempty,
		wrfull => w_wrfull
	);
end architecture;
