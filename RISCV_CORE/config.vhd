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

    -- Masks for CSR access
    -- NOTES:  Unacceptable with our Vivado version:
    -- constant MASK_WIRI_MIP: std_logic_vector(63 downto 0) := x"bbb"; -- Can't elaborate, but looks fine in IDE
    -- constant MASK_WIRI_MIP: std_logic_vector(63 downto 0) := std_logic_vector(to_unsigned(x"bbb")); -- Thinks this is a string literal
    -- constant MASK_WIRI_MIP: std_logic_vector(63 downto 0) := std_logic_vector(to_unsigned(16#bbb#)); -- Needs bit size for result
    constant MASK_WIRI_MIP: std_logic_vector(63 downto 0) := std_logic_vector(to_unsigned(16#bbb#, 64));
    constant MASK_WIRI_MIE: std_logic_vector(63 downto 0) := std_logic_vector(to_unsigned(16#bbb#, 64));
    constant MASK_WIRI_SIP: std_logic_vector(63 downto 0) := std_logic_vector(to_unsigned(16#db#, 64));
    constant MASK_WIRI_SIE: std_logic_vector(63 downto 0) := std_logic_vector(to_unsigned(16#0#, 64));
    constant MASK_A: std_logic_vector(63 downto 0) := std_logic_vector(to_unsigned(16#0#, 64));
    constant MASK_AB: std_logic_vector(63 downto 0) := std_logic_vector(to_unsigned(16#0#, 64));
    constant MASK_AC: std_logic_vector(63 downto 0) := std_logic_vector(to_unsigned(16#0#, 64));
    constant MASK_AD: std_logic_vector(63 downto 0) := std_logic_vector(to_unsigned(16#0#, 64));
    constant MASK_AE: std_logic_vector(63 downto 0) := std_logic_vector(to_unsigned(16#0#, 64));
    constant MASK_AF: std_logic_vector(63 downto 0) := std_logic_vector(to_unsigned(16#0#, 64));
    constant MASK_AG: std_logic_vector(63 downto 0) := std_logic_vector(to_unsigned(16#0#, 64));

    -- Special CSR return values for r/w filter functions
    constant CSR_TRAP_VALUE   : doubleword := (others => '0');
    constant CSR_IGNORE_VALUE : doubleword := (others => '1');

    -- Familiar names for CSR registers
    constant CSR_ERROR      :integer := -1; -- Not implemented, trap
    constant CSR_ZERO       :integer := 0; -- Not implemented, read 0, ignore write
    constant CSR_FFLAGS     :integer := 1;
    constant CSR_FRM        :integer := 2;
    constant CSR_FCSR       :integer := 3;
    constant CSR_CYCLE      :integer := 4;
    constant CSR_TIME       :integer := 5;
    constant CSR_INSTRET    :integer := 6;
    constant CSR_SIE        :integer := 7;
    constant CSR_STVEC      :integer := 8;
    constant CSR_SCOUNTEREN :integer := 9;
    constant CSR_SSCRATCH   :integer := 10;
    constant CSR_SEPC       :integer := 11;
    constant CSR_SCAUSE     :integer := 12;
    constant CSR_STVAL      :integer := 13;
    constant CSR_SIP        :integer := 14;
    constant CSR_SSTATUS    :integer := 15;
    constant CSR_SATP       :integer := 16;
    constant CSR_MSTATUS    :integer := 17;
    constant CSR_MISA       :integer := 18;
    constant CSR_MEDELEG    :integer := 19;
    constant CSR_MIDELEG    :integer := 20;
    constant CSR_MIE        :integer := 21;
    constant CSR_MTVEC      :integer := 22;
    constant CSR_MCOUNTEREN :integer := 23;
    constant CSR_MSCRATCH   :integer := 24;
    constant CSR_MEPC       :integer := 25;
    constant CSR_MCAUSE     :integer := 26;
    constant CSR_MTVAL      :integer := 27;
    constant CSR_MIP        :integer := 28;
    constant CSR_MCYCLE     :integer := 29;
    constant CSR_MINSTRET   :integer := 30;

    -- CSR 12-bit addresses per specification
    constant CSR_ADDR_USTATUS : std_logic_vector(11 downto 0) := x"000";
    constant CSR_ADDR_UIE : std_logic_vector(11 downto 0) := x"004";
    constant CSR_ADDR_UTVEC : std_logic_vector(11 downto 0) := x"005";
    constant CSR_ADDR_USCRATCH : std_logic_vector(11 downto 0) := x"040";
    constant CSR_ADDR_UEPC : std_logic_vector(11 downto 0) := x"041";
    constant CSR_ADDR_UCAUSE : std_logic_vector(11 downto 0) := x"042";
    constant CSR_ADDR_UTVAL : std_logic_vector(11 downto 0) := x"043";
    constant CSR_ADDR_UIP : std_logic_vector(11 downto 0) := x"044";
    constant CSR_ADDR_FFLAGS : std_logic_vector(11 downto 0) := x"001";
    constant CSR_ADDR_FRM : std_logic_vector(11 downto 0) := x"002";
    constant CSR_ADDR_FCSR : std_logic_vector(11 downto 0) := x"003";
    constant CSR_ADDR_CYCLE : std_logic_vector(11 downto 0) := x"c00";
    constant CSR_ADDR_TIME : std_logic_vector(11 downto 0) := x"c01";
    constant CSR_ADDR_INSTRET : std_logic_vector(11 downto 0) := x"c02";
    constant CSR_ADDR_HPMCOUNTER3: std_logic_vector(11 downto 0) := x"c03";
    constant CSR_ADDR_HPMCOUNTER4: std_logic_vector(11 downto 0) := x"c04";
    constant CSR_ADDR_HPMCOUNTER5: std_logic_vector(11 downto 0) := x"c05";
    constant CSR_ADDR_HPMCOUNTER6: std_logic_vector(11 downto 0) := x"c06";
    constant CSR_ADDR_HPMCOUNTER7: std_logic_vector(11 downto 0) := x"c07";
    constant CSR_ADDR_HPMCOUNTER8: std_logic_vector(11 downto 0) := x"c08";
    constant CSR_ADDR_HPMCOUNTER9: std_logic_vector(11 downto 0) := x"c09";
    constant CSR_ADDR_HPMCOUNTER10: std_logic_vector(11 downto 0) := x"c0a";
    constant CSR_ADDR_HPMCOUNTER11: std_logic_vector(11 downto 0) := x"c0b";
    constant CSR_ADDR_HPMCOUNTER12: std_logic_vector(11 downto 0) := x"c0c";
    constant CSR_ADDR_HPMCOUNTER13: std_logic_vector(11 downto 0) := x"c0d";
    constant CSR_ADDR_HPMCOUNTER14: std_logic_vector(11 downto 0) := x"c0e";
    constant CSR_ADDR_HPMCOUNTER15: std_logic_vector(11 downto 0) := x"c0f";
    constant CSR_ADDR_HPMCOUNTER16: std_logic_vector(11 downto 0) := x"c10";
    constant CSR_ADDR_HPMCOUNTER17: std_logic_vector(11 downto 0) := x"c11";
    constant CSR_ADDR_HPMCOUNTER18: std_logic_vector(11 downto 0) := x"c12";
    constant CSR_ADDR_HPMCOUNTER19: std_logic_vector(11 downto 0) := x"c13";
    constant CSR_ADDR_HPMCOUNTER20: std_logic_vector(11 downto 0) := x"c14";
    constant CSR_ADDR_HPMCOUNTER21: std_logic_vector(11 downto 0) := x"c15";
    constant CSR_ADDR_HPMCOUNTER22: std_logic_vector(11 downto 0) := x"c16";
    constant CSR_ADDR_HPMCOUNTER23: std_logic_vector(11 downto 0) := x"c17";
    constant CSR_ADDR_HPMCOUNTER24: std_logic_vector(11 downto 0) := x"c18";
    constant CSR_ADDR_HPMCOUNTER25: std_logic_vector(11 downto 0) := x"c19";
    constant CSR_ADDR_HPMCOUNTER26: std_logic_vector(11 downto 0) := x"c1a";
    constant CSR_ADDR_HPMCOUNTER27: std_logic_vector(11 downto 0) := x"c1b";
    constant CSR_ADDR_HPMCOUNTER28: std_logic_vector(11 downto 0) := x"c1c";
    constant CSR_ADDR_HPMCOUNTER29: std_logic_vector(11 downto 0) := x"c1d";
    constant CSR_ADDR_HPMCOUNTER30: std_logic_vector(11 downto 0) := x"c1e";
    constant CSR_ADDR_HPMCOUNTER31 : std_logic_vector(11 downto 0) := x"c1f";
    constant CSR_ADDR_SSTATUS : std_logic_vector(11 downto 0) := x"100";
    constant CSR_ADDR_SEDELEG : std_logic_vector(11 downto 0) := x"102";
    constant CSR_ADDR_SIDELEG : std_logic_vector(11 downto 0) := x"103";
    constant CSR_ADDR_SIE : std_logic_vector(11 downto 0) := x"104";
    constant CSR_ADDR_STVEC : std_logic_vector(11 downto 0) := x"105";
    constant CSR_ADDR_SCOUNTEREN : std_logic_vector(11 downto 0) := x"106";
    constant CSR_ADDR_SSCRATCH : std_logic_vector(11 downto 0) := x"140";
    constant CSR_ADDR_SEPC : std_logic_vector(11 downto 0) := x"141";
    constant CSR_ADDR_SCAUSE : std_logic_vector(11 downto 0) := x"142";
    constant CSR_ADDR_STVAL : std_logic_vector(11 downto 0) := x"143";
    constant CSR_ADDR_SIP : std_logic_vector(11 downto 0) := x"144";
    constant CSR_ADDR_SATP : std_logic_vector(11 downto 0) := x"180";
    constant CSR_ADDR_MVENDORID : std_logic_vector(11 downto 0) := x"f11";
    constant CSR_ADDR_MARCHID : std_logic_vector(11 downto 0) := x"f12";
    constant CSR_ADDR_MIMPID : std_logic_vector(11 downto 0) := x"f13";
    constant CSR_ADDR_MHARTID : std_logic_vector(11 downto 0) := x"f14";
    constant CSR_ADDR_MSTATUS : std_logic_vector(11 downto 0) := x"300";
    constant CSR_ADDR_MISA : std_logic_vector(11 downto 0) := x"301";
    constant CSR_ADDR_MEDELEG : std_logic_vector(11 downto 0) := x"302";
    constant CSR_ADDR_MIDELEG : std_logic_vector(11 downto 0) := x"303";
    constant CSR_ADDR_MIE : std_logic_vector(11 downto 0) := x"304";
    constant CSR_ADDR_MTVEC : std_logic_vector(11 downto 0) := x"305";
    constant CSR_ADDR_MCOUNTEREN : std_logic_vector(11 downto 0) := x"306";
    constant CSR_ADDR_MSCRATCH : std_logic_vector(11 downto 0) := x"340";
    constant CSR_ADDR_MEPC : std_logic_vector(11 downto 0) := x"341";
    constant CSR_ADDR_MCAUSE : std_logic_vector(11 downto 0) := x"342";
    constant CSR_ADDR_MTVAL : std_logic_vector(11 downto 0) := x"343";
    constant CSR_ADDR_MIP : std_logic_vector(11 downto 0) := x"344";
    constant CSR_ADDR_MCYCLE : std_logic_vector(11 downto 0) := x"b00";
    constant CSR_ADDR_MINSTRET : std_logic_vector(11 downto 0) := x"b02";
    constant CSR_ADDR_MHPMCOUNTER3 : std_logic_vector(11 downto 0) := x"b03";
    constant CSR_ADDR_MHPMCOUNTER4 : std_logic_vector(11 downto 0) := x"b04";
    constant CSR_ADDR_MHPMCOUNTER5 : std_logic_vector(11 downto 0) := x"b05";
    constant CSR_ADDR_MHPMCOUNTER6 : std_logic_vector(11 downto 0) := x"b06";
    constant CSR_ADDR_MHPMCOUNTER7 : std_logic_vector(11 downto 0) := x"b07";
    constant CSR_ADDR_MHPMCOUNTER8 : std_logic_vector(11 downto 0) := x"b08";
    constant CSR_ADDR_MHPMCOUNTER9 : std_logic_vector(11 downto 0) := x"b09";
    constant CSR_ADDR_MHPMCOUNTER10 : std_logic_vector(11 downto 0) := x"b0a";
    constant CSR_ADDR_MHPMCOUNTER11 : std_logic_vector(11 downto 0) := x"b0b";
    constant CSR_ADDR_MHPMCOUNTER12 : std_logic_vector(11 downto 0) := x"b0c";
    constant CSR_ADDR_MHPMCOUNTER13 : std_logic_vector(11 downto 0) := x"b0d";
    constant CSR_ADDR_MHPMCOUNTER14 : std_logic_vector(11 downto 0) := x"b0e";
    constant CSR_ADDR_MHPMCOUNTER15 : std_logic_vector(11 downto 0) := x"b0f";
    constant CSR_ADDR_MHPMCOUNTER16 : std_logic_vector(11 downto 0) := x"b10";
    constant CSR_ADDR_MHPMCOUNTER17 : std_logic_vector(11 downto 0) := x"b11";
    constant CSR_ADDR_MHPMCOUNTER18 : std_logic_vector(11 downto 0) := x"b12";
    constant CSR_ADDR_MHPMCOUNTER19 : std_logic_vector(11 downto 0) := x"b13";
    constant CSR_ADDR_MHPMCOUNTER20 : std_logic_vector(11 downto 0) := x"b14";
    constant CSR_ADDR_MHPMCOUNTER21 : std_logic_vector(11 downto 0) := x"b15";
    constant CSR_ADDR_MHPMCOUNTER22 : std_logic_vector(11 downto 0) := x"b16";
    constant CSR_ADDR_MHPMCOUNTER23 : std_logic_vector(11 downto 0) := x"b17";
    constant CSR_ADDR_MHPMCOUNTER24 : std_logic_vector(11 downto 0) := x"b18";
    constant CSR_ADDR_MHPMCOUNTER25 : std_logic_vector(11 downto 0) := x"b19";
    constant CSR_ADDR_MHPMCOUNTER26 : std_logic_vector(11 downto 0) := x"b1a";
    constant CSR_ADDR_MHPMCOUNTER27 : std_logic_vector(11 downto 0) := x"b1b";
    constant CSR_ADDR_MHPMCOUNTER28 : std_logic_vector(11 downto 0) := x"b1c";
    constant CSR_ADDR_MHPMCOUNTER29 : std_logic_vector(11 downto 0) := x"b1d";
    constant CSR_ADDR_MHPMCOUNTER30 : std_logic_vector(11 downto 0) := x"b1e";
    constant CSR_ADDR_MHPMCOUNTER31 : std_logic_vector(11 downto 0) := x"b1f";
    constant CSR_ADDR_MHPMEVENT3 : std_logic_vector(11 downto 0) := x"323";
    constant CSR_ADDR_MHPMEVENT4 : std_logic_vector(11 downto 0) := x"324";
    constant CSR_ADDR_MHPMEVENT5 : std_logic_vector(11 downto 0) := x"325";
    constant CSR_ADDR_MHPMEVENT6 : std_logic_vector(11 downto 0) := x"326";
    constant CSR_ADDR_MHPMEVENT7 : std_logic_vector(11 downto 0) := x"327";
    constant CSR_ADDR_MHPMEVENT8 : std_logic_vector(11 downto 0) := x"328";
    constant CSR_ADDR_MHPMEVENT9 : std_logic_vector(11 downto 0) := x"329";
    constant CSR_ADDR_MHPMEVENT10 : std_logic_vector(11 downto 0) := x"32a";
    constant CSR_ADDR_MHPMEVENT11 : std_logic_vector(11 downto 0) := x"32b";
    constant CSR_ADDR_MHPMEVENT12 : std_logic_vector(11 downto 0) := x"32c";
    constant CSR_ADDR_MHPMEVENT13 : std_logic_vector(11 downto 0) := x"32d";
    constant CSR_ADDR_MHPMEVENT14 : std_logic_vector(11 downto 0) := x"32e";
    constant CSR_ADDR_MHPMEVENT15 : std_logic_vector(11 downto 0) := x"32f";
    constant CSR_ADDR_MHPMEVENT16 : std_logic_vector(11 downto 0) := x"330";
    constant CSR_ADDR_MHPMEVENT17 : std_logic_vector(11 downto 0) := x"331";
    constant CSR_ADDR_MHPMEVENT18 : std_logic_vector(11 downto 0) := x"332";
    constant CSR_ADDR_MHPMEVENT19 : std_logic_vector(11 downto 0) := x"333";
    constant CSR_ADDR_MHPMEVENT20 : std_logic_vector(11 downto 0) := x"334";
    constant CSR_ADDR_MHPMEVENT21 : std_logic_vector(11 downto 0) := x"335";
    constant CSR_ADDR_MHPMEVENT22 : std_logic_vector(11 downto 0) := x"336";
    constant CSR_ADDR_MHPMEVENT23 : std_logic_vector(11 downto 0) := x"337";
    constant CSR_ADDR_MHPMEVENT24 : std_logic_vector(11 downto 0) := x"338";
    constant CSR_ADDR_MHPMEVENT25 : std_logic_vector(11 downto 0) := x"339";
    constant CSR_ADDR_MHPMEVENT26 : std_logic_vector(11 downto 0) := x"33a";
    constant CSR_ADDR_MHPMEVENT27 : std_logic_vector(11 downto 0) := x"33b";
    constant CSR_ADDR_MHPMEVENT28 : std_logic_vector(11 downto 0) := x"33c";
    constant CSR_ADDR_MHPMEVENT29 : std_logic_vector(11 downto 0) := x"33d";
    constant CSR_ADDR_MHPMEVENT30 : std_logic_vector(11 downto 0) := x"33e";
    constant CSR_ADDR_MHPMEVENT31 : std_logic_vector(11 downto 0) := x"33f";
    
    -- Privilege modes
    constant USER_MODE : std_logic_vector(1 downto 0) := "00";
    constant SUPERVISOR_MODE : std_logic_vector(1 downto 0) := "01";
    constant MACHINE_MODE : std_logic_vector(1 downto 0) := "11";
    
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

    -- Forward declare static functions
    function CSR_write(CSR: natural; value: doubleword) return doubleword;
    function CSR_read(CSR: natural; value: doubleword) return doubleword;


end package config;


-- Package body defined derived constants and subroutines (i.e. functions)
package body config is

    -- TODO - Might need additional parameters to specify the privilege mode, double check

    -- CSR function for writing as a function of CSR register
    --@param CSR The familiar name of the CSR register, encoded above in the package declaration
    --@param value The raw value to be written
    --@return the modified value to be written back the the given CSR
    function CSR_write(CSR: natural; value: doubleword) return doubleword is
    begin
        return zero_word & zero_word;
    end;
    
    -- CSR function for reading as a function of CSR register
    --@param CSR The familiar name of the CSR register, encoded above in the package declaration
    --@param value The raw contents of the given CSR
    --@return the adjusted value of the CSR to be reported back
    function CSR_read(CSR: natural; value: doubleword) return doubleword is
    begin
        return value;
    end;
end config;
