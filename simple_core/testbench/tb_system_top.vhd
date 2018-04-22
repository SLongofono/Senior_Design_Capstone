----------------------------------------------------------------------------------
-- Engineer:    Longofono 
--
-- Create Date: 04/21/2018 06:23:15 PM
-- Module Name: tb_system_top - Behavioral
-- Description: System-level testbench for simluation
--
-- Additional Comments:  
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library config;
use work.config.all;


entity tb_system_top is
end tb_system_top;

architecture Behavioral of tb_system_top is

component system_top is
    port(
            clk: in std_logic;
            rst: in std_logic;
            status: out std_logic;

            -- LEDS out
            LED: out std_logic_vector(15 downto 0);
        
            -- UART out
            UART_TXD: out std_logic;
            UART_RXD: in std_logic;
        
            -- DDR2 Signals
            ddr2_addr : out STD_LOGIC_VECTOR (12 downto 0);
            ddr2_ba : out STD_LOGIC_VECTOR (2 downto 0);
            ddr2_ras_n : out STD_LOGIC;
            ddr2_cas_n : out STD_LOGIC;
            ddr2_we_n : out STD_LOGIC;
            ddr2_ck_p : out std_logic_vector(0 downto 0);
            ddr2_ck_n : out std_logic_vector(0 downto 0);
            ddr2_cke : out std_logic_vector(0 downto 0);
            ddr2_cs_n : out std_logic_vector(0 downto 0);
            ddr2_dm : out STD_LOGIC_VECTOR (1 downto 0);
            ddr2_odt : out std_logic_vector(0 downto 0);
            ddr2_dq : inout STD_LOGIC_VECTOR (15 downto 0);
            ddr2_dqs_p : inout STD_LOGIC_VECTOR (1 downto 0);
            ddr2_dqs_n : inout STD_LOGIC_VECTOR (1 downto 0);
           
            -- ROM SPI signals
            sck: out std_logic;  -- Special gated sck for the ROM STARTUPE2 generic 
            cs_n: out STD_LOGIC;
            dq: inout std_logic_vector(3 downto 0)
    );
end component;

signal s_clk: std_logic := '0';
signal s_rst: std_logic := '0';
signal s_status: std_logic;

-- LEDS out
signal s_LED: std_logic_vector(15 downto 0);

-- UART out
signal s_UART_TXD: std_logic;
signal s_UART_RXD: std_logic;

-- DDR2 Signals
signal s_ddr2_addr : STD_LOGIC_VECTOR (12 downto 0);
signal s_ddr2_ba : STD_LOGIC_VECTOR (2 downto 0);
signal s_ddr2_ras_n : STD_LOGIC;
signal s_ddr2_cas_n : STD_LOGIC;
signal s_ddr2_we_n : STD_LOGIC;
signal s_ddr2_ck_p : std_logic_vector(0 downto 0);
signal s_ddr2_ck_n : std_logic_vector(0 downto 0);
signal s_ddr2_cke : std_logic_vector(0 downto 0);
signal s_ddr2_cs_n : std_logic_vector(0 downto 0);
signal s_ddr2_dm : STD_LOGIC_VECTOR (1 downto 0);
signal s_ddr2_odt : std_logic_vector(0 downto 0);
signal s_ddr2_dq : STD_LOGIC_VECTOR (15 downto 0);
signal s_ddr2_dqs_p : STD_LOGIC_VECTOR (1 downto 0);
signal s_ddr2_dqs_n : STD_LOGIC_VECTOR (1 downto 0);

-- ROM SPI signals
signal s_sck: std_logic;  -- Special gated sck for the ROM STARTUPE2 generic 
signal s_cs_n: STD_LOGIC;
signal s_dq: std_logic_vector(3 downto 0);

signal t_per: time := 10 ns; -- Full speed 100 Mhz

begin

myCore: system_top
    port map(
        clk         => s_clk,
        rst         => s_rst,
        status      => s_status,
        LED         => s_LED,
        UART_TXD    => s_UART_TXD,
        UART_RXD    => s_UART_RXD,
        ddr2_addr   => s_ddr2_addr, 
        ddr2_ba     => s_ddr2_ba,   
        ddr2_ras_n  => s_ddr2_ras_n,
        ddr2_cas_n  => s_ddr2_cas_n,
        ddr2_we_n   => s_ddr2_we_n, 
        ddr2_ck_p   => s_ddr2_ck_p, 
        ddr2_ck_n   => s_ddr2_ck_n, 
        ddr2_cke    => s_ddr2_cke,  
        ddr2_cs_n   => s_ddr2_cs_n, 
        ddr2_dm     => s_ddr2_dm,   
        ddr2_odt    => s_ddr2_odt,  
        ddr2_dq     => s_ddr2_dq,   
        ddr2_dqs_p  => s_ddr2_dqs_p,
        ddr2_dqs_n  => s_ddr2_dqs_n,
        sck         => s_sck,       
        cs_n        => s_cs_n,      
        dq          => s_dq        
    );

tiktok: process -- System clock
begin
    s_clk <= '1';
    wait for t_per/2;
    s_clk <= '0';
    wait for t_per/2;
    
end process;
            
main: process
begin
    s_rst <= '1';
    wait for 20 ns;
    s_rst <= '0';
    wait for 100*t_per;
end process;            
            
end Behavioral;