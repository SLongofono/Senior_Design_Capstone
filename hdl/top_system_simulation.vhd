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

entity top_system_simulation is
--  Port ( );
end top_system_simulation;

architecture Behavioral of top_system_simulation is


component simple_core is
    Port(
        status: out std_logic;                          -- LED blinkenlites
        clk: in std_logic;                              -- System clock (100 MHz)
        rst: in std_logic;                              -- Tied to switch SW0
        
        reggie: out regfile_arr;
        pc_curr: out doubleword;
        DEBUG_halt: in std_logic;

        MMU_addr_in: out doubleword;                    -- 64-bits address for load/store
        MMU_data_in: out doubleword;                    -- 64-bits data for store
        MMU_satp: out doubleword;                       -- Signals address translation privilege
        MMU_mode: out std_logic_vector(1 downto 0);     -- Current operating mode (Machine, Supervisor, Etc)
        MMU_store: out std_logic;                       -- High to toggle store 
        MMU_load: out std_logic;                        -- High to toggle load
        MMU_busy: in std_logic;                         -- High when busy
        MMU_ready_instr: out std_logic;                 -- Ready for a new instruction (initiates fetch) 
        MMU_addr_instr: out doubleword;                 -- Instruction Address (AKA PC)
        MMU_alignment: out std_logic_vector(3 downto 0);-- alignment in bytes
        MMU_data_out: in doubleword;                    -- 64-Bits data out for load
        MMU_instr_out: in word;                         -- 64-Bits instruction out for fetch
        MMU_error: in std_logic_vector(5 downto 0)      -- Error bits from MMU
    );
end component;

component MMU is
    Port(
        clk: in std_logic;                      -- 100 Mhz Clock
        rst: in std_logic;                      -- Active high reset
        addr_in: in doubleword;                 -- 64-bits address in
        data_in: in doubleword;                 -- 64-bits data in
        satp: in doubleword;                    -- Control register
        mode: in std_logic_vector(1 downto 0);  -- Current mode (Machine, Supervisor, Etc)
        store: in std_logic;                    -- High to toggle store 
        load: in std_logic;                     -- High to toggle load
        busy: out std_logic := '0';             -- High when busy
        ready_instr: in std_logic;              -- Can fetch next instruction (might be redundant)
        addr_instr: in doubleword;              -- Instruction Address (AKA PC)
        alignment: in std_logic_vector(3 downto 0); --Mask
        data_out: out doubleword;               -- 64-Bits data out
        instr_out: out word;              -- 64-Bits instruction out
        error: out std_logic_vector(5 downto 0);-- Error

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
        dq: inout std_logic_vector(3 downto 0));
end component;

component debug_controller is
    port (clk,RST: in STD_LOGIC;
          HALT: out STD_LOGIC;
          REGGIE: in regfile_arr;
          PC_IN: in doubleword;
          INSTRUCTION_IN: in word;
          UART_RXD: in STD_LOGIC;
          UART_TXD 	: out  STD_LOGIC);
end component;


signal s_MMU_addr_in: doubleword;                     -- 64-bits address for load/store
signal s_MMU_data_in: doubleword;                     -- 64-bits data for store
signal s_MMU_satp: doubleword := (others => '0');     -- Signals address translation privilege
signal s_MMU_mode: std_logic_vector(1 downto 0);      -- Current operating mode (Machine, Supervisor, Etc)
signal s_MMU_store: std_logic;                        -- High to toggle store 
signal s_MMU_load: std_logic;                         -- High to toggle load
signal s_MMU_busy: std_logic;                         -- High when busy
signal s_MMU_ready_instr: std_logic;                  -- Ready for a new instruction (initiates fetch) 
signal s_MMU_addr_instr: doubleword;                  -- Instruction Address (AKA PC)
signal s_MMU_alignment: std_logic_vector(3 downto 0); -- alignment in bytes
signal s_MMU_data_out: doubleword;                    -- 64-Bits data out for load
signal s_MMU_instr_out: word;                   	  -- 64-Bits instruction out for fetch
signal s_MMU_error: std_logic_vector(5 downto 0);     -- Error bits from MMU
signal s_MMU_txd : std_logic;
signal status, clk: std_logic := '0';
signal rst: std_logic := '1';

        signal LED:  std_logic_vector(15 downto 0);
        signal UART_TXD:  std_logic;
        signal UART_RXD:  std_logic;
        signal ddr2_addr :  STD_LOGIC_VECTOR (12 downto 0);
        signal ddr2_ba :    STD_LOGIC_VECTOR (2 downto 0);
        signal ddr2_ras_n : STD_LOGIC;
        signal ddr2_cas_n : STD_LOGIC;
        signal ddr2_we_n :  STD_LOGIC;
        signal ddr2_ck_p :  std_logic_vector(0 downto 0);
        signal ddr2_ck_n :  std_logic_vector(0 downto 0);
        signal ddr2_cke :   std_logic_vector(0 downto 0);
        signal ddr2_cs_n :  std_logic_vector(0 downto 0);
        signal ddr2_dm :    STD_LOGIC_VECTOR (1 downto 0);
        signal ddr2_odt :   std_logic_vector(0 downto 0);
        signal ddr2_dq :   STD_LOGIC_VECTOR (15 downto 0);
        signal ddr2_dqs_p : STD_LOGIC_VECTOR (1 downto 0);
        signal ddr2_dqs_n : STD_LOGIC_VECTOR (1 downto 0);
        signal sck:  std_logic;  -- Special gated sck for the ROM STARTUPE2 generic 
        signal cs_n:  STD_LOGIC;
        signal dq:  std_logic_vector(3 downto 0);

