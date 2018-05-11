----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Longofono
-- 
-- Create Date: 02/04/2018 01:43:16 PM
-- Module Name: timer - Behavioral
-- Description: Control unit timer module
-- 
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library config;
use work.config.all;

entity timer is
    Port(
        clk:                in std_logic;   -- System clock
        rst:                in std_logic;   -- System reset
        CSR_compare:        in doubleword;  -- Comparison value to trigger interrupt
        CSR_count:          out doubleword; -- Current timer count in 50 MHz ticks
        timer_interrupt:    out std_logic   -- Interrupt condition signal
    );
end timer;

architecture Behavioral of timer is

-- latch for counter
signal lastVal: doubleword;
signal interrupt: std_logic;

begin

-- Updates counter value
process(clk, rst)
begin
    if('1' = rst) then
        lastVal <= (others => '0');
    elsif(rising_edge(clk)) then
        lastVal <= std_logic_vector(unsigned(lastVal) + 1);
    end if;
end process;

-- Triggers timer interrupt signal
process(CSR_compare, lastVal)
begin
    if(unsigned(CSR_compare) = unsigned(lastVal)) then
        interrupt <= '1';
    else
        interrupt <= '0';
    end if;
end process;

CSR_count <= lastVal;
timer_interrupt <= interrupt;

end Behavioral;
