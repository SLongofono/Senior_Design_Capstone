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

signal result: doubleword;
signal feedback: std_logic_vector(2 downto 0);
signal shift_arg: natural;
signal preserved: natural;

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
                        shift_arg <= to_integer(unsigned(rs2));
                        result <= std_logic_vector(shift_left(unsigned(rs1), shift_arg));
                    when op_SLLI =>
                        shift_arg <= to_integer(unsigned(shamt));
                        result <= std_logic_vector(shift_left(unsigned(rs1), shift_arg));
                    when op_SRL =>
                        shift_arg <= to_integer(unsigned(rs2));
                        result <= std_logic_vector(shift_right(unsigned(rs1), shift_arg));
                    when op_SRLI =>                        
                        shift_arg <= to_integer(unsigned(shamt));
                        result <= std_logic_vector(shift_right(unsigned(rs1), shift_arg));
                    when op_SRA =>                        
                        shift_arg <= to_integer(unsigned(rs2));
                        -- Case 1: shift_arg > length rs2
                        if(shift_arg > 64) then
                            result <= (others => rs1(63));
                        else
                        -- Case 2: shift_arg <= length rs2
                            preserved <= 63 - shift_arg;
                            result <= (
                                preserved downto 0 => rs1(63 downto preserved),
                                others => '0'
                            );
                        end if;
                    when op_SRAI =>                        
                        shift_arg <= to_integer(unsigned(rs2));
                        
                    when op_ADD =>
                    when op_ADDI =>                        
                        result <= rs1 + rs2;
                        if((result < rs1) or (result < rs2)) then
                            -- case overflow
                            feedback(1) <= '1';
                        end if;
                    when op_SUB =>                        
                        result <= rs1 + rs2;
                        if((result < rs1) or (result < rs2)) then
                            -- case overflow
                            feedback(1) <= '1';
                        end if;
                    when op_LUI =>
                            result <= rs1(63 downto 32) & "00000000000000000000000000000000";
                            -- TODO check if this is here in error fix me
                    when op_AUIPC =>
                            -- TODO verify that PC can easily be passed in here as arg 1
                            result <= rs1 + rs2
                    when op_XOR =>
                    when op_XORI =>                        
                            result <= rs1 xor rs2;
                    when op_OR =>                        
                    when op_ORI =>                        
                            result <= rs1 or rs2;
                    when op_AND =>                        
                    when op_ANDI =>                        
                            result <= rs1 and rs2;
                    when op_SLT =>                        
                    when op_SLTI =>                        
                    when op_SLTU =>                        
                    when op_SLTIU =>                        
                    when op_SLLW =>                        
                    when op_SLLIW =>                        
                    when op_SRLW =>                        
                    when op_SRLIW =>                        
                    when op_SRAW =>                        
                    when op_SRAIW =>                        
                    when op_ADDW =>                        
                    when op_ADDIW =>                        
                            result(63 downto 32) <= rs1(63 downto 32);
                            result(31 downto 0) <= rs2(31 downto 0) + rs2(31 downto 0);
                    when op_SUBW =>                        
                            result(63 downto 32) <= rs1(63 downto 32);
                            result(31 downto 0) <= rs2(31 downto 0) - rs2(31 downto 0);
                    when others =>
                        feedback(0) <= '1';
                        result <= (others => '0');
                end case;
            end if;
        end if;
    end if;

end process;

error <= feedback(0);
overflow <= feedback(1);
zero <= feedback(2);
rout <= result;

end Behavioral;
