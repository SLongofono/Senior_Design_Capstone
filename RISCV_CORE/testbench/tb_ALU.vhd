----------------------------------------------------------------------------------
-- Engineer: Longofono
-- 
-- Create Date: 01/02/2018 02:03:32 PM
-- Module Name: tb_ALU - Behavioral
-- Description: 
-- 
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library config;
use work.config.all;

entity tb_ALU is
--  Port ( );
end tb_ALU;

architecture Behavioral of tb_ALU is

-- Component declarations
component ALU is
    port(
        clk:        in std_logic;                       -- System clock
        rst:        in std_logic;                       -- Reset
        halt:       in std_logic;                       -- Do nothing
        ctrl:       in ctrl_t;                          -- Operation
        rs1:        in doubleword;                      -- Source 1
        rs2:        in doubleword;                      -- Source 2
        shamt:      in std_logic_vector(4 downto 0);    -- shift amount
        rout:       out doubleword;                     -- Output Result
        error:      out std_logic;                      -- signal exception
        overflow:   out std_logic;                      -- signal overflow
        zero:       out std_logic                       -- signal zero result
    );
end component;

-- Signals and constants
constant t_per: time := 1 ns;
signal clk: std_logic := '0';
signal rst: std_logic := '1';
signal s_halt: std_logic := '0';
signal s_ctrl: ctrl_t := "00000";
signal s_rs1: doubleword := (others => '0');
signal s_rs2: doubleword := (others => '0');
signal s_shamt: std_logic_vector(4 downto 0) := "00000";
signal s_rd: doubleword := (others => '0');
signal s_zero : std_logic := '0';
signal s_overflow : std_logic := '0';
signal s_error : std_logic := '0';

begin

-- Instantiate components
myALU: ALU
    port map(
        clk => clk,
        rst => rst,
        halt => s_halt,
        ctrl => s_ctrl,
        rs1 => s_rs1,
        rs2 => s_rs2,
        shamt => s_shamt,
        rout => s_rd,
        error => s_error,
        overflow => s_overflow,
        zero => s_zero
    );

-- Clock generation
tiktok: process
begin
    clk <= '0';
    wait for t_per/2;
    clk <= '1';
    wait for t_per/2;
end process;

main: process
begin
    -- Settling
    wait for t_per;
    wait;
end process;
end Behavioral;
