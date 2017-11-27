----------------------------------------------------------------------------------
-- Engineer: Longofono
-- 
-- Create Date: 11/27/2017 09:05:36 AM
-- Module Name: tb_regfile - Behavioral
-- Description: 
-- 
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library config;
use work.config.all;

entity tb_regfile is
--  Port ( );
end tb_regfile;

architecture Behavioral of tb_regfile is

-- Component declarations
component regfile is
    port(
        clk:            in std_logic;
        rst:            in std_logic;
        read_addr_1:    in std_logic_vector(4 downto 0);    -- Register source read_data_1
        read_addr_2:    in std_logic_vector(4 downto 0);    -- Register source read_data_2
        write_addr:     in std_logic_vector(4 downto 0);    -- Write dest write_data
        write_data:     in doubleword;                      -- Data to be written
        halt:           in std_logic;                       -- Control, do nothing on high
        write_en:       in std_logic;                       -- write_data is valid
        read_data_1:    out doubleword;                     -- Data from read_addr_1
        read_data_2:    out doubleword;                     -- Data from read_addr_2
        write_error:    out std_logic;                      -- Writing to constant, HW exception
        debug_out:      out regfile_arr                     -- Copy of regfile contents for debugger
    );
end component;

-- Signals and constants
constant t_per: time := 1 ns;

signal clk: std_logic := '0';
signal rst: std_logic := '1';
signal ra1: std_logic_vector(4 downto 0) := "00000";
signal ra2: std_logic_vector(4 downto 0) := "00000";
signal wa: std_logic_vector(4 downto 0) := "00000";
signal halt: std_logic := '0';
signal write_en: std_logic := '0';
signal rd1: doubleword;
signal rd2:doubleword;
signal wd: doubleword := (others => '0');
signal write_error: std_logic;
signal debug: regfile_arr;

begin
-- Instantiation
myReg: regfile
    port map(
        clk => clk,
        rst => rst,
        read_addr_1 => ra1,
        read_addr_2 => ra2,
        write_addr => wa,
        write_data => wd,
        halt => halt,
        write_en => write_en,
        read_data_1 => rd1,
        read_data_2 => rd2,
        write_error => write_error,
        debug_out => debug
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

    -- Test error condition
    wd <= (others => '1');
    wa <= "00000";
    write_en <= '1';
    rst <= '0';
    wait for t_per;

    -- Test simple write and read (RAW test)
    ra1 <= "00001";
    ra2 <= "00010";
    wa <= "00001";
    write_en <= '1';
    wd <= (others => '1');
    wait for t_per;
    
    -- Test write to all valid writeable registers
    for I in 1 to 32 loop
        wa <= std_logic_vector(to_unsigned(I, 5));
        wd <= (others => '1');
        write_en <= '1';
        wait for t_per;
    end loop;

    -- Test reset
    rst <= '1';
    wa <= "00001";
    wait for t_per;
    
    -- Test halt
    rst <= '0';
    halt <= '1';
    wa <= "00001";
    wd <= (others => '1');
    wait for t_per;
    
    -- Test resume
    halt <= '0';
    wa <= "00001";
    wd <= (others => '1');
    wait for t_per;

    wait;
end process;

end Behavioral;
