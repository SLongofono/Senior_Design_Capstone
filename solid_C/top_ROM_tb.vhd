----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/28/2018 05:30:29 PM
-- Design Name: 
-- Module Name: top_system_simulation - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library config;
use work.config.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_ROM_tb is
--  Port ( );
end top_ROM_tb;

architecture Behavioral of top_ROM_tb is


component shell is
    Port(
        clk: in std_logic;
        rst: in std_logic;
        status: out std_logic;
        DEBUG_halt: in std_logic;

        -- LEDS out
        LED: out std_logic_vector(15 downto 0);
    
        -- UART out
        UART_TXD: out std_logic;
        UART_RXD: in std_logic;
    
        -- ROM / RAM lines --
        MEM_addr:       out std_logic_vector(26 downto 0);
        MEM_data_in:    out std_logic_vector(7 downto 0);
        MEM_data_out:   in  std_logic_vector(7 downto 0); 
        MEM_ram:        out std_logic;
        MEM_write:      out std_logic;
        MEM_request:    out std_logic;
        MEM_status:     in  std_logic;
        MEM_err:        in  std_logic 
    );
end component;

component stub_ram_int is
    Port(
        memAddress      : in STD_LOGIC_VECTOR (26 downto 0);
        dataIn          : in STD_LOGIC_VECTOR (7 downto 0);
        dataOut         : out STD_LOGIC_VECTOR (7 downto 0);
        valid           : in STD_LOGIC;
        done            : out STD_LOGIC;
        write           : in STD_LOGIC;
        chip_select     : in STD_LOGIC;
        err             : out STD_LOGIC;
        clk             : in STD_LOGIC;
        reset           : in STD_LOGIC
    );
end component;

component rom_intf is
    Port(
        memAddress       : in STD_LOGIC_VECTOR (26 downto 0);
        dataIn           : in STD_LOGIC_VECTOR (7 downto 0);
        dataOut          : out STD_LOGIC_VECTOR (7 downto 0);
        valid            : in STD_LOGIC;
        done             : out STD_LOGIC;
        write            : in STD_LOGIC;
        chip_select      : in STD_LOGIC;
        err              : out STD_LOGIC;
        clk, rst         : in STD_LOGIC;
        
        -- ROM SPI signals
        cs_n: out STD_LOGIC;
        dq: inout std_logic_vector(3 downto 0)
    );
end component;

-- Signals
signal s_clk:         std_logic;
signal s_rst:         std_logic;
signal s_status:      std_logic;
signal s_DEBUG_halt:  std_logic;

signal s_cs_n:      STD_LOGIC;
signal s_dq:        std_logic_vector(3 downto 0);

-- LEDS out
signal s_LED: std_logic_vector(15 downto 0);

-- UART out
signal s_UART_TXD: std_logic;
signal s_UART_RXD: std_logic;

-- ROM / RAM lines --
signal s_MEM_addr:       std_logic_vector(26 downto 0);
signal s_MEM_data_in:    std_logic_vector(7 downto 0);
signal s_MEM_data_out:   std_logic_vector(7 downto 0); 
signal s_MEM_ram:        std_logic;
signal s_MEM_write:      std_logic;
signal s_MEM_request:    std_logic;
signal s_MEM_status:     std_logic;
signal s_MEM_err:        std_logic;

signal s_rom_data_out:      std_logic_vector(7 downto 0);
signal s_rom_done:          std_logic;
signal s_rom_chip_select:   std_logic;
signal s_rom_err:           std_logic;

signal s_ram_data_out:      std_logic_vector(7 downto 0);
signal s_ram_done:          std_logic;
signal s_ram_chip_select:   std_logic;
signal s_ram_err:           std_logic;

begin

s_MEM_data_out <= s_ram_data_out when ( s_MEM_ram = '1' ) else s_rom_data_out;
s_MEM_status   <= s_ram_done     when ( s_MEM_ram = '1' ) else s_rom_done;
s_MEM_err      <= s_ram_err      when ( s_MEM_ram = '1' ) else s_rom_err;

s_ram_chip_select <= s_MEM_ram;
s_rom_chip_select <= not s_MEM_ram;

s_UART_RXD <= '0';
s_DEBUG_halt <= '0';

my_shell: shell
    port map(
        clk         => s_clk,
        rst         => s_rst,
        status      => s_status,
        DEBUG_halt  => s_DEBUG_halt,

        -- LEDS out
        LED         => s_LED,
    
        -- UART out
        UART_TXD    => s_UART_TXD,
        UART_RXD    => s_UART_RXD,
    
        -- ROM / RAM lines --
        MEM_addr        => s_MEM_addr,
        MEM_data_in     => s_MEM_data_in,
        MEM_data_out    => s_MEM_data_out,
        MEM_ram         => s_MEM_ram,
        MEM_write       => s_MEM_write,
        MEM_request     => s_MEM_request,
        MEM_status      => s_MEM_status,
        MEM_err         => s_MEM_err
    );
            
my_ram: stub_ram_int
    port map(
        memAddress  => s_MEM_addr,
        dataIn      => s_MEM_data_in,
        dataOut     => s_ram_data_out,
        valid       => s_MEM_request,
        done        => s_ram_done,
        write       => s_MEM_write,
        chip_select => s_ram_chip_select,
        err         => s_ram_err,
        clk         => s_clk,
        reset       => s_rst
    );

my_rom: rom_intf
    port map(
        memAddress  => s_MEM_addr,
        dataIn      => s_MEM_data_in,
        dataOut     => s_rom_data_out,
        valid       => s_MEM_request,
        done        => s_rom_done,
        write       => s_MEM_write,
        chip_select => s_rom_chip_select,
        err         => s_rom_err,
        clk         => s_clk,
        rst         => s_rst,
        cs_n        => s_cs_n,
        dq          => s_dq
    );



process begin
    s_rst <= '1';
    wait for 8 ns;
    s_rst <= '0';
    wait;
end process;

process begin
    s_clk <= '0';
    wait for 5 ns;
    s_clk <= '1';
    wait for 5 ns;
end process;


end Behavioral;
