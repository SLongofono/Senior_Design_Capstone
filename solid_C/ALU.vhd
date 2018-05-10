----------------------------------------------------------------------------------
-- Engineer: Longofono
-- 
-- Create Date: 12/04/2017 08:30:06 AM
-- Module Name: ALU - Behavioral
-- Description: 
-- 
-- Additional Comments: Omitted MULSHU because it is a special snowflake.
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use IEEE.NUMERIC_BIT.ALL;

library config;
use work.config.all;

entity ALU is
    Port(
        clk:        in std_logic;                       -- System clock
        rst:        in std_logic;                       -- Reset
        ctrl:       in instr_t;                          -- Operation
        rs1:        in doubleword;                      -- Source 1
        rs2:        in doubleword;                      -- Source 2
        shamt:      in std_logic_vector(4 downto 0);    -- shift amount
        rout:       out doubleword;                     -- Output Result
        error:      out std_logic;                      -- signal exception
        overflow:   out std_logic;                      -- signal overflow
        zero:       out std_logic                       -- signal zero result
    );
end ALU;

architecture Behavioral of ALU is

-- component declaration
component Shifter is
    port (
        clk : in std_logic;
        rst : in std_logic;
        ctrl: in instr_t;
        i_a1 : in std_logic_vector(63 downto 0);     -- Operand 1
        i_a2 : in std_logic_vector(5 downto 0);                -- Shift bits number
        result: out doubleword
    );
end component;

-- Signals and constants
constant all_bits_set : doubleword := (others => '1');

signal result: doubleword;
signal feedback: std_logic_vector(2 downto 0);  -- (Error, Overflow, Zero)

-- Shift unit signals
signal s_shift_amt: std_logic_vector(5 downto 0);
signal s_shift_arg: doubleword;
signal s_shift_result: doubleword;

begin

-- Instantiation
myShifter : Shifter
    port map(
        clk => clk,
        rst => rst,
        ctrl => ctrl,
        i_a1 => s_shift_arg, -- Operand 1
        i_a2 => s_shift_amt, -- Shift bits number
        result => s_shift_result
    );

process( clk )
    variable shift_limit: natural;
    variable mul_reg: std_logic_vector(127 downto 0);
    variable add_word: doubleword;
