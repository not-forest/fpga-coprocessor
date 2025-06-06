-- ============================================================
-- File: pll.vhd
-- Desc: Phase-locked loop entity. Used to feed the coprocessor with a maximal stable clock specifically for
-- Cyclone IV E family of FPGAs.
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

entity pll_vendor is
    port (
        i_clk0      : in std_logic;         -- External clock input (50 MHz)
        ni_sleep    : in std_logic;         -- Control signal for sleep mode. (Active low)
        o_clk0      : out std_logic;        -- 50 MHz clock
        o_clk1      : out std_logic;        -- 100 MHz clock
        o_clk2      : out std_logic;        -- Max Cyclone IV Clock (~472.5 MHz)
        o_locked    : out std_logic         -- PLL Lock Signal
    );
end entity pll_vendor;

architecture vendor of pll_vendor is
    signal w_oclks : std_logic_vector(5 downto 0);  -- Signal for output clocks

    component altpll
        generic (
            inclk0_input_frequency  : natural := 50000;
            -- Clock 0 (50 MHz)
            clk0_multiply_by        : natural := 1;
            clk0_divide_by          : natural := 1;
            -- Clock 1 (100 MHz)
            clk1_multiply_by        : natural := 2;
            clk1_divide_by          : natural := 1;
            -- Clock 2 (Max ~472.5 MHz)
            clk2_multiply_by        : natural := 19;
            clk2_divide_by          : natural := 2;
            -- Other PLL settings
            compensate_clock        : string  := "clk0";
            operation_mode          : string  := "normal";
            bandwidth_type          : string  := "auto";
            pll_type                : string  := "auto";
            intended_device_family  : string  := "Cyclone IV E"
        );
        port (
            inclk  : in  std_logic_vector(1 downto 0);
            clk    : out std_logic_vector(5 downto 0);
            locked : out std_logic;
            areset : in  std_logic
        );
    end component;

begin
    -- Instantiate the PLL
    ALTPLL_Inst : altpll
        port map (
            inclk(0) => i_clk0,
            inclk(1) => '0',
            clk      => w_oclks,
            locked   => o_locked,
            areset   => not ni_sleep
        );

    -- Assigning PLL outputs
    o_clk0 <= w_oclks(0);  -- 50 MHz clock
    o_clk1 <= w_oclks(1);  -- 100 MHz clock
    o_clk2 <= w_oclks(2);  -- Max Cyclone IV clock (~472.5 MHz)
end architecture vendor;

