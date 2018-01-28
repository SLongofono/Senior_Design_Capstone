----------------------------------------------------------------------------------
-- Engineer: Longofono
-- 
-- Create Date: 01/28/2018 03:09:12 PM
-- Module Name: tb_writeback - Behavioral
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

entity tb_writeback is
--  Port ( );
end tb_writeback;

architecture Behavioral of tb_writeback is
-- component forward declaration
component writeback is
    port(
        clk:            in std_logic;   -- System clock
        rst:            in std_logic;   -- System reset
        halt:           in std_logic;   -- Do nothing when high
        ready_input:    in std_logic;   -- Control requests read
        ready_output:   in std_logic;   -- MMU requests write
        output_OK:      out std_logic;  -- Write data and address are valid
        input_OK:       out std_logic;  -- Read data and address recorded
        input_data:     in doubleword;  -- Data from previous stage
        input_address:  in word;        -- MMU Destination for input data
        output_data:    out doubleword; -- Data to be written to MMU
        output_address: out word        -- MMU destination for output data
    );
end component;

-- Signals and constants
constant t_per: time := 1 ns;
constant w1 : doubleword := (63 downto 32 => '0', others => '1');
constant w2 : doubleword := (63 downto 32 => '0', others => '1');
constant ad : word := "01111111111111111111111111111111";

signal s_clk: std_logic := '0';
signal s_rst: std_logic := '1';
signal s_ra: word := (others => '0');
signal s_wa: word;
signal s_rdata: doubleword := (others => '0');
signal s_wdata: doubleword;
signal s_ack_r: std_logic := '0';
signal s_ack_w: std_logic := '0';
signal s_halt: std_logic := '0';
signal s_read: std_logic := '0';
signal s_write: std_logic := '0';

begin
-- Instantiation
myWB: writeback
    port map(
        clk => s_clk,
        rst => s_rst,
        halt => s_halt,
        ready_input => s_read,
        ready_output => s_write,
        output_OK => s_ack_w,
        input_OK => s_ack_r,
        input_data => s_rdata,
        input_address => s_ra,
        output_data => s_wdata,
        output_address => s_wa
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
    -- Settling
    wait for t_per/2;
    wait for t_per;
    s_rst <= '0';

    -- Test read and write in isolation
    s_read <= '1';
    s_ra <= ad;
    s_rdata <= w1;
    wait for t_per;
    s_write <= '1';
    s_read <= '0';
    wait for t_per;
    s_write <= '0';

    -- Test simple write and read (RAW test)
    s_read <= '1';
    s_ra <= ad;
    s_rdata <= w1;
    s_write <= '0';
    wait for t_per; -- allow write to propagate
    s_rdata <= w2;
    s_write <= '1';  -- attempt simultaneous read and write
    wait for t_per;
    
     -- Test reset
    s_read <= '0';
    s_write <= '0';
    s_rst <= '1';
    wait for t_per;
    
    -- Test halt
    s_rst <= '0';
    s_halt <= '1';
    s_read <= '1';
    s_ra <= ad;
    s_rdata <= w1;
    wait for t_per;
    
    -- Test resume
    s_halt <= '0';
    wait for t_per;

    wait;
end process;


end Behavioral;
