----------------------------------------------------------------------------------
-- Engineer: Longofono
-- 
-- Create Date: 12/04/2017 08:30:06 AM
-- Module Name: ALU - Behavioral
-- Description: 
-- 
-- Additional Comments:
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
end ALU;

architecture Behavioral of ALU is

constant zero_word : std_logic_vector(31 downto 0) := (others => '0');
constant all_bits_set : doubleword := (others => '1');

signal result: doubleword;
signal feedback: std_logic_vector(2 downto 0);  -- (Error, Overflow, Zero)
signal shift_arg: natural;
signal preserved: natural;
signal auipc_ext: word;
signal mul_reg: doubleword;

begin

process(clk, rst)
begin
--    shift_arg <= to_integer(unsigned(shamt));
    feedback <= "000";
    if(rising_edge(clk)) then
        if('0' = halt) then
            if('1' = rst) then
                result <= (others => '0');
            else
                case ctrl is
                    -- Treat as 32-bit operands
                    when op_SLL =>
                        shift_arg <= to_integer(unsigned(rs2(5 downto 0)));
                        result <= std_logic_vector(shift_left(unsigned(rs1), shift_arg));
                    when op_SLLI =>
                        shift_arg <= to_integer(unsigned(shamt));
                        result <= std_logic_vector(shift_left(unsigned(rs1), shift_arg));
                    when op_SRL =>
                        shift_arg <= to_integer(unsigned(rs2(5 downto 0)));
                        result <= std_logic_vector(shift_right(unsigned(rs1), shift_arg));
                    when op_SRLI =>                        
                        shift_arg <= to_integer(unsigned(shamt));
                        result <= std_logic_vector(shift_right(unsigned(rs1), shift_arg));
                    when op_SRA =>                        
                        shift_arg <= to_integer(unsigned(rs2(5 downto 0)));
                        result <= std_logic_vector(shift_right(signed(rs1), shift_arg));
                    when op_SRAI =>                        
                        shift_arg <= to_integer(unsigned(shamt));
                        result <= std_logic_vector(shift_right(signed(rs1), shift_arg));
                    when op_ADD =>
                    when op_ADDI =>                        
                        result <= std_logic_vector(signed(rs1) + signed(rs2));
                        --if((result < rs1) or (result < rs2)) then
                            -- case overflow
                        --    feedback(1) <= '1';
                        --end if;
                    when op_SUB =>                        
                        result <= std_logic_vector(signed(rs1) - signed(rs2));
                        --if((result < rs1) or (result < rs2)) then
                            -- case overflow
                        --   feedback(1) <= '1';
                        --end if;
                    when op_LUI =>
                        -- In brief: rd = rs << 12
                        -- Load 20 MSBs of low word with low 20 of immediate value
                        -- sign extend to fit 64 bit system
                        result(31 downto 12) <= rs1(19 downto 0);
                        result(11 downto 0) <= (others => '0');
                        result(63 downto 32) <= (others => result(31));
                    when op_AUIPC =>
                        -- TODO verify that PC can easily be passed in here as arg 1
                        -- In brief: rd = PC + (rs << 12)
                        -- Load 20 MSBs of low word with low 20 of immediate value
                        -- sign extend (rs << 12) to fit 64 bit
                        auipc_ext(31 downto 12) <= rs1(19 downto 0);
                        auipc_ext(11 downto 0) <= (others => '0');
                        result <= std_logic_vector(signed(rs1) + signed(auipc_ext));
                    when op_XOR =>
                    when op_XORI =>
                        -- Assumption: immediate value in rs2 is already sign-extended                        
                        result <= rs1 xor rs2;
                    when op_OR =>                        
                    when op_ORI =>                        
                        -- Assumption: immediate value in rs2 is already sign-extended                        
                        result <= rs1 or rs2;
                    when op_AND =>                        
                    when op_ANDI =>                        
                        -- Assumption: immediate value in rs2 is already sign-extended                        
                        result <= rs1 and rs2;
                    when op_SLT =>                        
                    when op_SLTI =>
                        if(signed(rs1) < signed(rs2)) then
                            result <= (0 => '1', others => '0');                       
                        else
                            result <= (others => '0');                       
                        end if;
                    when op_SLTU =>
                    when op_SLTIU =>                        
                        -- Assumption: immediate value in rs2 is already sign-extended                        
                        if(unsigned(rs1) < unsigned(rs2)) then
                            result <= (0 => '1', others => '0');                       
                        else
                            result <= (others => '0');                       
                        end if;
                    when op_SLLW =>
                        -- Since these are word operations instead of double
                        -- word operations, only use the bottom 5 bits instead of 6                       
                        shift_arg <= to_integer(unsigned(rs2(4 downto 0)));
                        result(31 downto 0) <= std_logic_vector(shift_left(unsigned(rs1(31 downto 0)), shift_arg));
                        result(63 downto 32) <= (others => result(31));
                    when op_SLLIW =>                        
                        shift_arg <= to_integer(signed(shamt));
                        result(31 downto 0) <= std_logic_vector(shift_left(unsigned(rs1(31 downto 0)), shift_arg));
                    when op_SRLW =>                        
                        shift_arg <= to_integer(unsigned(rs2(4 downto 0)));
                        result <= std_logic_vector(shift_right(unsigned(rs1), shift_arg));
                    when op_SRLIW =>                        
                        shift_arg <= to_integer(signed(shamt));
                        result <= std_logic_vector(shift_right(unsigned(rs1), shift_arg));
                    when op_SRAW =>                        
                        shift_arg <= to_integer(unsigned(rs2(4 downto 0)));
                        result <= std_logic_vector(shift_right(unsigned(rs1), shift_arg));
                    when op_SRAIW =>                        
                        shift_arg <= to_integer(signed(shamt));
                        result <= std_logic_vector(shift_right(unsigned(rs1), shift_arg));
                    when op_ADDW =>                        
                    when op_ADDIW =>                        
                        -- Assumption: immediate value in rs2 is already sign-extended                        
                        result(63 downto 32) <= rs1(63 downto 32);
                        result(31 downto 0) <= std_logic_vector(signed(rs2(31 downto 0)) + signed(rs2(31 downto 0)));
                    when op_SUBW =>                        
                        result(63 downto 32) <= rs1(63 downto 32);
                        result(31 downto 0) <= std_logic_vector(signed(rs2(31 downto 0)) - signed(rs2(31 downto 0)));
                    when op_MUL =>
                        mul_reg <= std_logic_vector(signed(rs1) * signed(rs2));
                        result <= zero_word & mul_reg(31 downto 0);
                    when op_MULH =>
                        mul_reg <= std_logic_vector(signed(rs1) * signed(rs2));
                        result <= mul_reg(63 downto 32) & zero_word;
                    when op_MULHU =>
                        mul_reg <= std_logic_vector(unsigned(rs1) * unsigned(rs2));
                        result <= mul_reg(63 downto 32) & zero_word;
                    when op_MULHSU =>
                        -- TODO - verify that this multiplier does not introduce problems on the schematic/layout
                        mul_reg <= std_logic_vector(signed(rs1) * signed('0' & rs2));
                        result <= mul_reg(63 downto 32) & zero_word;
                        
                    --  
                    --  Special Values for Divide by Zero and Division Overflow (per 2.2 spec)
                    --  Situation                           ||  Special Return Values for Each Instruction
                    --  <condition> <Dividend>  <Divisor>   ||  <DIVU>          <REMU>      <DIV>       <REM>
                    --  Divide by 0 x           0           ||  All bits set    x           -1          x
                    --  Overflow    -(2^64 -1)  -1          ||  N/A             N/A         -(2^(64-1)) 0
                    --
                    
                    when op_DIV =>
                        if(zero_word = rs2(31 downto 0) and zero_word = rs2(63 downto 32)) then
                            -- case divide by zero, set result to -1 (all ones)
                            mul_reg <= all_bits_set;
                        elsif( (all_bits_set = rs1) and (-1 = to_integer(signed(rs2))) ) then
                            -- case division overflow, set only MSB
                            mul_reg <= (63 => '1', others => '0');
                        else
                            mul_reg <= std_logic_vector(signed(rs1) / signed(rs2));
                        end if;
                        result <= mul_reg;
                    when op_DIVU => 
                        if(zero_word = rs2(31 downto 0) and zero_word = rs2(63 downto 32)) then
                            -- case divide by zero, set result to all ones
                            mul_reg <= all_bits_set;
                        else
                            mul_reg <= std_logic_vector(unsigned(rs1) / unsigned(rs2));
                        end if;
                        result <= mul_reg;
                    when op_REM =>
                        if(zero_word = rs2(31 downto 0) and zero_word = rs2(63 downto 32)) then
                            -- case divide by zero, set result to dividend
                            mul_reg <= rs1;
                        elsif( (all_bits_set = rs1) and (-1 = to_integer(signed(rs2))) ) then
                            -- case division overflow, set result to 0
                            mul_reg <= (others => '0');
                        else
                            mul_reg <= std_logic_vector(signed(rs1) mod signed(rs2));
                        end if;
                        result <= mul_reg;
                    when op_REMU =>
                        if(zero_word = rs2(31 downto 0) and zero_word = rs2(63 downto 32)) then
                            -- case divide by zero, set result to dividend
                            mul_reg <= rs1;
                        else
                            mul_reg <= std_logic_vector(unsigned(rs1) mod unsigned(rs2));
                        end if;
                        result <= mul_reg;
                    when op_MULW =>
                        mul_reg <= std_logic_vector(signed(rs1(31 downto 0)) * signed(rs2(31 downto 0)));
                        result(63 downto 32) <= (others => mul_reg(31));
                        result(31 downto 0) <= mul_reg(31 downto 0);
                    when op_DIVW =>
                        if(zero_word = rs2(31 downto 0)) then
                            -- case divide by zero, set result to -1 (all ones)
                            mul_reg <= all_bits_set;
                        elsif( (all_bits_set(31 downto 0) = rs1(31 downto 0)) and (-1 = to_integer(signed(rs2(31 downto 0)))) ) then
                            -- case division overflow, set only MSB
                            mul_reg <= (31 => '1', others => '0');
                        else
                            mul_reg <= std_logic_vector(signed(rs1(31 downto 0)) / signed(rs2(31 downto 0)));
                        end if;
                        result(63 downto 32) <= (others => mul_reg(31));
                        result(31 downto 0) <= mul_reg(31 downto 0);
                    when op_DIVUW => 
                        if(zero_word = rs2(31 downto 0)) then
                            -- case divide by zero, set result to all ones
                            mul_reg <= all_bits_set;
                        else
                            mul_reg <= std_logic_vector(unsigned(rs1(31 downto 0)) / unsigned(rs2(31 downto 0)));
                        end if;
                        result(63 downto 32) <= (others => mul_reg(31));
                        result(31 downto 0) <= mul_reg(31 downto 0);
                    when op_REMW =>
                        if(zero_word = rs2(31 downto 0)) then
                            -- case divide by zero, set result to dividend
                            mul_reg <= rs1;
                        elsif( (all_bits_set(31 downto 0) = rs1(31 downto 0)) and (-1 = to_integer(signed(rs2(31 downto 0)))) ) then
                            -- case division overflow, set result to 0
                            mul_reg <= (others => '0');
                        else
                            mul_reg <= std_logic_vector(signed(rs1(31 downto 0)) mod signed(rs2(31 downto 0)));
                        end if;
                        result(63 downto 32) <= (others => mul_reg(31));
                        result(31 downto 0) <= mul_reg(31 downto 0);
                    when op_REMUW =>
                        if(zero_word = rs2(31 downto 0)) then
                            -- case divide by zero, set result to dividend
                            mul_reg <= rs1;
                        else
                            mul_reg <= std_logic_vector(unsigned(rs1(31 downto 0)) mod unsigned(rs2(31 downto 0)));
                        end if;
                        result(63 downto 32) <= (others => mul_reg(31));
                        result(31 downto 0) <= mul_reg(31 downto 0);
                    when others =>
                        -- Error condition: unknown control code
                        feedback(0) <= '1';
                        result <= (others => '0');
                end case;
            end if; -- Reset
        end if; -- Halt
    end if; -- Clock

end process;

error <= feedback(0); -- TODO feedback single bit for error conditions.
overflow <= feedback(1);-- TODO check here, remove from logic above
zero <= '1' when (0 = unsigned(result)) else '0';
rout <= result;

end Behavioral;
