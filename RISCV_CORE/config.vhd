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
    
    -- Familiar names for opcodes
    subtype opcode_t is std_logic_vector(6 downto 0);
    
    -- Load upper immediate
    constant LUI    : opcode_t := "0110111";

    -- Add upper immedaite to PC
    constant AUIPC  : opcode_t := "0010111";
    
    -- Jump and link
    constant JAL    : opcode_t := "1101111";
    
    -- Jump and link register
    constant JALR   : opcode_t := "1100111";
    
    -- Branch types, general
    constant BRANCH : opcode_t := "1100011";
    
    -- Load types, includes all but atomic load and LUI
    constant LOAD   : opcode_t := "0000011";
    
    -- Store types, includes all but atomic
    constant STORE  : opcode_t := "0100011";
    
    -- ALU immediate types
    constant ALUI   : opcode_t := "0010011";
    
    -- ALU types, includes integer mul/div
    constant ALU    : opcode_t := "0110011";
    
    -- Special fence instructions
    constant FENCE  : opcode_t := "0001111";
    
    -- CSR manipulation and ecalls
    constant CSR    : opcode_t := "1110011";
    
    -- ALU types, low word
    constant ALUW   : opcode_t := "0111011";
    
    -- ALU immediate types, low word
    constant ALUIW  : opcode_t := "0011011";
    
    -- Atomic types
    constant ATOM   : opcode_t := "0101111";
    
    -- Floating point load types
    constant FLOAD  : opcode_t := "0000111";
    
    -- Floating point store types
    constant FSTORE : opcode_t := "0100111";
    
    -- Floating point multiply-then-add
    constant FMADD  : opcode_t := "1000011";

    -- Floating point multiply-then-sub
    constant FMSUB  : opcode_t := "1000111";

    -- Floating point negate-multiply-then-add
    constant FNADD  : opcode_t := "1001011";

    -- Floating point negate-multiply-then-sub
    constant FNSUB  : opcode_t := "1001111";

    -- Floating point arithmetic types
    constant FPALU  : opcode_t := "1010011";
    
    
    
end package config;
