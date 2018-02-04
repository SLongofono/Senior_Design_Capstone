----------------------------------------------------------------------------------
-- Engineer: Longofono
-- 
-- Create Date: 02/04/2018 02:05:57 PM
-- Module Name: tb_timer - Behavioral
-- Description: Test bench for timer and timer interrupt 
-- 
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library config;
use work.config.all;

entity tb_timer is
--  Port ( );
end tb_timer;

architecture Behavioral of tb_timer is

-- component forward declaration
component timer is
    port(
        clk:            in std_logic;   -- System clock
        rst:            in std_logic;   -- System reset
        CSR_compare:    in doubleword;  -- Comparison value to trigger interrupt
        CSR_count:      out doubleword; -- Current timer count in 50 MHz ticks
        timer_interrupt:out std_logic   -- Interrupt condition signal
    );
end component;

-- Signals and constants
constant t_per: time := 1 ns;
signal s_clk: std_logic;
signal s_rst: std_logic;
signal s_CSR_compare: doubleword;
signal s_CSR_count: doubleword;
signal s_timer_interrupt: std_logic;
begin

-- Instantiation
myTimer: timer
    port map(
        clk => s_clk,
        rst => s_rst,
        CSR_compare => s_CSR_compare,
        CSR_count => s_CSR_count,
        timer_interrupt => s_timer_interrupt
    );


-- Clock generation
tiktok: process
begin
    s_clk <= '0';
    wait for t_per/2;
    s_clk <= '1';
    wait for t_per/2;
end process;

main: process
begin
    s_rst <= '1';
    -- Settling
    wait for t_per/2;
    wait for t_per;

    -- Test simple count compare
    s_rst <= '0';
    s_CSR_compare <= (others => '0');
    wait for 10 * t_per;
    
    -- Test 1 tick timer
    s_CSR_compare <= std_logic_vector(unsigned(s_CSR_count) + 1);
    wait for t_per;
    
    -- Test 10 tick timer
    s_CSR_compare <= std_logic_vector(unsigned(s_CSR_count) + 10);
    wait for 11 * t_per;
    
    -- quick reset
    s_rst <= '1';
    wait for t_per;
    s_rst <= '0';
    
    -- Test 0.1 second timer or stack overflow and crash Vivado
    s_CSR_compare <= std_logic_vector(to_unsigned(5000000, 64));
    wait for 200 * t_per;

    wait;
end process;


end Behavioral;