signal s_DEBUG_halt: std_logic;						  -- Halt signal from Debugger
signal s_DEBUG_pc_in: doubleword;
signal s_DEBUG_reggie: regfile_arr;
signal s_DEBUG_txd: std_logic;
signal counter: integer := 0;

begin

bestCore: simple_core
    port map(
        status          => status,
        clk             => clk, 
        rst             => rst,
        
        reggie    => s_DEBUG_reggie,
        pc_curr   => s_DEBUG_pc_in,
        DEBUG_halt  => s_DEBUG_halt,

        MMU_addr_in     => s_MMU_addr_in,
        MMU_data_in     => s_MMU_data_in,
        MMU_satp        => s_MMU_satp,
        MMU_mode        => s_MMU_mode,
        MMU_store       => s_MMU_store,
        MMU_load        => s_MMU_load,
        MMU_busy        => s_MMU_busy,
        MMU_ready_instr => s_MMU_ready_instr,
        MMU_addr_instr  => s_MMU_addr_instr,
        MMU_alignment   => s_MMU_alignment,
        MMU_data_out    => s_MMU_data_out,
        MMU_instr_out   => s_MMU_instr_out,
        MMU_error       => s_MMU_error
    );
    
memmy: MMU
    port map(
        clk         => clk,       
        rst         => rst,        
        addr_in     => s_MMU_addr_in,    
        data_in     => s_MMU_data_in,    
        satp        => s_MMU_satp,
        mode        => s_MMU_mode,       
        store       => s_MMU_store,      
        load        => s_MMU_load,       
        busy        => s_MMU_busy,       
        ready_instr => s_MMU_ready_instr,
        addr_instr  => s_MMU_addr_instr, 
        alignment   => s_MMU_alignment, 
        data_out    => s_MMU_data_out,   
        instr_out   => s_MMU_instr_out, 
        error       => s_MMU_error,
        LED         => LED,       
        UART_TXD    => s_MMU_txd,   
        UART_RXD    => UART_RXD,
        ddr2_addr   => ddr2_addr,
        ddr2_ba     => ddr2_ba,   
        ddr2_ras_n  => ddr2_ras_n,
        ddr2_cas_n  => ddr2_cas_n,
        ddr2_we_n   => ddr2_we_n, 
        ddr2_ck_p   => ddr2_ck_p,
        ddr2_ck_n   => ddr2_ck_n,
        ddr2_cke    => ddr2_cke,
        ddr2_cs_n   => ddr2_cs_n,
        ddr2_dm     => ddr2_dm,
        ddr2_odt    => ddr2_odt,
        ddr2_dq     => ddr2_dq,
        ddr2_dqs_p  => ddr2_dqs_p,
        ddr2_dqs_n  => ddr2_dqs_n,
        sck         => sck, 
        cs_n        => cs_n,
        dq          => dq
    );

debugger: debug_controller port map(
		clk 		    => clk,
		rst 		    => rst,
        halt 		    => s_DEBUG_halt,
        reggie 		    => s_DEBUG_reggie,
        pc_in 		    => s_DEBUG_pc_in,
        INSTRUCTION_IN  => s_MMU_instr_out,
        UART_RXD 	    => UART_RXD,
        UART_TXD 	    => s_DEBUG_txd);



process begin
    counter <= counter + 1;
    if(counter > 2) then
        rst <= '0';
    end if;
    clk <= clk xor '1';
    wait for 10 ns;
end process;


end Behavioral;
