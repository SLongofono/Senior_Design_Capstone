library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Rtype for register to register operations
-- Itype for immediate value to register operations and loading
-- Stype for storing
-- Utype for unconditional branch (jump)
-- SBtype for branches

package config is
    
    -- System word size
    subtype doubleword is std_logic_vector(63 downto 0);
    subtype word is std_logic_vector(31 downto 0);
    constant zero_word: std_logic_vector(31 downto 0) := "00000000000000000000000000000000";

    -- Familiar names for CSR registers
    constant CSR_MARCHID    :natural := 0;
    constant CSR_MCAUSE     :natural := 1;
    constant CSR_MCOUNTEREN :natural := 2;
    constant CSR_MEDELEG    :natural := 3;
    constant CSR_MEPC       :natural := 4;
    constant CSR_MHARTID    :natural := 5;
    constant CSR_MIDELEG    :natural := 6;
    constant CSR_MIE        :natural := 7;
    constant CSR_MIMPID     :natural := 8;
    constant CSR_MIP        :natural := 9;
    constant CSR_MSCRATCH   :natural := 10;
    constant CSR_MSTATUS    :natural := 11;
    constant CSR_MTVAL      :natural := 12;
    constant CSR_MTVEC      :natural := 13;
    constant CSR_MVENDORID  :natural := 14;
    constant CSR_SCAUSE     :natural := 15;
    constant CSR_SCOUNTEREN :natural := 16;
    constant CSR_SEDELEG    :natural := 17;
    constant CSR_SEPC       :natural := 18;
    constant CSR_SIDELEG    :natural := 19;
    constant CSR_SIE        :natural := 20;
    constant CSR_SIP        :natural := 21;
    constant CSR_SSCRATCH   :natural := 22;
    constant CSR_SSTATUS    :natural := 23;
    constant CSR_STVAL      :natural := 24;
    constant CSR_STVEC      :natural := 25;
    constant CSR_USTATUS    :natural := 26;
    constant CSR_UIE        :natural := 27;
    constant CSR_UTVEC      :natural := 28;
    constant CSR_USCRATCH   :natural := 29;
    constant CSR_UEPC       :natural := 30;
    constant CSR_UCAUSE     :natural := 31;
    constant CSR_UTVAL      :natural := 32;
    constant CSR_UIP        :natural := 33;
    constant CSR_UFFLAGS    :natural := 34;
    constant CSR_UFRM       :natural := 35;
    constant CSR_UFCSR      :natural := 36;
    constant CSR_UCYCLE     :natural := 37;
    constant CSR_UTIME      :natural := 38;
    constant CSR_UHPMCOUNTER:natural := 39;

    -- Debug output bus
    type regfile_arr is array (0 to 31) of doubleword;
    
    -- Familiar names for instruction fields
    subtype funct7_t is std_logic_vector(6 downto 0);
    subtype opcode_t is std_logic_vector(6 downto 0);
    subtype funct3_t is std_logic_vector(2 downto 0);
    subtype funct6_t is std_logic_vector(5 downto 0);
    subtype reg_t is std_logic_vector(4 downto 0);
    
    -- Instruction type populated by decoder
    subtype instr_t is std_logic_vector(7 downto 0);
    
    -- Control types for ALU
    subtype ctrl_t is std_logic_vector(5 downto 0);
    
    -- Opcodes determine overall instruction families, thus
    -- they are a logical way to group them.
    -- Load upper immediate
    constant LUI_T    : opcode_t := "0110111";

    -- Add upper immedaite to PC
    constant AUIPC_T  : opcode_t := "0010111";
    
    -- Jump and link
    constant JAL_T    : opcode_t := "1101111";
    
    -- Jump and link register
    constant JALR_T   : opcode_t := "1100111";
    
    -- Branch types, general
    constant BRANCH_T : opcode_t := "1100011";
    
    -- Load types, includes all but atomic load and LUI
    constant LOAD_T   : opcode_t := "0000011";
    
    -- Store types, includes all but atomic
    constant STORE_T  : opcode_t := "0100011";
    
    -- ALU immediate types
    constant ALUI_T   : opcode_t := "0010011";
    
    -- ALU types, includes integer mul/div
    constant ALU_T    : opcode_t := "0110011";
    
    -- Special fence instructions
    constant FENCE_T  : opcode_t := "0001111";
    
    -- CSR manipulation and ecalls
    constant CSR_T    : opcode_t := "1110011";
    
    -- ALU types, low word
    constant ALUW_T   : opcode_t := "0111011";
    
    -- ALU immediate types, low word
    constant ALUIW_T  : opcode_t := "0011011";
    
    -- Atomic types
    constant ATOM_T   : opcode_t := "0101111";
    
    -- Floating point load types
    constant FLOAD_T  : opcode_t := "0000111";
    
    -- Floating point store types
    constant FSTORE_T : opcode_t := "0100111";
    
    -- Floating point multiply-then-add
    constant FMADD_T  : opcode_t := "1000011";

    -- Floating point multiply-then-sub
    constant FMSUB_T  : opcode_t := "1000111";

    -- Floating point negate-multiply-then-add
    constant FNADD_T  : opcode_t := "1001011";

    -- Floating point negate-multiply-then-sub
    constant FNSUB_T  : opcode_t := "1001111";

    -- Floating point arithmetic types
    constant FPALU_T  : opcode_t := "1010011";
    
    -- Operation names for ALU
    constant op_SLL     : ctrl_t := "000000";
    constant op_SLLI    : ctrl_t := "000001";
    constant op_SRL     : ctrl_t := "000010";
    constant op_SRLI    : ctrl_t := "000011";
    constant op_SRA     : ctrl_t := "000100";
    constant op_SRAI    : ctrl_t := "000101";
    constant op_ADD     : ctrl_t := "000110";
    constant op_ADDI    : ctrl_t := "000111";
    constant op_SUB     : ctrl_t := "001000";
    constant op_LUI     : ctrl_t := "001001";
    constant op_AUIPC   : ctrl_t := "001010";
    constant op_XOR     : ctrl_t := "001011";
    constant op_XORI    : ctrl_t := "001100";
    constant op_OR      : ctrl_t := "001101";
    constant op_ORI     : ctrl_t := "001110";
    constant op_AND     : ctrl_t := "001111";
    constant op_ANDI    : ctrl_t := "010000";
    constant op_SLT     : ctrl_t := "010001";
    constant op_SLTI    : ctrl_t := "010010";
    constant op_SLTU    : ctrl_t := "010011";
    constant op_SLTIU   : ctrl_t := "010100";
    constant op_SLLW    : ctrl_t := "010101";
    constant op_SLLIW   : ctrl_t := "010110";
    constant op_SRLW    : ctrl_t := "010111";
    constant op_SRLIW   : ctrl_t := "011000";
    constant op_SRAW    : ctrl_t := "011001";
    constant op_SRAIW   : ctrl_t := "011010";
    constant op_ADDW    : ctrl_t := "011011";
    constant op_ADDIW   : ctrl_t := "011100";
    constant op_SUBW    : ctrl_t := "011101";
    constant op_MUL     : ctrl_t := "011110";
    constant op_MULH    : ctrl_t := "011111";
    constant op_MULHU   : ctrl_t := "100000";
    constant op_MULHSU  : ctrl_t := "100001";
    constant op_DIV     : ctrl_t := "100010";
    constant op_DIVU    : ctrl_t := "100011";
    constant op_REM     : ctrl_t := "100100";
    constant op_REMU    : ctrl_t := "100101";
    constant op_MULW    : ctrl_t := "100110";
    constant op_DIVW    : ctrl_t := "100111";
    constant op_DIVUW   : ctrl_t := "101000";
    constant op_REMW    : ctrl_t := "101001";
    constant op_REMUW   : ctrl_t := "101010";
   
    -- Instruction names for core (see intr.py to generate)
    constant instr_LUI      : instr_t := "00000000";
    constant instr_AUIPC    : instr_t := "00000001";
    constant instr_JAL      : instr_t := "00000010";
    constant instr_JALR     : instr_t := "00000011";
    constant instr_BEQ      : instr_t := "00000100";
    constant instr_BNE      : instr_t := "00000101";
    constant instr_BLT      : instr_t := "00000110";
    constant instr_BGE      : instr_t := "00000111";
    constant instr_BLTU     : instr_t := "00001000";
    constant instr_BGEU     : instr_t := "00001001";
    constant instr_LB       : instr_t := "00001010";
    constant instr_LH       : instr_t := "00001011";
    constant instr_LW       : instr_t := "00001100";
    constant instr_LBU      : instr_t := "00001101";
    constant instr_LHU      : instr_t := "00001110";
    constant instr_SB       : instr_t := "00001111";
    constant instr_SH       : instr_t := "00010000";
    constant instr_SW       : instr_t := "00010001";
    constant instr_ADDI     : instr_t := "00010010";
    constant instr_SLTI     : instr_t := "00010011";
    constant instr_SLTIU    : instr_t := "00010100";
    constant instr_XORI     : instr_t := "00010101";
    constant instr_ORI      : instr_t := "00010110";
    constant instr_ANDI     : instr_t := "00010111";
    constant instr_SLLI     : instr_t := "00011000";
    constant instr_SRLI     : instr_t := "00011001";
    constant instr_SRAI     : instr_t := "00011010";
    constant instr_ADD      : instr_t := "00011011";
    constant instr_SUB      : instr_t := "00011100";
    constant instr_SLL      : instr_t := "00011101";
    constant instr_SLT      : instr_t := "00011110";
    constant instr_SLTU     : instr_t := "00011111";
    constant instr_XOR      : instr_t := "00100000";
    constant instr_SRL      : instr_t := "00100001";
    constant instr_SRA      : instr_t := "00100010";
    constant instr_OR       : instr_t := "00100011";
    constant instr_AND      : instr_t := "00100100";
    constant instr_FENCE    : instr_t := "00100101";
    constant instr_FENCEI   : instr_t := "00100110";
    constant instr_ECALL    : instr_t := "00100111";
    constant instr_EBREAK   : instr_t := "00101000";
    constant instr_CSRRW    : instr_t := "00101001";
    constant instr_CSRRS    : instr_t := "00101010";
    constant instr_CSRRC    : instr_t := "00101011";
    constant instr_CSRRWI   : instr_t := "00101100";
    constant instr_CSRRSI   : instr_t := "00101101";
    constant instr_CSRRCI   : instr_t := "00101110";
    constant instr_LWU      : instr_t := "00101111";
    constant instr_LD       : instr_t := "00110000";
    constant instr_SD       : instr_t := "00110001";
    constant instr_SLLI6    : instr_t := "00110010";
    constant instr_SRLI6    : instr_t := "00110011";
    constant instr_SRAI6    : instr_t := "00110100";
    constant instr_ADDIW    : instr_t := "00110101";
    constant instr_SLLIW    : instr_t := "00110110";
    constant instr_SRLIW    : instr_t := "00110111";
    constant instr_SRAIW    : instr_t := "00111000";
    constant instr_ADDW     : instr_t := "00111001";
    constant instr_SUBW     : instr_t := "00111010";
    constant instr_SLLW     : instr_t := "00111011";
    constant instr_SRLW     : instr_t := "00111100";
    constant instr_SRAW     : instr_t := "00111101";
    constant instr_MUL      : instr_t := "00111110";
    constant instr_MULH     : instr_t := "00111111";
    constant instr_MULHSU   : instr_t := "01000000";
    constant instr_MULHU    : instr_t := "01000001";
    constant instr_DIV      : instr_t := "01000010";
    constant instr_DIVU     : instr_t := "01000011";
    constant instr_REM      : instr_t := "01000100";
    constant instr_REMU     : instr_t := "01000101";
    constant instr_MULW     : instr_t := "01000110";
    constant instr_DIVW     : instr_t := "01000111";
    constant instr_DIVUW    : instr_t := "01001000";
    constant instr_REMW     : instr_t := "01001001";
    constant instr_REMUW    : instr_t := "01001010";
    constant instr_LRW      : instr_t := "01001011";
    constant instr_SCW      : instr_t := "01001100";
    constant instr_AMOSWAPW : instr_t := "01001101";
    constant instr_AMOADDW  : instr_t := "01001110";
    constant instr_AMOXORW  : instr_t := "01001111";
    constant instr_AMOANDW  : instr_t := "01010000";
    constant instr_AMOORW   : instr_t := "01010001";
    constant instr_AMOMINW  : instr_t := "01010010";
    constant instr_AMOMAXW  : instr_t := "01010011";
    constant instr_AMOMINUW : instr_t := "01010100";
    constant instr_AMOMAXUW : instr_t := "01010101";
    constant instr_LRD      : instr_t := "01010110";
    constant instr_SCD      : instr_t := "01010111";
    constant instr_AMOSWAPD : instr_t := "01011000";
    constant instr_AMOADDD  : instr_t := "01011001";
    constant instr_AMOXORD  : instr_t := "01011010";
    constant instr_AMOANDD  : instr_t := "01011011";
    constant instr_AMOORD   : instr_t := "01011100";
    constant instr_AMOMIND  : instr_t := "01011101";
    constant instr_AMOMAXD  : instr_t := "01011110";
    constant instr_AMOMINUD : instr_t := "01011111";
    constant instr_AMOMAXUD : instr_t := "01100000";
    constant instr_FLW      : instr_t := "01100001";
    constant instr_FSW      : instr_t := "01100010";
    constant instr_FMADDS   : instr_t := "01100011";
    constant instr_FMSUBS   : instr_t := "01100100";
    constant instr_FNMSUBS  : instr_t := "01100101";
    constant instr_FNMADDS  : instr_t := "01100110";
    constant instr_FADDS    : instr_t := "01100111";
    constant instr_FSUBS    : instr_t := "01101000";
    constant instr_FMULS    : instr_t := "01101001";
    constant instr_FDIVS    : instr_t := "01101010";
    constant instr_FSQRTS   : instr_t := "01101011";
    constant instr_FSGNJS   : instr_t := "01101100";
    constant instr_FSGNJNS  : instr_t := "01101101";
    constant instr_FSGNJXS  : instr_t := "01101110";
    constant instr_FMINS    : instr_t := "01101111";
    constant instr_FMAXS    : instr_t := "01110000";
    constant instr_FCVTWS   : instr_t := "01110001";
    constant instr_FCVTWUS  : instr_t := "01110010";
    constant instr_FMVXW    : instr_t := "01110011";
    constant instr_FEQS     : instr_t := "01110100";
    constant instr_FLTS     : instr_t := "01110101";
    constant instr_FLES     : instr_t := "01110110";
    constant instr_FCLASSS  : instr_t := "01110111";
    constant instr_FCVTSW   : instr_t := "01111000";
    constant instr_FCVTSWU  : instr_t := "01111001";
    constant instr_FMVWX    : instr_t := "01111010";
    constant instr_FCVTLS   : instr_t := "01111011";
    constant instr_FCVTLUS  : instr_t := "01111100";
    constant instr_FCVTSL   : instr_t := "01111101";
    constant instr_FCVTSLU  : instr_t := "01111110";
    constant instr_FLD      : instr_t := "01111111";
    constant instr_FSD      : instr_t := "10000000";
    constant instr_FMADDD   : instr_t := "10000001";
    constant instr_FMSUBD   : instr_t := "10000010";
    constant instr_FNMSUBD  : instr_t := "10000011";
    constant instr_FNMADDD  : instr_t := "10000100";
    constant instr_FADDD    : instr_t := "10000101";
    constant instr_FSUBD    : instr_t := "10000110";
    constant instr_FMULD    : instr_t := "10000111";
    constant instr_FDIVD    : instr_t := "10001000";
    constant instr_FSQRTD   : instr_t := "10001001";
    constant instr_FSGNJD   : instr_t := "10001010";
    constant instr_FSGNJND  : instr_t := "10001011";
    constant instr_FSGNJXD  : instr_t := "10001100";
    constant instr_FMIND    : instr_t := "10001101";
    constant instr_FMAXD    : instr_t := "10001110";
    constant instr_FCVTSD   : instr_t := "10001111";
    constant instr_FCVTDS   : instr_t := "10010000";
    constant instr_FEQD     : instr_t := "10010001";
    constant instr_FLTD     : instr_t := "10010010";
    constant instr_FLED     : instr_t := "10010011";
    constant instr_FCLASSD  : instr_t := "10010100";
    constant instr_FCVTWD   : instr_t := "10010101";
    constant instr_FCVTWUD  : instr_t := "10010110";
    constant instr_FCVTDW   : instr_t := "10010111";
    constant instr_FCVTDWU  : instr_t := "10011000";
    constant instr_FCVTLD   : instr_t := "10011001";
    constant instr_FCVTLUD  : instr_t := "10011010";
    constant instr_FMVXD    : instr_t := "10011011";
    constant instr_FCVTDL   : instr_t := "10011100";
    constant instr_FCVTDLU  : instr_t := "10011101";
    constant instr_FMVDX    : instr_t := "10011110";
    constant instr_URET     : instr_t := "10011111";
    constant instr_SRET     : instr_t := "10100000";
    constant instr_MRET     : instr_t := "10100001";
    constant instr_WFI      : instr_t := "10100010";
    constant instr_SFENCEVM : instr_t := "10100011";

end package config;