begin
--    shift_arg <= to_integer(unsigned(shamt));
    feedback <= "000";
    if(rising_edge(clk)) then
            case ctrl is
                -- Treat as 32-bit operands
                when instr_SLL =>
                    s_shift_amt <= rs2(5 downto 0);
                    s_shift_arg <= rs1;
                    result <= s_shift_result;
                when instr_SLLI =>
                    s_shift_amt <= '0' & shamt;
                    s_shift_arg <= rs1;
                    result <= s_shift_result;
                --    shift_limit := to_integer(unsigned(shamt));
                --    result <= zero_word & rs1(31 - shift_limit downto 0) & zero_word(shift_limit-1 downto 0);
                when instr_SRL =>
                    s_shift_amt <= rs2(5 downto 0);
                    s_shift_arg <= rs1;
                    result <= s_shift_result;
                when instr_SRLI =>                        
                    s_shift_amt <= '0' & shamt;
                    s_shift_arg <= rs1;
                    result <= s_shift_result;
                when instr_SRA =>                        
                    s_shift_amt <= rs2(5 downto 0);
                    s_shift_arg <= rs1;
                    result <= s_shift_result;
                when instr_SRAI =>                        
                    s_shift_amt <= '0' & shamt;
                    s_shift_arg <= rs1;
                    result <= s_shift_result;
                when instr_ADD =>
                    result <= std_logic_vector(signed(rs1) + signed(rs2));
                when instr_ADDI =>                        
                    result <= std_logic_vector(signed(rs1) + signed(rs2));
                    --if((result < rs1) or (result < rs2)) then
                        -- case overflow
                    --    feedback(1) <= '1';
                    --end if;
                when instr_SUB =>                        
                    result <= std_logic_vector(signed(rs1) - signed(rs2));
                    --if((result < rs1) or (result < rs2)) then
                        -- case overflow
                    --   feedback(1) <= '1';
                    --end if;
                when instr_LUI =>
                    -- In brief: rd = sign_extend(rsimm20 << 12)
                    -- Load low 20 of immediate value shifted left 12
                    -- sign extend to fit 64 bit system
                    result(31 downto 0) <= rs2(19 downto 0) & "000000000000";
                    result(63 downto 32) <= (others => rs2(19));
                when instr_AUIPC =>
                    -- TODO verify that PC can easily be passed in here as arg 1
                    -- In brief: rd = PC + (rs << 12)
                    -- Load 20 MSBs of low word with low 20 of immediate value
                    -- sign extend (rs << 12) to fit 64 bit
                    
                    -- NOTE: Here, we use a "qualified expression" to hint at how the compiler should resolve
                    --       the ambiguity.  We give a hint as to which overloaded function should be used,
                    --       in this case, the one that takes in a bit vector constant and a std_logic_vector
                    --       and returns a std_logic_vector.
                    --auipc_ext(31 downto 0) := std_logic_vector'(rs2(19 downto 0) & "000000000000");
                    
                    result <= std_logic_vector(signed(rs1) + signed(std_logic_vector'(rs2(19 downto 0) & "000000000000")));
                when instr_XOR =>
                    -- Assumption: immediate value in rs2 is already sign-extended                        
                    result <= rs1 xor rs2;
                when instr_XORI =>
                    -- Assumption: immediate value in rs2 is already sign-extended                        
                    result <= rs1 xor rs2;
                when instr_OR =>                        
                    -- Assumption: immediate value in rs2 is already sign-extended                        
                    result <= rs1 or rs2;
                when instr_ORI =>                        
                    -- Assumption: immediate value in rs2 is already sign-extended                        
                    result <= rs1 or rs2;
                when instr_AND =>                        
                    -- Assumption: immediate value in rs2 is already sign-extended                        
                    result <= rs1 and rs2;
                when instr_ANDI =>                        
                    -- Assumption: immediate value in rs2 is already sign-extended                        
                    result <= rs1 and rs2;
                when instr_SLT =>                        
                    if(signed(rs1) < signed(rs2)) then
                        result <= (0 => '1', others => '0');                       
                    else
                        result <= (others => '0');                       
                    end if;
                when instr_SLTI =>
                    if(signed(rs1) < signed(rs2)) then
                        result <= (0 => '1', others => '0');                       
                    else
                        result <= (others => '0');                       
                    end if;
                when instr_SLTU =>
                    -- Assumption: immediate value in rs2 is already sign-extended                        
                    if(unsigned(rs1) < unsigned(rs2)) then
                        result <= (0 => '1', others => '0');                       
                    else
                        result <= (others => '0');                       
                    end if;
                when instr_SLTIU =>                        
                    -- Assumption: immediate value in rs2 is already sign-extended                        
                    if(unsigned(rs1) < unsigned(rs2)) then
                        result <= (0 => '1', others => '0');                       
                    else
                        result <= (others => '0');                       
                    end if;
                when instr_SLLW =>
                    -- Since these are word operations instead of double
                    -- word operations, only use the bottom 5 bits instead of 6                       
                    s_shift_amt <= '0' & rs2(4 downto 0);
                    s_shift_arg <= rs1;
                    result <= s_shift_result;
                when instr_SLLIW =>                        
                    s_shift_amt <=  '0' & shamt;
                    s_shift_arg <= rs1;
                    result <= s_shift_result;
                when instr_SRLW =>                        
                    s_shift_amt <= '0' & rs2(4 downto 0);
                    s_shift_arg <= rs1;
                    result <= s_shift_result;
                when instr_SRLIW =>                        
                    s_shift_amt <= '0' & shamt;
                    s_shift_arg <= rs1;
                    result <= s_shift_result;
                when instr_SRAW =>                        
                    s_shift_amt <= '0' & rs2(4 downto 0);
                    s_shift_arg <= rs1;
                    result <= s_shift_result;
                when instr_SRAIW =>                        
                    s_shift_amt <= '0' & shamt;
                    s_shift_arg <= rs1;
                    result <= s_shift_result;
                when instr_ADDW =>                        
                    add_word := std_logic_vector(signed(rs1) + signed(rs2));                        
                    result(63 downto 32) <= (others => add_word(31));
                    result(31 downto 0) <= add_word(31 downto 0);
                when instr_ADDIW =>                                              
                    add_word := std_logic_vector(signed(rs1) + signed(rs2));
                    result(63 downto 32) <= (others => add_word(31));
                    result(31 downto 0) <= add_word(31 downto 0);
                when instr_SUBW =>                        
                    add_word := std_logic_vector(signed(rs1) - signed(rs2));
                    result(63 downto 32) <= (others => add_word(31));
                    result(31 downto 0) <= add_word(31 downto 0);
                when instr_MUL =>
                    mul_reg := std_logic_vector(signed(rs1) * signed(rs2));
                    result <= mul_reg(63 downto 0);
                when instr_MULH =>
                    mul_reg := std_logic_vector(signed(rs1) * signed(rs2));
                    result <= zero_word & mul_reg(63 downto 32);
                when instr_MULHU =>
                    mul_reg := std_logic_vector(unsigned(rs1) * unsigned(rs2));
                    result <= zero_word & mul_reg(63 downto 32);
                --when instr_MULHSU =>
                    -- TODO - verify that this multiplier does not introduce problems on the schematic/layout
                    --mul_reg_plus <= std_logic_vector(signed(rs1(31) & rs1) * signed('0' & rs2));
                    --result <= zero_word & mul_reg_plus(63 downto 32);
                    
                --  
                --  Special Values for Divide by Zero and Division Overflow (per 2.2 spec)
                --  Situation                           ||  Special Return Values for Each Instruction
                --  <condition> <Dividend>  <Divisor>   ||  <DIVU>          <REMU>      <DIV>       <REM>
                --  Divide by 0 x           0           ||  All bits set    x           -1          x
                --  Overflow    -(2^64 -1)  -1          ||  N/A             N/A         -(2^(64-1)) 0
                --
                
                when instr_DIV =>
                    if(zero_word = rs2(31 downto 0) and zero_word = rs2(63 downto 32)) then
                        -- case divide by zero, set result to -1 (all ones)
                        mul_reg := all_bits_set & all_bits_set;
                    elsif( (all_bits_set = rs1) and (-1 = to_integer(signed(rs2))) ) then
                        -- case division overflow, set only MSB
                        mul_reg := (63 => '1', others => '0');
                    else
                        mul_reg := zero_word & zero_word & std_logic_vector(signed(rs1) / signed(rs2));
                    end if;
                    result <= mul_reg(63 downto 0);
                when instr_DIVU => 
                    if(zero_word = rs2(31 downto 0) and zero_word = rs2(63 downto 32)) then
                        -- case divide by zero, set result to all ones
                        mul_reg := all_bits_set & all_bits_set;
                    else
                        mul_reg := zero_word & zero_word & std_logic_vector(unsigned(rs1) / unsigned(rs2));
                    end if;
                    result <= mul_reg(63 downto 0);
                when instr_REM =>
                    if(zero_word = rs2(31 downto 0) and zero_word = rs2(63 downto 32)) then
                        -- case divide by zero, set result to dividend
                        mul_reg := zero_word & zero_word & rs1;
                    elsif( (all_bits_set = rs1) and (-1 = to_integer(signed(rs2))) ) then
                        -- case division overflow, set result to 0
                        mul_reg := (others => '0');
                    else
                        mul_reg := zero_word & zero_word & std_logic_vector(signed(rs1) rem signed(rs2));
                    end if;
                    result(31 downto 0) <= mul_reg(31 downto 0);
                    result(63 downto 32) <= (others => mul_reg(31));
                when instr_REMU =>
                    if(zero_word = rs2(31 downto 0) and zero_word = rs2(63 downto 32)) then
                        -- case divide by zero, set result to dividend
                        mul_reg := zero_word & zero_word & rs1;
                    else
                        mul_reg := zero_word & zero_word & std_logic_vector(unsigned(rs1) rem unsigned(rs2));
                    end if;
                    result <= mul_reg(63 downto 0);
                when instr_MULW =>
                    mul_reg := zero_word & zero_word & std_logic_vector(signed(rs1(31 downto 0)) * signed(rs2(31 downto 0)));
                    result(63 downto 32) <= (others => mul_reg(31));
                    result(31 downto 0) <= mul_reg(31 downto 0);
                when instr_DIVW =>
                    if(zero_word = rs2(31 downto 0)) then
                        -- case divide by zero, set result to -1 (all ones)
                        mul_reg := all_bits_set & all_bits_set;
                    elsif( (all_bits_set(31 downto 0) = rs1(31 downto 0)) and (-1 = to_integer(signed(rs2(31 downto 0)))) ) then
                        -- case division overflow, set only MSB
                        mul_reg := (31 => '1', others => '0');
                    else
                        mul_reg := zero_word & zero_word & zero_word & std_logic_vector(signed(rs1(31 downto 0)) / signed(rs2(31 downto 0)));
                    end if;
                    result(63 downto 32) <= (others => mul_reg(31));
                    result(31 downto 0) <= mul_reg(31 downto 0);
                when instr_DIVUW => 
                    if(zero_word = rs2(31 downto 0)) then
                        -- case divide by zero, set result to all ones
                        mul_reg := all_bits_set & all_bits_set;
                    else
                        mul_reg := zero_word & zero_word & zero_word & std_logic_vector(unsigned(rs1(31 downto 0)) / unsigned(rs2(31 downto 0)));
                    end if;
                    result(63 downto 32) <= (others => mul_reg(31));
                    result(31 downto 0) <= mul_reg(31 downto 0);
                when instr_REMW =>
                    if(zero_word = rs2(31 downto 0)) then
                        -- case divide by zero, set result to dividend
                        mul_reg := zero_word & zero_word & rs1;
                    elsif( (all_bits_set(31 downto 0) = rs1(31 downto 0)) and (-1 = to_integer(signed(rs2(31 downto 0)))) ) then
                        -- case division overflow, set result to 0
                        mul_reg := (others => '0');
                    else
                        mul_reg := zero_word & zero_word & zero_word & std_logic_vector(signed(rs1(31 downto 0)) rem signed(rs2(31 downto 0)));
                    end if;
                    result(63 downto 32) <= (others => mul_reg(31));
                    result(31 downto 0) <= mul_reg(31 downto 0);
                when instr_REMUW =>
                    if(zero_word = rs2(31 downto 0)) then
                        -- case divide by zero, set result to dividend
                        mul_reg := zero_word & zero_word & rs1;
                    else
                        mul_reg := zero_word & zero_word & zero_word & std_logic_vector(unsigned(rs1(31 downto 0)) rem unsigned(rs2(31 downto 0)));
                    end if;
                    result(63 downto 32) <= (others => mul_reg(31));
                    result(31 downto 0) <= mul_reg(31 downto 0);
                when others =>
                    -- Error condition: unknown control code
                    feedback(0) <= '1';
                    result <= (others => '0');
            end case;
    end if; -- Clock

end process;

error <= feedback(0); -- TODO feedback single bit for error conditions.
overflow <= feedback(1);-- TODO check here, remove from logic above
zero <= '1' when (0 = unsigned(result)) else '0';
rout <= result;

end Behavioral;