-- ============================================================
-- File: sipo_tb.vhd
-- Desc: Word shifting memory block for systolic array inputs. Shifts upcoming word of data and flushes the entire
--      previous batch on each clock cycle simultaneously. Internally acts as a SIPO block of N registers.
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
library std;

use ieee.std_logic_1164.all;
use std.textio.all;

use coproc.intrinsics.all;
use coproc.tb.all;
use coproc.word_shifter;

entity sipo_tb is
    type tb_dut is record
        ni_clr : std_logic;
        i_clk : std_logic;
        i_data : t_word;          
        o_batch : t_word_array(3 downto 0);   
    end record;
end entity;

architecture behavioral of sipo_tb is
    signal sigs : tb_dut := (
        ni_clr => '1',
        i_clk => '1',
        i_data => (others => '0'),
        o_batch => (others => (others => '0'))
    );

    -- Asserts output from shift block batch with expected output.
    procedure assert_shift_regs (
        constant i_left : in t_word_array(3 downto 0);
        signal i_right : in t_word_array(3 downto 0)
    ) is 
        variable ret : boolean := false;
        variable hexleft, hexright : line;
    begin
        for i in 0 to 3 loop
            write(hexleft, to_hstring(i_left(i)));
            write(hexright, to_hstring(i_right(i)));
            if i < 3 then
                write(hexleft, string'(", "));
                write(hexright, string'(", "));
            end if;
        end loop;

        ret := i_left = i_right;
        if not ret then
            report "Failed assertion. Expected: (" & hexleft.all & "), got: (" & hexright.all & ")" severity error;
        else
            report "Passed: (" & hexleft.all & ")";
        end if;
    end procedure;


    -- Test is performed with 1MHz clock.
    signal freq : real := 1.000e6;
begin
    WORD_SHIFTER_Inst : entity word_shifter
    generic map (
        g_LENGTH => 4
                )
    port map (
        ni_clr => sigs.ni_clr,
        i_clk => sigs.i_clk,
        i_data => sigs.i_data,   
        o_batch => sigs.o_batch   
         );

    -- Simulates input clock.
    p_EX_CLOCK : tick(sigs.i_clk, freq);

    p_APPENDER : process is 
        -- Values that will be pushed into the shifter.
        variable seq : t_word_array(0 to 5) := (x"AA", x"BB", x"CC", x"DD", x"EE", x"FF");
    begin
        report "Enter p_APPENDER";

        wait until falling_edge(sigs.i_clk);
        -- Sending each word sequence per clock tick.
        for i in seq'range loop
            sigs.i_data <= seq(i);
            wait until falling_edge(sigs.i_clk);
        end loop;
        sigs.i_data <= (others => '0');

        report "Done: p_APPENDER";
        wait;
    end process;

    p_MAIN : process begin
        report "Enter p_MAIN.";

        -- Synchronisation with appender process.
        wait until falling_edge(sigs.i_clk);
        wait until falling_edge(sigs.i_clk);
        assert_shift_regs((x"00", x"00", x"00", x"00"), sigs.o_batch);
        wait until falling_edge(sigs.i_clk);
        assert_shift_regs((x"AA", x"00", x"00", x"00"), sigs.o_batch);
        wait until falling_edge(sigs.i_clk);
        assert_shift_regs((x"BB", x"AA", x"00", x"00"), sigs.o_batch);
        wait until falling_edge(sigs.i_clk);
        assert_shift_regs((x"CC", x"BB", x"AA", x"00"), sigs.o_batch);
        wait until falling_edge(sigs.i_clk);
        assert_shift_regs((x"DD", x"CC", x"BB", x"AA"), sigs.o_batch);
        wait until falling_edge(sigs.i_clk);
        assert_shift_regs((x"EE", x"DD", x"CC", x"BB"), sigs.o_batch);
        wait until falling_edge(sigs.i_clk);
        assert_shift_regs((x"FF", x"EE", x"DD", x"CC"), sigs.o_batch);
        wait until falling_edge(sigs.i_clk);
        assert_shift_regs((x"00", x"FF", x"EE", x"DD"), sigs.o_batch);
        wait until falling_edge(sigs.i_clk);
        assert_shift_regs((x"00", x"00", x"FF", x"EE"), sigs.o_batch);
        wait until falling_edge(sigs.i_clk);
        assert_shift_regs((x"00", x"00", x"00", x"FF"), sigs.o_batch);

        report "Done: p_MAIN";
        stop_clock(freq);
        wait;
    end process;
end architecture;
