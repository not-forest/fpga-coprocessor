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
    port (
        ni_clr          : in std_logic := '1';      -- Asynchronous clear (Active low).
        i_clk_producer  : in std_logic := '1';      -- Internal clock for producer.
        i_clk_consumer  : in std_logic := '1';      -- Internal clock for producer.

        i_tx            : in t_word;
        o_rx            : out t_word;

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

    -- Custom procedure to ensure timing constrains for dual-clocked FIFO interface.
    -- 
    -- Both read and write requests must be asserted for one clock cycle only. This procedure ensures,
    -- that both producer and consumer can hold their READY lines high as long as they won't, because it
    -- will only fire one request per rising edge.
    procedure delta_ready (
        signal i_clk        : in std_logic;     -- Input clock from the required domain.
        signal i_condition  : in std_logic;     -- Condition, under which the request will be asserted together with the request.
        signal i_ready      : in std_logic;     -- Ready request from the domain side.
        signal io_dt        : inout std_logic;  -- Delta logic semaphore to clock requests only for one clock cycle.
        signal o_req        : out std_logic     -- Wire to FIFO's request inputs.
    ) is begin
        if rising_edge(i_clk) then
            -- On each TX ready signal, putting the write request for one clock cycle.
            if ni_clr = '0' then
                o_req <= '0';
                io_dt <= '0';
            else
                o_req <= (i_ready and i_condition and not io_dt);
                io_dt <= i_ready;
            end if;
        end if;
    end procedure;

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
    -- Process for handling producer's and consumer's timing constraints.
    p_PROD_TIMINGS : delta_ready(i_clk_producer, o_tx_ready, i_tx_ready, r_write_dt, r_wrreq);
    p_CONS_TIMINGS : delta_ready(i_clk_consumer, o_rx_ready, i_rx_ready, r_read_dt, r_rdreq);

    -- Sending ready flags straight from FIFO interface.
    o_tx_ready <= not w_wrfull;
    o_rx_ready <= not w_rdempty;

	DCFIFO_Inst : dcfifo
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
