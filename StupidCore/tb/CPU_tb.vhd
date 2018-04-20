----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/13/2018 04:19:50 PM
-- Design Name: 
-- Module Name: CPU_tb - Behavioral
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

entity CPU_tb is
--  Port ( );
end CPU_tb;

architecture Behavioral of CPU_tb is
component simpler_core is
  Port(
    status: out std_logic; -- LED blinkenlites
    CLK: in std_logic;  -- Tied to switch V10
    RST: in std_logic;   -- Tied to switch J15
    LED: out std_logic_vector(15 downto 0);
    PC_Switch: in std_logic;
    -- UART Serial I/O
    UART_RXD: in std_logic;
    UART_TXD: out std_logic;

    -- DDR2 signals
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
    
    
    --pragma synthesis_off
    address_out,instruction_out, instruction_address_out,load_wb_data : out STD_LOGIC_VECTOR(63 downto 0);
    reggie: out regfile_arr;
    opcode: out opcode_t;
    o_load_type: out std_logic_vector(7 downto 0);
    ALU_result: out doubleword;
    MMU_state: out std_logic_vector(5 downto 0);
    --pragma synthesis_on
    
    --ROM signals
    dq: inout STD_LOGIC_VECTOR(3 downto 0);
    cs_n: out STD_LOGIC);
end component;

signal status, PC_Switch, clk, UART_RXD, UART_TXD, cs_n: std_logic := '0';
signal rst: std_logic := '1';
signal LED: std_logic_vector(15 downto 0) := (others => '0');
signal dq: std_logic_vector(3 downto 0) := (others => '0');

signal ddr2_addr : STD_LOGIC_VECTOR (12 downto 0);
signal ddr2_ba : STD_LOGIC_VECTOR (2 downto 0);
signal ddr2_ras_n : STD_LOGIC;
signal ddr2_cas_n : STD_LOGIC;
signal ddr2_we_n : STD_LOGIC;
signal ddr2_ck_p : std_logic_vector(0 downto 0);
signal ddr2_ck_n : std_logic_vector(0 downto 0);
signal ddr2_cke : std_logic_vector(0 downto 0);
signal ddr2_cs_n : std_logic_vector(0 downto 0);
signal ddr2_dm : STD_LOGIC_VECTOR (1 downto 0);
signal ddr2_odt : std_logic_vector(0 downto 0);
signal ddr2_dq : STD_LOGIC_VECTOR (15 downto 0);
signal ddr2_dqs_p : STD_LOGIC_VECTOR (1 downto 0);
signal ddr2_dqs_n : STD_LOGIC_VECTOR (1 downto 0);
signal address_out, load_wb_data,instruction_out, instruction_address_out: STD_LOGIC_VECTOR(63 downto 0);
signal reggie : regfile_arr;
signal counter: integer:= 0;
signal opcode: opcode_t;
signal load_type: std_logic_vector(7 downto 0);
signal ALU_result: doubleword;
signal MMU_state: std_logic_vector(5 downto 0);
begin

CPU: simpler_core port map( status => status,
    CLK => clk,
    RST => rst,
    LED => LED,
    PC_Switch => PC_Switch,
    -- UART Serial I/O
    UART_RXD => UART_RXD,
    UART_TXD => UART_TXD,

    -- DDR2 signals
    ddr2_addr => ddr2_addr,
    ddr2_ba =>ddr2_ba,
    ddr2_ras_n => ddr2_ras_n,
    ddr2_cas_n =>ddr2_cas_n ,
    ddr2_we_n =>    ddr2_we_n ,
    ddr2_ck_p => ddr2_ck_p,
    ddr2_ck_n => ddr2_ck_n,
    ddr2_cke => ddr2_cke ,
    ddr2_cs_n => ddr2_cs_n ,
    ddr2_dm => ddr2_dm ,
    ddr2_odt => ddr2_odt ,
    ddr2_dq => ddr2_dq ,
    ddr2_dqs_p => ddr2_dqs_p ,
    ddr2_dqs_n => ddr2_dqs_n ,
    
    --pragma synthesis_off
    address_out => address_out,
    instruction_out => instruction_out,
    instruction_address_out => instruction_address_out,
    reggie => reggie,
    load_wb_data => load_wb_data,
    opcode => opcode,
    o_load_type => load_type,
    ALU_result => ALU_result,
    MMU_state => MMU_state,
    --pragma synthesis_on
    
    --ROM signals
    dq => dq,
    cs_n => cs_n);

process begin
    counter <= counter + 1;
    clk <= clk xor '1';
    wait for 10 ns;
    if(counter < 10) then
      rst <= '1';
    else
      rst <= '0';
    end if;
end process;

end Behavioral;
