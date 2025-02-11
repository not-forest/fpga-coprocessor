-- ============================================================
-- File: pll.vhd
-- Desc: Phase-locked loop entity. Used to feed the coprocessor with a stable clock signal for
--  proper data flow.
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

library altera_mf;
use altera_mf.all;

entity pll is
    port (
        i_clk0  : in std_logic := '1';  -- External clock input (50 MHz)
        o_clk0  : out std_logic;        -- PLL 50 MHz output clock
        o_clk1  : out std_logic;        -- PLL 75 MHz output clock
        o_clk2  : out std_logic         -- PLL 100 MHz output clock
    );
end entity pll;

architecture vendor of pll is
    signal w_oclks : std_logic_vector(4 downto 0);  -- Used to connect output clocks

    component altpll
        generic (
            bandwidth_type            : string;
            clk0_divide_by            : natural;
            clk0_duty_cycle           : natural;
            clk0_multiply_by          : natural;
            clk0_phase_shift          : string;
            clk1_divide_by            : natural;
            clk1_duty_cycle           : natural;
            clk1_multiply_by          : natural;
            clk1_phase_shift          : string;
            clk2_divide_by            : natural;
            clk2_duty_cycle           : natural;
            clk2_multiply_by          : natural;
            clk2_phase_shift          : string;
            compensate_clock          : string;
            inclk0_input_frequency    : natural;
            intended_device_family    : string;
            lpm_hint                  : string;
            lpm_type                  : string;
            operation_mode            : string;
            pll_type                  : string;
            port_activeclock          : string;
            port_areset               : string;
            port_clkbad0              : string;
            port_clkbad1              : string;
            port_clkloss              : string;
            port_clkswitch            : string;
            port_configupdate         : string;
            port_fbin                 : string;
            port_inclk0               : string;
            port_inclk1               : string;
            port_locked               : string;
            port_pfdena               : string;
            port_phasecounterselect   : string;
            port_phasedone            : string;
            port_phasestep            : string;
            port_phaseupdown          : string;
            port_pllena               : string;
            port_scanaclr             : string;
            port_scanclk              : string;
            port_scanclkena           : string;
            port_scandata             : string;
            port_scandataout          : string;
            port_scandone             : string;
            port_scanread             : string;
            port_scanwrite            : string;
            port_clk0                 : string;
            port_clk1                 : string;
            port_clk2                 : string;
            port_clk3                 : string;
            port_clk4                 : string;
            port_clk5                 : string;
            port_clkena0              : string;
            port_clkena1              : string;
            port_clkena2              : string;
            port_clkena3              : string;
            port_clkena4              : string;
            port_clkena5              : string;
            port_extclk0              : string;
            port_extclk1              : string;
            port_extclk2              : string;
            port_extclk3              : string;
            width_clock               : natural
        );
        port (
            inclk : in std_logic_vector(1 downto 0);
            clk   : out std_logic_vector(4 downto 0)
        );
    end component;

begin
    ALTPLL_Inst : altpll
        generic map (
            inclk0_input_frequency  => 20000,   -- Input clock 50 MHz -> 20 ns
            -- Clock 0 (50 MHz)
            clk0_multiply_by        => 1, 
            clk0_divide_by          => 1, 
            clk0_duty_cycle         => 50, 
            clk0_phase_shift        => "0", 

            -- Clock 1 (75 MHz)
            clk1_multiply_by        => 3, 
            clk1_divide_by          => 2, 
            clk1_duty_cycle         => 50, 
            clk1_phase_shift        => "0",

            -- Clock 2 (100 MHz)
            clk2_multiply_by        => 2, 
            clk2_divide_by          => 1, 
            clk2_duty_cycle         => 50, 
            clk2_phase_shift        => "0",

            lpm_hint                => "cbx_module_prefix=clk_pll",
            intended_device_family  => "cyclone iv e",
            compensate_clock        => "clk0",
            operation_mode          => "normal",
            bandwidth_type          => "auto",
            pll_type                => "auto",
            lpm_type                => "altpll",
            width_clock             => 5,
            
            -- Unused ports
            port_activeclock        => "port_unused",
            port_areset             => "port_unused",
            port_clkbad0            => "port_unused",
            port_clkbad1            => "port_unused",
            port_clkloss            => "port_unused",
            port_clkswitch          => "port_unused",
            port_configupdate       => "port_unused",
            port_fbin               => "port_unused",
            port_inclk0             => "port_used",
            port_inclk1             => "port_unused",
            port_locked             => "port_unused",
            port_pfdena             => "port_unused",
            port_phasecounterselect => "port_unused",
            port_phasedone          => "port_unused",
            port_phasestep          => "port_unused",
            port_phaseupdown        => "port_unused",
            port_pllena             => "port_unused",
            port_scanaclr           => "port_unused",
            port_scanclk            => "port_unused",
            port_scanclkena         => "port_unused",
            port_scandata           => "port_unused",
            port_scandataout        => "port_unused",
            port_scandone           => "port_unused",
            port_scanread           => "port_unused",
            port_scanwrite          => "port_unused",
            port_clk0               => "port_used",
            port_clk1               => "port_used",
            port_clk2               => "port_used",
            port_clk3               => "port_unused",
            port_clk4               => "port_unused",
            port_clk5               => "port_unused",
            port_clkena0            => "port_unused",
            port_clkena1            => "port_unused",
            port_clkena2            => "port_unused",
            port_clkena3            => "port_unused",
            port_clkena4            => "port_unused",
            port_clkena5            => "port_unused",
            port_extclk0            => "port_unused",
            port_extclk1            => "port_unused",
            port_extclk2            => "port_unused",
            port_extclk3            => "port_unused"
        )
        port map (
            inclk(0) => i_clk0,
            inclk(1) => '0',
            clk      => w_oclks
        );

    o_clk0 <= w_oclks(0);  -- 50 MHz clock
    o_clk1 <= w_oclks(1);  -- 75 MHz clock
    o_clk2 <= w_oclks(2);  -- 100 MHz clock
end architecture vendor;
