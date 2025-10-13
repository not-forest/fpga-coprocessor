-- ============================================================
-- File: pe_fifo.vhd
-- Desc: Regular FIFO queue used to feed rows and columns of systolic array.
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

use ieee.std_logic_1164.all;
use coproc.intrinsics.all;
use altera_mf.all;

entity pe_fifo is
    generic (
        g_BLOCK_SIZE : natural := 16                -- Size of PE batch block equals to FIFO length.
    );
    port (
        na_clr : in std_logic := '1';
        i_clk : in std_logic := '1';  
        
        i_data : in t_word := (others => '0');
        o_data : out t_word;

        i_tx_ready      : in std_logic := '0';      -- Producer is ready to send some data to the FIFO.
        i_rx_ready      : in std_logic := '0';      -- Consumer is ready to get some data from the FIFO.
        o_tx_ready      : buffer std_logic;         -- FIFO is ready to obtain new data (not full.)
        o_rx_ready      : buffer std_logic          -- FIFO is ready to send some data (not empty.)
    );
end entity;

architecture vendor of pe_fifo is
    signal r_wrreq      : std_logic := '0';
    signal r_rdreq      : std_logic := '0';
    signal w_wrfull     : std_logic := '0';
    signal w_rdempty    : std_logic := '0';

    signal r_write_dt : std_logic := '0';       -- Delta logic semaphore to lock write requests only for one clock cycle. 
    signal r_read_dt : std_logic := '0';        -- Delta logic semaphore to lock read requests only for one clock cycle. 

    component scfifo is
	generic (
		add_ram_output_register		: string;
		intended_device_family		: string;
		lpm_hint		            : string;
		lpm_numwords		        : natural;
		lpm_showahead		        : string;
		lpm_type		            : string;
		lpm_width		            : natural;
		lpm_widthu		            : natural;
		overflow_checking		    : string;
		underflow_checking		    : string;
		use_eab		                : string
	);
	port (
		clock	: in std_logic;
		data	: in t_word;
		rdreq	: in std_logic;
		wrreq	: in std_logic;
        aclr    : in std_logic;
		empty	: out std_logic;
		full	: out std_logic;
		q	    : out t_word;
		usedw	: out t_word
	);
    end component;
begin
    -- Process for handling producer's and consumer's timing constraints.
    p_PROD_TIMINGS : delta_ready(na_clr, i_clk, o_tx_ready, i_tx_ready, r_write_dt, r_wrreq);
    p_CONS_TIMINGS : delta_ready(na_clr, i_clk, o_rx_ready, i_rx_ready, r_read_dt, r_rdreq);

    -- Sending ready flags straight from FIFO interface.
    o_tx_ready <= not w_wrfull;
    o_rx_ready <= not w_rdempty;

	SCFIFO_Inst : scfifo
	GENERIC MAP (
		add_ram_output_register => "ON",
		intended_device_family => "Cyclone IV E",
		lpm_hint => "RAM_BLOCK_TYPE=M9K",
		lpm_numwords => g_BLOCK_SIZE,
		lpm_showahead => "OFF",
		lpm_type => "scfifo",
		lpm_width => t_word'length,
		lpm_widthu => t_word'length,
		overflow_checking => "OFF",
		underflow_checking => "OFF",
		use_eab => "ON"
	)
	PORT MAP (
		clock => i_clk,
        aclr => not na_clr,
		data => i_data,
		rdreq => r_rdreq,
		wrreq => r_wrreq,
		empty => w_rdempty,
		full => w_wrfull,
		q => o_data,
		usedw => open
	);
end architecture;
