-- ============================================================
-- File: tb.vhd
-- Desc: General test bench bindings and data types. 
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

-- Defines different data types for writing test benches.
package tb is
    -- Custom clock type for testbench simulations.
    subtype t_clock is std_logic;

    -- Function to wrap an input integer to 32-bit word format.
    function w(x : integer) return t_word;

    -- Provides a constant simulation of clock ticks with certain frequency --
    procedure tick (signal clk : inout t_clock; signal freq : in real);
    -- Stops the clock with given frequency.
    procedure stop_clock(signal freq : out real); 
end package;

package body tb is
    -- Function to wrap an input integer to 32-bit word format.
    function w(x : integer) return t_word is begin
        return t_word(to_unsigned(x, 32));
    end function;

    -- Provides a constant simulation of clock ticks with certain frequency --
    procedure tick (
        signal clk      : inout t_clock;  -- This signal will simulate the clock behavior.
        signal freq     : in real         -- Clock's frequency. 
    ) is
    begin
        if freq /= 0.0 then
            clk <= not clk after (1 sec / freq) / 2;
        else
            wait;
        end if;
    end procedure;

    procedure stop_clock(
        signal freq     : out real        -- Clock's frequency.
    ) is 
    begin
        freq <= 0.0;
    end procedure;
end package body;
