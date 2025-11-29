-- ============================================================
-- File: avalon_serializer.vhd
-- Desc: Avalon MM Slave interface wrapper for serializer component. Only acts as a bridge from platform designer environment
--      to hardware part.
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
use ieee.numeric_std.all;
use coproc.intrinsics.all;

entity avalon_serializer is
    port (
        i_clk   : in std_logic;                 -- Input clock (NIOS Domain). Required by avalon interface.
        ni_clr  : in std_logic;                 -- Synchronous reset (Active Low). Required by avalon inteface.
        
        -- Avalon-MM Slave interface
        av_address      : in  std_logic_vector(0 to 0); -- Ignored since writes only change `iterations` register value.
        av_write        : in  std_logic;                -- Writes new iterations value and clears the internal state machine.
        av_read         : in  std_logic;                -- Read flag.
        av_writedata    : in  t_niosv_word;             -- Must be a proper value of iterations. Also equal to input matrix dimension.
        av_readdata     : out t_niosv_word;             -- Obtains output from serializer.
        av_waitrequest  : out std_logic;                -- Only when FIFO is not empty.

        -- Exported conduits.
        o_clr               : out std_logic;        -- Connected to real component via av_write
        o_iterations        : out t_niosv_word;     -- Amount of iterations before serializer shall begin sampling.
        o_iterations_write  : out std_logic;        -- Writes new amount of iterations. 
        o_rx_ready          : out std_logic;        -- Signal to enable read from internal FIFO. 
        i_rx_ready          : in std_logic;         -- Signal to check whether internal FIFO is ready to be read.
        i_acc               : in t_niosv_word       -- Input accumulator data from real component.
    );
end entity;

architecture avalon of avalon_serializer is
begin
    o_rx_ready <= av_read when i_rx_ready = '1' else '0';   -- Setting read signal only when FIFO is ready.
    o_iterations_write <= av_write;                         -- Iterations are written when write command is used. 
    o_iterations <= av_writedata;                           
    av_waitrequest <= not i_rx_ready;                       -- When FIFO is empty, blocking wait request.
    av_readdata <= i_acc;                                   -- Reads each next accumulator value from the FIFO.
    o_clr <= av_write;                                      -- Writes also reset the internal state machine.
end architecture;
