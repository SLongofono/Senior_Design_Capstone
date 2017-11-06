----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Longofono
-- 
-- Create Date: 11/06/2017 10:33:06 AM
-- Design Name: 
-- Module Name: decode - Behavioral
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

-- Decode Unit
-- Determines the intruction type
-- Parses out all possible fields (whether or not they are relevant)
-- May sign extend and prepare a full immediate address, I'm not sure if
-- this is the right place to do this yet.  For now, just pulls the 12 or 20 bit
-- raw immediate value based on instruction type.  See config.vhd for typedefs and constants

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library config;
use work.config.all;

entity decode is
    Port(
        instr   : in std_logic_vector(63 downto 0);
        inst_t  : out instr_t;
        funct3  : out funct3_t;
        funct6  : out funct6_t;
        funct7  : out funct7_t;
        imm12   : out std_logic_vector(11 downto 0); -- I, B, and S Immediates
        imm20   : out std_logic_vector(20 downto 0); -- U and J Immediates
        opcode  : out opcode_t;
        rs1     : out reg_t;
        rs2     : out reg_t;
        rd      : out reg_t
    );
end decode;

architecture Behavioral of decode is

signal s_imm12 : std_logic_vector(11 downto 0);
signal s_imm20 : std_logic_vector(20 downto 0);
signal s_opcode: opcode_t;
signal s_inst_t: instr_t;

begin
-- Update instruction type whenever it changes
process(instr)
begin
    s_opcode <= instr(6 downto 0);
    s_imm12 <= (others => '0');
    s_imm20 <= (others => '0');
    s_inst_t<= (others => '1');
    case instr(6 downto 0) is
        when LUI_T =>;,
        when AUIPC_T => ;,
        when JAL_T =>;,
        when JALR_T =>;,
        when BRANCH_T =>;,
        when LOAD_T =>;,
        when STORE_T =>;,
        when ALUI_T =>;,
        when ALU_T =>;,
        when FENCE_T =>;,
        when CSR_T =>;,
        when ALUW_T =>;,
        when ALUIW_T =>;,
        when ATOM_T =>;,
        when FLOAD_T =>;,
        when FSTORE_T =>;,
        when FMADD_T =>;,
        when FMSUB_T =>;,
        when FNADD_T =>;,
        when FNSUB_T =>;,
        when FPALU_T =>;,
        when others => ;
    end case;
end process;

rd <= instr(11 downto 7);
rs1 <= instr(19 downto 15);
rs2 <= instr(24 downto 20);
funct3 <= instr(14 downto 12);
funct6 <= instr(14 downto 12);
funct7 <= instr(14 downto 12);
opcode <= s_opcode;
imm12 <= s_imm12;
imm20 <= s_imm20;

end Behavioral;
