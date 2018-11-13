library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library config;
use work.config.all;

use IEEE.NUMERIC_STD.ALL;

entity MMU_tb is
end MMU_tb;

architecture Behavioral of MMU_tb is

component MMU is
    Port(
        clk: in std_logic;      -- 100 Mhz Clock
        rst: in std_logic;          -- Active high reset
        addr_in: in doubleword;     -- 64-bits address in
        data_in: in doubleword;     -- 64-bits data in
        satp: in doubleword;        -- Control register
        store: in std_logic;        -- High to toggle store 
        load: in std_logic;         -- High to toggle load
        busy: out std_logic;        -- High when busy
        ready_instr: in std_logic;  -- Can fetch next instruction (might be redundant)
        addr_instr: in doubleword;  -- Instruction Address (AKA PC)
        alignment: in std_logic_vector(3 downto 0); --Mask
        data_out: out doubleword;   -- 64-Bits data out
        instr_out: out doubleword;  -- 64-Bits instruction out
        error: out std_logic_vector(5 downto 0);
        
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

        fkuck_vivado_so_much: out std_logic_vector(5 downto 0);
        s_internal_address_out: out doubleword;
        -- ROM SPI signals
        sck: out std_logic;  -- Special gated sck for the ROM STARTUPE2 generic 
        cs_n: out STD_LOGIC;
        dq: inout std_logic_vector(3 downto 0));
end component;

signal clk, rst, store, load, busy, ready_instr: std_logic := '0';      -- 100 Mhz Clock
signal addr_in, data_in, satp, addr_instr, data_out, instr_out: doubleword := (others => '0');
signal alignment: std_logic_vector(3 downto 0) := (others => '0');
signal error: std_logic_vector(5 downto 0) := (others => '0');
signal LED: std_logic_vector(15 downto 0) := (others => '0');
-- For the moment all the rest open

signal UART_TXD: std_logic;
signal UART_RXD: std_logic;
signal s_fuck_vivado_so_fucking_much: std_logic_vector(5 downto 0);
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

signal sck: std_logic;  -- Special gated sck for the ROM STARTUPE2 generic 
signal cs_n: STD_LOGIC;
signal dq: std_logic_vector(3 downto 0);

signal s_internal_address_out: doubleword;

signal counter: integer := 0;
begin

oom: MMU port map(clk => clk, rst => rst, store => store, load => load, busy => busy, ready_instr => ready_instr,
	addr_in => addr_in, data_in => data_in, satp => satp, addr_instr => addr_instr, data_out => data_out,
	instr_out => instr_out, alignment => alignment, error => error, LED => LED, 
	UART_TXD=>UART_TXD,
	UART_RXD=>UART_RXD,
	ddr2_addr => ddr2_addr,
	ddr2_ba => ddr2_ba,
	ddr2_ras_n => ddr2_ras_n,
	ddr2_cas_n => ddr2_cas_n,
	ddr2_we_n => ddr2_we_n,
	ddr2_ck_p => ddr2_ck_p,
	ddr2_ck_n => ddr2_ck_n,
	ddr2_cke => ddr2_cke,
	ddr2_cs_n => ddr2_cs_n,
	ddr2_dm => ddr2_dm,
	ddr2_odt => ddr2_odt,
	ddr2_dq => ddr2_dq,
	ddr2_dqs_p => ddr2_dqs_p,
	ddr2_dqs_n => ddr2_dqs_n,
    fkuck_vivado_so_much => s_fuck_vivado_so_fucking_much,
    s_internal_address_out => s_internal_address_out,
    sck => sck,
	cs_n => cs_n,
	dq => dq);

process begin
	if(counter < 5) then
		rst <= '1';
	elsif(counter = 5) then
		rst <= '0';
    elsif(counter = 8) then
        load <= '1';
        addr_in <= x"0000000080000000";
	elsif(counter > 9) then
	    addr_in <= x"0000000080000000";
	    load <= '0';
	end if;
	
	counter <= counter + 1;
	clk <= clk xor '1';
	wait for 2 ns;
end process;

--pragma synthesis_off
--current_state <= current_state;
--pragma synthesis_on 

end Behavioral;