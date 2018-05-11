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
        ctrl:       in instr_t;                          -- Operation
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
signal s_ctrl: instr_t := "00000000";
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
    
    -- Begin Test
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '0');
    rst <= '0';
    wait for 1.5*t_per;

    -- Test instr_SLL - OK
    s_ctrl <= instr_SLL;
    s_rs1 <= (0 => '1', others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (63 downto 59 => '1', others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (others => '1');
    wait for t_per;
    
    -- Test instr_SLLI - OK
    s_ctrl <= instr_SLLI;
    s_rs1 <= (0 => '1', others => '0');
    s_rs2 <= (others => '0');
    s_shamt <= "00000";
    wait for t_per;
    s_shamt <= "00001";
    wait for t_per;
    s_shamt <= "00010";
    wait for t_per;
    s_shamt <= "00011";
    wait for t_per;
    s_shamt <= "11111";
    wait for t_per;
    s_rs1 <= (63 downto 59 => '1', others => '0');
    s_shamt <= "00000";
    wait for t_per;
    s_shamt <= "00001";
    wait for t_per;
    s_shamt <= "00010";
    wait for t_per;
    s_shamt <= "00011";
    wait for t_per;
    s_shamt <= "11111";
    wait for t_per;
        
    -- Test instr_SRL - OK
    s_ctrl <= instr_SRL;
    s_rs1 <= (10 => '1', others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (63 downto 59 => '1', others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (others => '1');
    wait for t_per;
        
    -- Test instr_SRLI - OK
    s_ctrl <= instr_SRLI;
    s_rs1 <= (10 => '1', others => '0');
    s_rs2 <= (others => '0');
    s_shamt <= "00000";
    wait for t_per;
    s_shamt <= "00001";
    wait for t_per;
    s_shamt <= "00010";
    wait for t_per;
    s_shamt <= "00011";
    wait for t_per;
    s_shamt <= "11111";
    wait for t_per;
    s_rs1 <= (63 downto 59 => '1', others => '0');
    s_shamt <= "00000";
    wait for t_per;
    s_shamt <= "00001";
    wait for t_per;
    s_shamt <= "00011";
    wait for t_per;
    s_shamt <= "11111";
    wait for t_per;
        
    -- Test instr_SRA - OK
    s_ctrl <= instr_SRA;
    s_rs1 <= (10 => '1', others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (63 downto 59 => '1', others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (others => '1');
    wait for t_per;
       
    -- Test instr_SRAI - OK
    s_ctrl <= instr_SRAI;
    s_rs1 <= (10 => '1', others => '0');
    s_rs2 <= (others => '0');
    s_shamt <= "00000";
    wait for t_per;
    s_shamt <= "00001";
    wait for t_per;
    s_shamt <= "00010";
    wait for t_per;
    s_shamt <= "00011";
    wait for t_per;
    s_shamt <= "11111";
    wait for t_per;
    s_rs1 <= (63 downto 59 => '1', others => '0');
    s_shamt <= "00000";
    wait for t_per;
    s_shamt <= "00001";
    wait for t_per;
    s_shamt <= "00011";
    wait for t_per;
    s_shamt <= "11111";
    wait for t_per;
 
    -- Test instr_ADD - OK
    s_ctrl <= instr_ADD;
    s_rs1 <= (others => '0');   -- 0 + 0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (1 => '1', others => '0');   -- 2 + 4
    s_rs2 <= (2 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (2 => '1', others => '0');   -- 4 + -2
    s_rs2 <= (0 => '0', others => '1');
    wait for t_per;
    s_rs1 <= (1 downto 0 => '0', others => '1');   -- -4 + 2
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (1 => '1', others => '0');   -- 2 + 0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '0');   -- 0 + -2
    s_rs2 <= (0 => '0', others => '1');
    wait for t_per;
    s_rs1 <= (0 => '1', others => '0');   -- 1 + 1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');   -- -1 + -1
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (63 => '0', others => '1'); -- overflow positive
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (63 => '1', others => '0'); -- overflow negative
    s_rs2 <= (1 downto 0 => '0', others => '1');
    wait for t_per;
        
    -- Test instr_ADDI - OK
    s_ctrl <= instr_ADDI;
    s_rs1 <= (others => '0');   -- 0 + 0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (1 => '1', others => '0');   -- 2 + 4
    s_rs2 <= (2 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (2 => '1', others => '0');   -- 4 + -2
    s_rs2 <= (0 => '0', others => '1');
    wait for t_per;
    s_rs1 <= (1 downto 0 => '0', others => '1');   -- -4 + 2
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (1 => '1', others => '0');   -- 2 + 0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '0');   -- 0 + -2
    s_rs2 <= (0 => '0', others => '1');
    wait for t_per;
    s_rs1 <= (0 => '1', others => '0');   -- 1 + 1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');   -- -1 + -1
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (63 => '0', others => '1'); -- overflow positive
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (63 => '1', 0 => '1', others => '0'); -- overflow negative
    s_rs2 <= (1 downto 0 => '0', others => '1');
    wait for t_per;
        
    -- Test instr_SUB - OK
    s_ctrl <= instr_SUB;
    s_rs1 <= (others => '0');   -- 0 - 0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (1 => '1', others => '0');   -- 2 - 4
    s_rs2 <= (2 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (2 => '1', others => '0');   -- 4 - -2
    s_rs2 <= (0 => '0', others => '1');
    wait for t_per;
    s_rs1 <= (1 downto 0 => '0', others => '1');   -- -4 - 2
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (1 => '1', others => '0');   -- 2 - 0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '0');   -- 0 - 2
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (0 => '1', others => '0');   -- 1 - 1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');   -- -1 - -1
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (63 => '0', others => '1'); -- overflow positive
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (63 => '1', 0 => '1', others => '0'); -- overflow negative
    s_rs2 <= (1 downto 0 => '1', others => '0');
    wait for t_per;
        
    -- Test instr_LUI - OK
    s_ctrl <= instr_LUI;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (19 downto 0 => '1', others => '0');
    s_rs2 <= (19 downto 0 => '1', others => '0');
    wait for t_per;
    wait for t_per;
        
    -- Test instr_AUIPC - OK
    s_ctrl <= instr_AUIPC;
    s_rs1 <= (31 => '1', others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (31 => '1', others => '0');
    s_rs2 <= (2 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (31 => '1', others => '0');
    s_rs2 <= (60 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (31 => '1', others => '0');
    s_rs2 <= (40 downto 32 => '1', others => '0');
    wait for t_per;
        
    -- Test instr_XOR - OK
    s_ctrl <= instr_XOR;
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (others => '0');
    s_rs2 <= (31 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= "1010101010101010101010101010101010101010101010101010101010101010";
    s_rs2 <= (others => '0');
    wait for t_per;
        
    -- Test instr_XORI - OK
    s_ctrl <= instr_XORI;
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (others => '0');
    s_rs2 <= (31 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= "1010101010101010101010101010101010101010101010101010101010101010";
    s_rs2 <= (others => '0');
    wait for t_per;
        
    -- Test instr_OR - OK
    s_ctrl <= instr_OR;
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (others => '0');
    s_rs2 <= (31 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= "1010101010101010101010101010101010101010101010101010101010101010";
    s_rs2 <= (others => '0');
    wait for t_per;
        
    -- Test instr_ORI - OK
    s_ctrl <= instr_ORI;
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (others => '0');
    s_rs2 <= (31 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= "1010101010101010101010101010101010101010101010101010101010101010";
    s_rs2 <= (others => '0');
    wait for t_per;
        
    -- Test instr_AND - OK
    s_ctrl <= instr_AND;
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (others => '0');
    s_rs2 <= (31 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= "1010101010101010101010101010101010101010101010101010101010101010";
    s_rs2 <= (others => '0');
    wait for t_per;
        
    -- Test instr_ANDI - OK
    s_ctrl <= instr_ANDI;
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (others => '0');
    s_rs2 <= (31 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= "1010101010101010101010101010101010101010101010101010101010101010";
    s_rs2 <= (others => '0');
    wait for t_per;
        
    -- Test instr_SLT - OK
    s_ctrl <= instr_SLT;
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '0');   
    wait for t_per;
    s_rs1 <= (1 => '1', others => '0');
    s_rs2 <= (others => '0');   
    wait for t_per;
    s_rs1 <= (others => '0');
    s_rs2 <= (1 => '1', others => '0');   
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '0');   
    wait for t_per;
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '1');   
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (1 => '0', others => '1');   
    wait for t_per;
    s_rs1 <= (1 => '0', others => '1');
    s_rs2 <= (others => '1');   
    wait for t_per;
        
    -- Test instr_SLTI - OK
    s_ctrl <= instr_SLTI;
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '0');   
    wait for t_per;
    s_rs1 <= (1 => '1', others => '0');
    s_rs2 <= (others => '0');   
    wait for t_per;
    s_rs1 <= (others => '0');
    s_rs2 <= (1 => '1', others => '0');   
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '0');   
    wait for t_per;
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '1');   
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (1 => '0', others => '1');   
    wait for t_per;
    s_rs1 <= (1 => '0', others => '1');
    s_rs2 <= (others => '1');   
    wait for t_per;
        
    -- Test instr_SLTU - OK
    s_ctrl <= instr_SLTU;
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '0');   
    wait for t_per;
    s_rs1 <= (1 => '1', others => '0');
    s_rs2 <= (others => '0');   
    wait for t_per;
    s_rs1 <= (others => '0');
    s_rs2 <= (1 => '1', others => '0');   
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '0');   
    wait for t_per;
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '1');   
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (1 => '0', others => '1');   
    wait for t_per;
    s_rs1 <= (1 => '0', others => '1');
    s_rs2 <= (others => '1');   
    wait for t_per;
        
    -- Test instr_SLTIU - OK
    s_ctrl <= instr_SLTIU;
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '0');   
    wait for t_per;
    s_rs1 <= (1 => '1', others => '0');
    s_rs2 <= (others => '0');   
    wait for t_per;
    s_rs1 <= (others => '0');
    s_rs2 <= (1 => '1', others => '0');   
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (others => '0');   
    wait for t_per;
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '1');   
    wait for t_per;
    s_rs1 <= (others => '1');
    s_rs2 <= (1 => '0', others => '1');   
    wait for t_per;
    s_rs1 <= (1 => '0', others => '1');
    s_rs2 <= (others => '1');   
    wait for t_per;
    wait for t_per;
        
    -- Test instr_SLLW - OK
    s_ctrl <= instr_SLLW;
    s_rs1 <= (0 => '1', others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (63 downto 59 => '1', others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (others => '1');
    wait for t_per;
    
    -- Test instr_SLLIW - OK
    s_ctrl <= instr_SLLIW;
    s_rs1 <= (0 => '1', others => '0');
    s_rs2 <= (others => '0');
    s_shamt <= "00000";
    wait for t_per;
    s_shamt <= "00001";
    wait for t_per;
    s_shamt <= "00010";
    wait for t_per;
    s_shamt <= "00011";
    wait for t_per;
    s_shamt <= "11111";
    wait for t_per;
    s_rs1 <= (63 downto 59 => '1', others => '0');
    s_shamt <= "00000";
    wait for t_per;
    s_shamt <= "00001";
    wait for t_per;
    s_shamt <= "00010";
    wait for t_per;
    s_shamt <= "00011";
    wait for t_per;
    s_shamt <= "11111";
    wait for t_per;
    
    -- Test instr_SRLW - OK
    s_ctrl <= instr_SRLW;
    s_rs1 <= (10 => '1', others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (63 downto 59 => '1', 30 downto 29 => '1', others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (others => '1');
    wait for t_per;
        
    -- Test instr_SRLIW - OK
    s_ctrl <= instr_SRLIW;
    s_rs1 <= (10 => '1', others => '0');
    s_rs2 <= (others => '0');
    s_shamt <= "00000";
    wait for t_per;
    s_shamt <= "00001";
    wait for t_per;
    s_shamt <= "00010";
    wait for t_per;
    s_shamt <= "00011";
    wait for t_per;
    s_shamt <= "11111";
    wait for t_per;
    s_rs1 <= (63 downto 59 => '1', 30 downto 29 => '1', others => '0');
    s_shamt <= "11011";
    wait for t_per;
    s_shamt <= "11100";
    wait for t_per;
    s_shamt <= "11101";
    wait for t_per;
    s_shamt <= "11110";
    wait for t_per;
    s_shamt <= "11111";
    wait for t_per;
        
    -- Test instr_SRAW - OK
    s_ctrl <= instr_SRAW;
    s_rs1 <= (10 => '1', others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (63 downto 59 => '1', 30 downto 29 => '1', others => '0');
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (1 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs2 <= (others => '1');
    wait for t_per;
        
    -- Test instr_SRAIW - OK
    s_ctrl <= instr_SRAIW;
    s_rs1 <= (10 => '1', others => '0');
    s_rs2 <= (others => '0');
    s_shamt <= "00000";
    wait for t_per;
    s_shamt <= "00001";
    wait for t_per;
    s_shamt <= "00010";
    wait for t_per;
    s_shamt <= "00011";
    wait for t_per;
    s_shamt <= "11111";
    wait for t_per;
    s_rs1 <= (63 downto 59 => '1', 30 downto 29 => '1', others => '0');
    s_shamt <= "11100";
    wait for t_per;
    s_shamt <= "11101";
    wait for t_per;
    s_shamt <= "11110";
    wait for t_per;
    s_shamt <= "11111";
    wait for t_per;
        
    -- Test instr_ADDW - OK
    s_ctrl <= instr_ADDW;
    s_rs1 <= (others => '0'); -- 0+0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0 + -8
    s_rs2 <= (2 downto 0 => '0', others => '1');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0 + 8
    s_rs2 <= (3 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (29 => '1', others => '0'); -- 268435456 + 0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (29 => '1', others => '0'); -- 268435456 + 4
    s_rs2 <= (2 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (29 => '1', others => '0'); -- 268435456 + -8
    s_rs2 <= (2 downto 0 => '0', others => '1');
    wait for t_per;
    s_rs1 <= (63 downto 31 => '1', others => '1'); -- max32 + 0 ignore upper word test
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
        
    -- Test instr_ADDIW - OK
    s_ctrl <= instr_ADDIW;
    s_rs1 <= (others => '0'); -- 0+0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0 + -8
    s_rs2 <= (2 downto 0 => '0', others => '1');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0 + 8
    s_rs2 <= (3 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (29 => '1', others => '0'); -- 268435456 + 0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (29 => '1', others => '0'); -- 268435456 + 4
    s_rs2 <= (2 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (29 => '1', others => '0'); -- 268435456 + -8
    s_rs2 <= (2 downto 0 => '0', others => '1');
    wait for t_per;
    s_rs1 <= (63 downto 31 => '0', others => '1'); -- max32 + 0 ignore upper word test
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
        
    -- Test instr_SUBW - OK
    s_ctrl <= instr_SUBW;
    s_rs1 <= (others => '0'); -- 0-0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0 - -8
    s_rs2 <= (2 downto 0 => '0', others => '1');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0 + -8
    s_rs2 <= (3 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (29 => '1', others => '0'); -- 268435456 - 0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (29 => '1', others => '0'); -- 268435456 - 4
    s_rs2 <= (2 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (29 => '1', others => '0'); -- 268435456 - -8
    s_rs2 <= (2 downto 0 => '0', others => '1');
    wait for t_per;
    s_rs1 <= (33 => '1', others => '0'); -- ignore upper word test
    s_rs2 <= (others => '1');
    wait for t_per;
        
    -- Test instr_MUL - OK
    s_ctrl <= instr_MUL;
    s_rs1 <= (others => '0'); -- 0*0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0*1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0*-1
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (0 => '1', others => '0'); -- 1 * 1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (0 => '1', others => '0'); -- 1 * -1
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (others => '1'); -- -1 * 1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '1'); -- -1 * -1
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (31 downto 0 => '1', others => '0'); --  result 1FFFFFFFF
    s_rs1 <= (31 downto 0 => '1', others => '0');
    wait for t_per;    
    s_rs1 <= (63 => '0', others => '1'); -- overflow positive "ignore arithmetic overflow"
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (63 => '1', others => '0'); -- overflow negative "ignore arithmetic overflow"
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
        
    -- Test instr_MULH (upper half of result written to rd)  - OK
    s_ctrl <= instr_MULH;
    s_rs1 <= (30 => '1', others => '0'); -- result shoud be 0
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (30 downto 0 => '1', others => '0'); -- result should be 1
    s_rs2 <= (2 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (63 downto 31 => '1', others => '0'); -- result should be x0FFFFFFFF
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (63 downto 31 => '1', others => '0'); -- result should be 1
    s_rs2 <= (0 => '0', others => '1');
    wait for t_per;
        
    -- Test instr_MULHU - OK
    s_ctrl <= instr_MULHU;
    s_rs1 <= (30 downto 0 => '1', others => '0'); -- result shoud be 0
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (31 => '1', others => '0'); -- result should be 1
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (31 downto 0 => '1', others => '0'); -- result should be 254
    s_rs2 <= (7 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (31 downto 0 => '1', others => '0'); -- result shoud be 4294967294
    s_rs2 <= (31 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (31 downto 0 => '1', others => '0'); -- result shoud be 0
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    wait for t_per;
        
    -- Test instr_MULHSU - Misses the first computation, correct thereafter.  May need to follow this with a NOP or find a different soln.
    s_ctrl <= instr_MULHSU;
    s_rs1 <= (30 downto 0 => '1', others => '0'); -- result shoud be 0
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (30 downto 0 => '1', others => '0'); -- result should be 1
    s_rs2 <= (2 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '1'); -- result should be 0x0ffffffff
    s_rs2 <= (31 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '1'); -- result shoud be 0x0fffffff
    s_rs2 <= (31 downto 0 => '1', others => '0');
    wait for t_per;
        
    -- Test instr_DIV - OK
    s_ctrl <= instr_DIV;
    s_rs1 <= (others => '0'); -- 0/0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0/1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0/-1
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (0 => '1', others => '0'); -- 1/1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '1'); -- -1/1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (0 => '1', others => '0'); -- 1/-1
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (47 downto 0 => '1', others => '0'); -- FFFFFFFFFFFF/7FFFFFFF = x20000
    s_rs2 <= (30 downto 0 => '1', others => '0');
    wait for t_per;
        
    -- Test instr_DIVU - OK
    s_ctrl <= instr_DIVU;
    s_rs1 <= (others => '0'); -- 0/0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0/1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0/max
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (0 => '1', others => '0'); -- 1/1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '1'); -- max/max
    s_rs2 <= (others => '1');
    wait for t_per;
    wait for t_per;
    s_rs1 <= (47 downto 0 => '1', others => '0'); -- FFFFFFFFFFFF/FFFFFFFF = x10000
    s_rs2 <= (31 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (47 downto 0 => '1', others => '0'); -- FFFFFFFFFFFF/FFFFFFFF = x0
    s_rs2 <= (48 downto 0 => '1', others => '0');
    wait for t_per;
        
    -- Test instr_REM - OK
    s_ctrl <= instr_REM;
    s_rs1 <= (others => '0');   -- 0/0 r 0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (0 => '1', others => '0');   -- 1/0 r 1
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '1'); -- -1/0 r -1
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (1 => '1', others => '0'); -- 2/2 r 0
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (5 downto 0 => '1', others => '0'); -- 63 / 2 r 1
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (5 downto 1 => '0', others => '1'); -- -63/2 r -1
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
        
    -- Test instr_REMU - OK
    s_ctrl <= instr_REMU;
    s_rs1 <= (others => '0');   -- 0/0 r 0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (0 => '1', others => '0');   -- 1/0 r 1
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '1'); -- max/0 r max
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (1 => '1', others => '0'); -- 1/1 r 0
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (5 downto 0 => '1', others => '0'); -- 63 / 2 r 1
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
        
    -- Test instr_MULW -- truncate result to 32 bits, sign extended
    s_ctrl <= instr_MULW;
    s_rs1 <= (others => '0'); -- 0*0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0*1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0*-1
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (0 => '1', others => '0'); -- 1 * 1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (0 => '1', others => '0'); -- 1 * -1
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (others => '1'); -- -1 * 1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '1'); -- -1 * -1
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (30 downto 0 => '1', others => '0'); --  result 1
    s_rs1 <= (30 downto 0 => '1', others => '0');
    wait for t_per;    
    s_rs1 <= (31 downto 0 => '1', others => '0'); -- result x80000001
    s_rs2 <= (30 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '1'); -- result xFFFFFFC1
    s_rs2 <= (5 downto 0 => '1', others => '0');
    wait for t_per;
        
    -- Test instr_DIVW - OK
    s_ctrl <= instr_DIVW;
    s_rs1 <= (others => '0'); -- 0/0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0/1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0/max
    s_rs2 <= (63 downto 31=> '0', others => '1');
    wait for t_per;
    s_rs1 <= (0 => '1', others => '0'); -- 1/1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (63 downto 31=> '0', others => '1'); -- max/max
    s_rs2 <= (63 downto 31=> '0', others => '1');
    wait for t_per;
    s_rs1 <= (62 downto 0 => '1', others => '0'); -- 7FFF FFFF FFFFFFFF/FFFFFFFF = xffffffff80000000 
    s_rs2 <= (31 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (31 downto 0 => '0', 63 => '0', others => '1'); -- 7FFFFFFFF0000000/FFFFFFFF = x0 
    s_rs2 <= (31 downto 0 => '1', others => '0');
    wait for t_per;
        
    -- Test instr_DIVUW - OK
    s_ctrl <= instr_DIVUW;
    s_rs1 <= (others => '0'); -- 0/0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0/1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '0'); -- 0/max
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (0 => '1', others => '0'); -- 1/1
    s_rs2 <= (0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '1'); -- max/max
    s_rs2 <= (others => '1');
    wait for t_per;
    s_rs1 <= (others => '1'); -- FFFFFFFF FFFFFFFF/FFFFFFFF = all 1's
    s_rs2 <= (31 downto 0 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (63 downto 32 => '1', others => '0'); -- FFFFFFFFF0000000/FFFFFFFF = x0 
    s_rs2 <= (31 downto 0 => '1', others => '0');
    wait for t_per;
        
    -- Test instr_REMW - OK
    s_ctrl <= instr_REMW;
    s_rs1 <= (others => '0'); --  expect 0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (1 downto 0 => '1', others => '0'); -- expect 1
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '1'); --  expect -1
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (2 => '1', others => '0'); -- expect 0
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (6 => '1', others => '0'); -- expect 4
    s_rs2 <= (3 => '1', 1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (5 downto 0 => '0', others => '1'); -- expect -4
    s_rs2 <= ( 3 => '1', 1 => '1', others => '0');
    wait for t_per;
        
    -- Test instr_REMUW - OK 
    s_ctrl <= instr_REMUW;
    s_rs1 <= (others => '0'); --  expect 0
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (1 downto 0 => '1', others => '0'); -- expect 1
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (others => '1'); --  expect xffffffff
    s_rs2 <= (others => '0');
    wait for t_per;
    s_rs1 <= (2 => '1', others => '0'); -- expect the Spanish inquisition
    s_rs2 <= (1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (6 => '1', others => '0'); -- expect 4
    s_rs2 <= (3 => '1', 1 => '1', others => '0');
    wait for t_per;
    s_rs1 <= (5 downto 0 => '0', others => '1'); -- expect 2
    s_rs2 <= ( 3 => '1', 1 => '1', others => '0');
    wait for t_per;
    
    wait;
end process;
end Behavioral;
