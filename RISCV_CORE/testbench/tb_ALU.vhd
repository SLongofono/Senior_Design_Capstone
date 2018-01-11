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
signal s_ctrl: ctrl_t := "000000";
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
    rst <= '0';
    
    s_rs1 <= (others => '0');
    s_rs2 <= (others => '0');
    wait for t_per/2;

    -- Test op_SLL
    s_ctrl <= op_SLL;
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

    
    -- Test op_SLLI
    s_ctrl <= op_SLLI;
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
    s_shamt <= "00011";
    wait for t_per;
    s_shamt <= "11111";
    wait for t_per;

        
    -- Test op_SRL
    s_ctrl <= op_SRL;
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

        
    -- Test op_SRLI
    s_ctrl <= op_SRLI;
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
        
    -- Test op_SRA
    s_ctrl <= op_SRA;
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

       
    -- Test op_SRAI
    s_ctrl <= op_SRAI;
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
        
 
    -- Test op_ADD
    s_ctrl <= op_ADD;
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
        
    -- Test op_ADDI

    wait for t_per;
        
    -- Test op_SUB

    wait for t_per;
        
    -- Test op_LUI

    wait for t_per;
        
    -- Test op_AUIPC

    wait for t_per;
        
    -- Test op_XOR

    wait for t_per;
        
    -- Test op_XORI

    wait for t_per;
        
    -- Test op_OR

    wait for t_per;
        
    -- Test op_ORI

    wait for t_per;
        
    -- Test op_AND

    wait for t_per;
        
    -- Test op_ANDI

    wait for t_per;
        
    -- Test op_SLT

    wait for t_per;
        
    -- Test op_SLTI

    wait for t_per;
        
    -- Test op_SLTU

    wait for t_per;
        
    -- Test op_SLTIU

    wait for t_per;
        
    -- Test op_SLLW

    wait for t_per;
        
    -- Test op_SLLIW

    wait for t_per;
        
    -- Test op_SRLW

    wait for t_per;
        
    -- Test op_SRLIW

    wait for t_per;
        
    -- Test op_SRAW

    wait for t_per;
        
    -- Test op_SRAIW

    wait for t_per;
        
    -- Test op_ADDW

    wait for t_per;
        
    -- Test op_ADDIW

    wait for t_per;
        
    -- Test op_SUBW

    wait for t_per;
        
    -- Test op_MUL

    wait for t_per;
        
    -- Test op_MULH

    wait for t_per;
        
    -- Test op_MULHU

    wait for t_per;
        
    -- Test op_MULHSU

    wait for t_per;
        
    -- Test op_DIV

    wait for t_per;
        
    -- Test op_DIVU

    wait for t_per;
        
    -- Test op_REM

    wait for t_per;
        
    -- Test op_REMU

    wait for t_per;
        
    -- Test op_MULW

    wait for t_per;
        
    -- Test op_DIVW

    wait for t_per;
        
    -- Test op_DIVUW

    wait for t_per;
        
    -- Test op_REMW

    wait for t_per;
        
    -- Test op_REMUW 

    wait for t_per;
 
    wait;
end process;
end Behavioral;
