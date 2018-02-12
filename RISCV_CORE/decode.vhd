----------------------------------------------------------------------------------
-- Engineer: Longofono
-- 
-- Create Date: 11/06/2017 10:33:06 AM
-- Module Name: decode - Behavioral
-- Description: 
-- 
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
        instr       : in std_logic_vector(63 downto 0);
        instr_code  : out instr_t;
        funct3      : out funct3_t;
        funct6      : out funct6_t;
        funct7      : out funct7_t;
        imm12       : out std_logic_vector(11 downto 0); -- I, B, and S Immediates
        imm20       : out std_logic_vector(19 downto 0); -- U and J Immediates
        opcode      : out opcode_t;
        rs1         : out reg_t;
        rs2         : out reg_t;
        rs3         : out reg_t;
        rd          : out reg_t;
        shamt       : out std_logic_vector(4 downto 0);
        csr         : out std_logic_vector(31 downto 20)
    );
end decode;

architecture Behavioral of decode is

signal s_imm12 : std_logic_vector(11 downto 0);
signal s_imm20 : std_logic_vector(19 downto 0);
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
            s_imm20 <= instr(31 downto 12);
        when AUIPC_T =>
            s_instr_t <= instr_AUIPC;
            s_imm20 <= instr(31 downto 12);
        when JAL_T =>
            s_instr_t <= instr_JAL;
            s_imm20 <= instr(31 downto 12);
        when JALR_T =>
            s_instr_t <= instr_JALR;
            s_imm12 <= instr(31 downto 20);
        when BRANCH_T =>
            case instr(14 downto 12) is
                when "000" =>
                    s_instr_t <= instr_BEQ;
                    s_imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "001" => 
                    s_instr_t <= instr_BNE;
                    s_imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "100" => 
                    s_instr_t <= instr_BLT;
                    s_imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "101" => 
                    s_instr_t <= instr_BGE;
                    s_imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "110" => 
                    s_instr_t <= instr_BLTU;
                    s_imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "111" => 
                    s_instr_t <= instr_BGEU;
                    s_imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when others => -- error state
            end case; 
        when LOAD_T =>
            case instr(14 downto 12) is
                when "000" =>
                    s_instr_t <= instr_LB;
                    s_imm12 <= instr(31 downto 20);
                when "001" =>
                    s_instr_t <= instr_LH;
                    s_imm12 <= instr(31 downto 20);
                when "010" =>
                    s_instr_t <= instr_LW;
                    s_imm12 <= instr(31 downto 20);
                when "100" =>
                    s_instr_t <= instr_LBU;
                    s_imm12 <= instr(31 downto 20);
                when "101" =>
                    s_instr_t <= instr_LHU;
                    s_imm12 <= instr(31 downto 20);
                when "110" =>
                    s_instr_t <= instr_LWU;
                    s_imm12 <= instr(31 downto 20);
                when "011" =>
                    s_instr_t <= instr_LD;
                    s_imm12 <= instr(31 downto 20);
                when others => --error state
            end case;
        when STORE_T =>
            case instr(14 downto 12) is
                when "000" =>
                    s_instr_t <= instr_SB;
                    s_imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "001" => 
                    s_instr_t <= instr_SH;
                    s_imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "010" =>
                    s_instr_t <= instr_SW;
                    s_imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "011" =>
                    s_instr_t <= instr_SD;
                    s_imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when others => -- error state
            end case;
        when ALUI_T =>
            case instr(14 downto 12) is
                when "000" =>
                    s_instr_t <= instr_ADDI;
                    s_imm12 <= instr(31 downto 20);
                when "010" =>
                    s_instr_t <= instr_SLTI;
                    s_imm12 <= instr(31 downto 20);
                when "011" =>
                    s_instr_t <= instr_SLTIU;
                    s_imm12 <= instr(31 downto 20);
                when "100" =>
                    s_instr_t <= instr_XORI;
                    s_imm12 <= instr(31 downto 20);
                when "110" =>
                    s_instr_t <= instr_ORI;
                    s_imm12 <= instr(31 downto 20);
                when "111" =>
                    s_instr_t <= instr_ANDI;
                    s_imm12 <= instr(31 downto 20);
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
            if(instr(31 downto 25)="0000001") then
                -- Case RV32M
                case instr(14 downto 12) is
                    when "000" => s_instr_t <= instr_MUL;
                    when "001" => s_instr_t <= instr_MULH;
                    when "010" => s_instr_t <= instr_MULHSU;
                    when "011" => s_instr_t <= instr_MULHU;
                    when "100" => s_instr_t <= instr_DIV;
                    when "101" => s_instr_t <= instr_DIVU;
                    when "110" => s_instr_t <= instr_REM;
                    when "111" => s_instr_t <= instr_REMU;
                    when others => -- error state
                end case;
            else
                -- Case RV32I
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
                        if(instr(31 downto 25) = "0100000") then
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
            end if;        
        when FENCE_T =>
            if(instr(14 downto 12) = "000") then
                s_instr_t <= instr_FENCE;
            else
                s_instr_t <= instr_FENCEI;
            end if;
        when CSR_T =>
            case instr(14 downto 12) is
                when "000" =>
                    if(instr(31 downto 20) = "000000000000") then
                        s_instr_t <= instr_EBREAK;
                    elsif(instr(31 downto 20) = "000000000001") then
                        s_instr_t <= instr_ECALL;
                    elsif(instr(31 downto 20) = "000000000010") then
                        s_instr_t <= instr_URET;
                    elsif(instr(31 downto 20) = "000100000010") then
                        s_instr_t <= instr_SRET;
                    elsif(instr(31 downto 20) = "001100000010") then
                        s_instr_t <= instr_MRET;
                    elsif(instr(31 downto 20) = "000100000101") then
                        s_instr_t <= instr_WFI;
                    elsif(instr(31 downto 25) = "0001001") then
                        s_instr_t <= instr_SFENCEVM;
                    else
                    end if;
                when "001" =>
                    s_instr_t <= instr_CSRRW;
                    s_csr <= instr(31 downto 20);
                when "010" =>
                    s_instr_t <= instr_CSRRS;
                    s_csr <= instr(31 downto 20);
                when "011" =>
                    s_instr_t <= instr_CSRRC;
                    s_csr <= instr(31 downto 20);
                when "101" =>
                    s_instr_t <= instr_CSRRWI;
                    s_csr <= instr(31 downto 20);
                when "110" =>
                    s_instr_t <= instr_CSRRSI;
                    s_csr <= instr(31 downto 20);
                when "111" =>
                    s_instr_t <= instr_CSRRCI;
                    s_csr <= instr(31 downto 20);
                when others => -- error state
            end case;
        when ALUW_T =>
            if(instr(31 downto 25) = "0000001") then
            -- Case RV64M
                case instr(14 downto 12) is
                    when "000" => s_instr_t <= instr_MULW;
                    when "100" => s_instr_t <= instr_DIVW;
                    when "101" => s_instr_t <= instr_DIVUW;
                    when "110" => s_instr_t <= instr_REMW;
                    when "111" => s_instr_t <= instr_REMUW;
                    when others => --error state
                end case;
            else
            -- Case 64I ALU
                case instr(14 downto 12) is
                    when "000" =>
                        if(instr(31 downto 25) = "0100000") then
                            s_instr_t <= instr_SUBW;
                        else
                            s_instr_t <= instr_ADDW;
                        end if;
                    when "001" =>
                        s_instr_t <= instr_SLLW;
                    when "101" =>
                        if(instr(31 downto 25) = "0100000") then
                            s_instr_t <= instr_SRAW;
                        else
                            s_instr_t <= instr_SRLW;
                        end if;
                    when others => -- error state
                end case;
            end if;        
        when ALUIW_T =>
            -- case RV64I
            case instr(14 downto 12) is
                when "000" =>
                    s_instr_t <= instr_ADDIW;
                    s_imm12 <= instr(31 downto 20);
                when "001" =>
                    s_instr_t <= instr_SLLIW;
                    s_shamt <= instr(24 downto 20);
                when "101" =>
                    if(instr(31 downto 25) = "0100000") then
                        s_instr_t <= instr_SRAIW;
                        s_shamt <= instr(24 downto 20);
                    else
                        s_instr_t <= instr_SRLIW;
                        s_shamt <= instr(24 downto 20);
                    end if;
                when others => --error state
            end case;
        when ATOM_T =>
            if(instr(14 downto 12)="011") then
                -- case RV64A
                case instr(31 downto 27) is
                    when "00010" => s_instr_t <= instr_LRD;
                    when "00011" => s_instr_t <= instr_SCD;
                    when "00001" => s_instr_t <= instr_AMOSWAPD;
                    when "00000" => s_instr_t <= instr_AMOADDD;
                    when "00100" => s_instr_t <= instr_AMOXORD;
                    when "01100" => s_instr_t <= instr_AMOANDD;
                    when "01000" => s_instr_t <= instr_AMOORD;
                    when "10000" => s_instr_t <= instr_AMOMIND;
                    when "10100" => s_instr_t <= instr_AMOMAXD;
                    when "11000" => s_instr_t <= instr_AMOMINUD;
                    when "11100" => s_instr_t <= instr_AMOMAXUD;
                    when others => --error state
                end case;
            else
                -- case RV32A
                case instr(31 downto 27) is
                    when "00010" => s_instr_t <= instr_LRW;
                    when "00011" => s_instr_t <= instr_SCW;
                    when "00001" => s_instr_t <= instr_AMOSWAPW;
                    when "00000" => s_instr_t <= instr_AMOADDW;
                    when "00100" => s_instr_t <= instr_AMOXORW;
                    when "01100" => s_instr_t <= instr_AMOANDW;
                    when "01000" => s_instr_t <= instr_AMOORW;
                    when "10000" => s_instr_t <= instr_AMOMINW;
                    when "10100" => s_instr_t <= instr_AMOMAXW;
                    when "11000" => s_instr_t <= instr_AMOMINUW;
                    when "11100" => s_instr_t <= instr_AMOMAXUW;
                    when others => --error state
                end case;
            end if;
        when FLOAD_T =>
            case instr(14 downto 12) is
                when "010" =>
                    s_instr_t <= instr_FLW;
                    s_imm12 <= instr(31 downto 20);
                when "011" =>
                    s_instr_t <= instr_FLD;
                    s_imm12 <= instr(31 downto 20);
                when others => --error state
            end case;
        when FSTORE_T =>
            case instr(14 downto 12) is
                when "010" =>
                    s_instr_t <= instr_FSW;
                    s_imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when "011" =>
                    s_instr_t <= instr_FSD;
                    s_imm12 <= instr(31 downto 25) & instr(11 downto 7);
                when others => --error state
            end case;
        when FMADD_T =>
            if(instr(26 downto 25) = "00") then
                s_instr_t <= instr_FMADDS;
            else
                s_instr_t <= instr_FMADDD;
            end if;
        when FMSUB_T =>
            if(instr(26 downto 25) = "00") then
                s_instr_t <= instr_FMSUBS;
            else
                s_instr_t <= instr_FMSUBD;
            end if;
        when FNADD_T =>
            if(instr(26 downto 25) = "00") then
                s_instr_t <= instr_FNMADDS;
            else
                s_instr_t <= instr_FNMADDD;
            end if;
        when FNSUB_T =>
            if(instr(26 downto 25) = "00") then
                s_instr_t <= instr_FNMSUBS;
            else
                s_instr_t <= instr_FNMSUBD;
            end if;
        when FPALU_T =>
            case instr(31 downto 25) is
                when "0000000" =>
                    s_instr_t <= instr_FADDS;
                when "0000100" =>
                    s_instr_t <= instr_FSUBS;
                when "0001000" =>
                    s_instr_t <= instr_FMULS;
                when "0001100" =>
                    s_instr_t <= instr_FDIVS;
                when "0101100" =>
                    s_instr_t <= instr_FSQRTS;
                when "0010000" =>
                    if (instr(14 downto 12) = "000") then
                        s_instr_t <= instr_FSGNJS;
                    elsif (instr(14 downto 12) = "001") then
                        s_instr_t <= instr_FSGNJNS;
                    else
                        s_instr_t <= instr_FSGNJXS;
                    end if;
                when "0010100" =>
                    if(instr(14 downto 12) = "000") then
                        s_instr_t <= instr_FMINS;
                    else
                        s_instr_t <= instr_FMAXS;
                    end if;
                when "1100000" =>
                    if(instr(24 downto 20) = "00000") then
                        s_instr_t <= instr_FCVTWS;
                    elsif(instr(24 downto 20) = "00001") then
                        s_instr_t <= instr_FCVTWUS;
                    elsif(instr(24 downto 20) = "00010") then
                        s_instr_t <= instr_FCVTLS;
                    else
                            s_instr_t <= instr_FCVTLUS;
                    end if;
                when "1110000" =>
                    if(instr(14 downto 12) = "000") then
                        s_instr_t <= instr_FMVXW;
                    else
                        s_instr_t <= instr_FCLASSS;
                    end if;
                when "1010000" =>
                    if(instr(14 downto 12) = "010") then
                        s_instr_t <= instr_FEQS;
                    elsif(instr(14 downto 12) = "001") then
                        s_instr_t <= instr_FLTS;
                    else
                        s_instr_t <= instr_FLES;
                    end if;
                when "1101000" =>
                    if(instr(24 downto 20) = "00000") then
                        s_instr_t <= instr_FCVTSW;
                    elsif(instr(24 downto 20) = "00001") then
                        s_instr_t <= instr_FCVTSWU;
                    elsif(instr(24 downto 20) = "00010") then
                        s_instr_t <= instr_FCVTSL;
                    else
                        s_instr_t <= instr_FCVTSLU;
                    end if;
                when "1111000" =>
                    s_instr_t <= instr_FMVWX;
                when "0000001" =>
                    s_instr_t <= instr_FADDD;
                when "0000101" =>
                    s_instr_t <= instr_FSUBD;
                when "0001001" =>
                    s_instr_t <= instr_FMULD;
                when "0001101" =>
                    s_instr_t <= instr_FDIVD;
                when "0101101" =>
                    s_instr_t <= instr_FSQRTD;
                when "0010001" =>
                    if(instr(14 downto 12) = "000") then
                        s_instr_t <= instr_FSGNJD;
                    elsif(instr(14 downto 12) = "001") then
                        s_instr_t <= instr_FSGNJND;
                    else
                        s_instr_t <= instr_FSGNJXD;
                    end if;
                when "0010101" =>
                    if(instr(14 downto 12) = "000") then
                        s_instr_t <= instr_FMIND;
                    else
                        s_instr_t <= instr_FMAXD;
                    end if;
                when "0100000" =>
                    s_instr_t <= instr_FCVTSD;
                when "0100001" =>
                     s_instr_t <= instr_FCVTDS;
                when "1010001" =>
                    if(instr(14 downto 12) = "010") then
                        s_instr_t <= instr_FEQD;
                    elsif(instr(14 downto 12) = "001") then
                        s_instr_t <= instr_FLTD;
                    else
                        s_instr_t <= instr_FLED;    
                    end if;
                when "1110001" =>
                    if(instr(14 downto 12) = "001") then
                        s_instr_t <= instr_FCLASSD;
                    else
                        s_instr_t <= instr_FMVXD;
                    end if;
                when "1100001" =>
                    if(instr(24 downto 20) = "00000") then
                        s_instr_t <= instr_FCVTWD;
                    elsif(instr(24 downto 20) = "00001") then
                        s_instr_t <= instr_FCVTWUD;
                    elsif(instr(24 downto 20) = "00010") then
                        s_instr_t <= instr_FCVTLD;                
                    else
                        s_instr_t <= instr_FCVTLUD;                
                    end if;
                when "1101001" =>
                    if(instr(24 downto 20) = "00000") then
                        s_instr_t <= instr_FCVTDW;
                    elsif(instr(24 downto 20) = "00001") then
                        s_instr_t <= instr_FCVTDWU;
                    elsif(instr(24 downto 20) = "00010") then
                        s_instr_t <= instr_FCVTDL;
                    else
                        s_instr_t <= instr_FCVTDLU;
                    end if;
                when "1111001" =>
                    s_instr_t <= instr_FMVDX;                    
                when others => --error state
            end case;
        when others => -- error state
    end case;
end process;

rd <= instr(11 downto 7);
rs1 <= instr(19 downto 15);
rs2 <= instr(24 downto 20);
rs3 <= instr(31 downto 27);
funct3 <= instr(14 downto 12);
funct6 <= instr(31 downto 26);
funct7 <= instr(31 downto 25);
opcode <= instr(6 downto 0);
imm12 <= s_imm12;
imm20 <= s_imm20;
shamt <= s_shamt;
csr <= s_csr;
instr_code <= s_instr_t;

end Behavioral;
