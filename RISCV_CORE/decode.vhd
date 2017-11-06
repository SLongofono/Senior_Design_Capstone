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
        rd      : out reg_t;
        shamt   : out std_logic_vector(4 downto 0);
        csr     : out std_logic_vector(31 downto 20)
    );
end decode;

architecture Behavioral of decode is

signal s_imm12 : std_logic_vector(11 downto 0);
signal s_imm20 : std_logic_vector(20 downto 0);
signal s_instr_t: instr_t;
signal s_shamt: std_logic_vector(4 downto 0);
signal s_csr: std_logic_vector(11 downto 0);
begin
-- Update instruction type whenever it changes
process(instr)
begin
    s_imm12 <= (others => '0');
    s_imm20 <= (others => '0');
    s_instr_t<= (others => '1');
    s_shamt <= (others => '0');
    s_csr <= (others => '0');
    case instr(6 downto 0) is
        when LUI_T =>
            s_instr_t <= instr_LUI;
            imm20 <= instr(31 downto 12);
        when AUIPC_T =>
            s_instr_t <= instr_AUIPC;
            imm20 <= instr(31 downto 12);
        when JAL_T =>
            s_instr_t <= instr_JAL;
            imm20 <= instr(31 downto 12);
        when JALR_T =>
            s_instr_t <= instr_JALR;
            imm12 <= instr(31 downto 20);
        when BRANCH_T =>
            case instr(14 downto 12) is
                when "000" =>
                    s_instr_t <= instr_BEQ;
                    imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "001" => 
                    s_instr_t <= instr_BNE;
                    imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "100" => 
                    s_instr_t <= instr_BLT;
                    imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "101" => 
                    s_instr_t <= instr_BGE;
                    imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "110" => 
                    s_instr_t <= instr_BLTU;
                    imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "111" => 
                    s_instr_t <= instr_BGEU;
                    imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when others => -- error state
            end case; 
        when LOAD_T =>
            case instr(14 downto 12) is
                when "000" =>
                    s_instr_t <= instr_LB;
                    imm12 <= instr(31 downto 20);
                when "001" =>
                    s_instr_t <= instr_LH;
                    imm12 <= instr(31 downto 20);
                when "010" =>
                    s_instr_t <= instr_LW;
                    imm12 <= instr(31 downto 20);
                when "100" =>
                    s_instr_t <= instr_LBU;
                    imm12 <= instr(31 downto 20);
                when "101" =>
                    s_instr_t <= instr_LHU;
                    imm12 <= instr(31 downto 20);
                when others => --error state
            end case;
        when STORE_T =>
            case instr(14 downto 12) is
                when "000" =>
                    s_instr_t <= instr_SB;
                    imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "001" => 
                    s_instr_t <= instr_SH;
                    imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "010" =>
                    s_instr_t <= instr_SW;
                    imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when others => -- error state
            end case;
        when ALUI_T =>
            case instr(14 downto 12) is
                when "000" =>
                    s_instr_t <= instr_ADDI;
                    imm12 <= instr(31 downto 20);
                when "010" =>
                    s_instr_t <= instr_SLTI;
                    imm12 <= instr(31 downto 20);
                when "011" =>
                    s_instr_t <= instr_SLTIU;
                    imm12 <= instr(31 downto 20);
                when "100" =>
                    s_instr_t <= instr_XORI;
                    imm12 <= instr(31 downto 20);
                when "110" =>
                    s_instr_t <= instr_ORI;
                    imm12 <= instr(31 downto 20);
                when "111" =>
                    s_instr_t <= instr_ANDI;
                    imm12 <= instr(31 downto 20);
                when "001" =>
                    s_instr_t <= instr_SLLI;
                    s_shamt <= instr(24 downto 20);
                when "101" =>
                    if (instr(31 downto 25) = "0100000") then
                        s_instr_t <= instr_SRAI;
                        s_shamt <= instr(24 downto 20);
                    else
                        s_instr_t <= instr_SRLI;
                        s_shamt <= instr(24 downto 20);
                    end if;
                when others => -- error state
            end case;
        when ALU_T =>
            case instr(14 downto 12) is
                when "000" =>
                    if(instr(31 downto 25) = "0100000") then
                        s_instr_t <= instr_SUB;
                    else
                        s_instr_t <= instr_ADD;
                    end if;
                when "001" =>
                        s_instr_t <= instr_SLL;
                when "010" =>
                        s_instr_t <= instr_SLT;               
                when "011" =>
                        s_instr_t <= instr_SLTU;
                when "100" =>
                        s_instr_t <= instr_XOR;               
                when "101" =>
                    if(instr(31 downto 25) = "01000000") then
                        s_instr_t <= instr_SRA;
                    else
                        s_instr_t <= instr_SRL;
                    end if;
                when "110" =>
                        s_instr_t <= instr_OR;
                when "111" =>
                        s_instr_t <= instr_AND;
                when others => -- error state
            end case;        
        when FENCE_T =>
            if(instr(14 downto 12) = "000") then
                s_instr_t <= instr_FENCE;
            else
                s_instr_t <= instr_FENCEI;
            end if;
        when CSR_T =>
            case instr(14 downto 12) is
                when "000" =>
                    if(instr(20) = '1') then
                        s_instr_t <= instr_EBREAK;
                    else
                        s_instr_t <= instr_ECALL;
                    end if;
                when "001" =>
                    s_instr_t <= instr_CSRRW;
                when "010" =>
                    s_instr_t <= instr_CSRRS;
                when "011" =>
                    s_instr_t <= instr_CSRRC;
                when "101" =>
                    s_instr_t <= instr_CSRRWI;
                when "110" =>
                    s_instr_t <= instr_CSRRSI;
                when "111" =>
                    s_instr_t <= instr_CSRRCI;
                when others => -- error state
            end case;
        when ALUW_T =>;
        when ALUIW_T =>;
        when ATOM_T =>;
        when FLOAD_T =>;
        when FSTORE_T =>;
        when FMADD_T =>;
        when FMSUB_T =>;
        when FNADD_T =>;
        when FNSUB_T =>;
        when FPALU_T =>;
        when others => ;
    end case;
end process;

rd <= instr(11 downto 7);
rs1 <= instr(19 downto 15);
rs2 <= instr(24 downto 20);
funct3 <= instr(14 downto 12);
funct6 <= instr(31 downto 26);
funct7 <= instr(31 downto 25);
opcode <= instr(6 downto 0);
imm12 <= s_imm12;
imm20 <= s_imm20;
shamt <= s_shamt;
csr <= s_csr;
end Behavioral;
