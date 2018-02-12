----------------------------------------------------------------------------------
-- Engineer: Longofono
-- Create Date: 02/10/2018 07:53:02 PM
-- Module Name: MMU_stub - Behavioral
-- Description: Simple stub of MMU to feed instructions and store data 
-- 
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library config;
use work.config.all;

use IEEE.NUMERIC_STD.ALL;

entity MMU_stub is
    Port(
        clk: in std_logic;
        rst: in std_logic;
        addr_in: in doubleword;
        data_in: in doubleword;
        store: in std_logic;
        load: in std_logic;
        busy: out std_logic;
        ready_instr: in std_logic;
        addr_instr: in doubleword;
        alignment: in std_logic_vector(3 downto 0);
        data_out: out doubleword;
        instr_out: out doubleword;
        error: out std_logic_vector(5 downto 0)
    );
end MMU_stub;

architecture Behavioral of MMU_stub is

type instsmem is array(0 to 31) of doubleword;
type mem is array(0 to 31) of doubleword;

signal memory: mem := (others => "0000000000000000000000000000000000000000000000000000000000000000");
signal instructions: instsmem := (
    zero_word & "00000000111100000000001010010011",
    zero_word & "00000001000000000000001100010011",
    zero_word & "00000000010100110000001100110011",
    zero_word & "00000000000000110111001010110011",
    zero_word & "00000000010100110110001100110011",
    zero_word & "00000000111100000000001010010011",
    zero_word & "00000001000000000000001100010011",
    zero_word & "00000000010100110000001100110011",
    zero_word & "00000000000000110111001010110011",
    zero_word & "00000000010100110110001100110011",
    zero_word & "00000000111100000000001010010011",
    zero_word & "00000001000000000000001100010011",
    zero_word & "00000000010100110000001100110011",
    zero_word & "00000000000000110111001010110011",
    zero_word & "00000000010100110110001100110011",
    zero_word & "00000000111100000000001010010011",
    zero_word & "00000001000000000000001100010011",
    zero_word & "00000000010100110000001100110011",
    zero_word & "00000000000000110111001010110011",
    zero_word & "00000000010100110110001100110011",
    zero_word & "00000000111100000000001010010011",
    zero_word & "00000001000000000000001100010011",
    zero_word & "00000000010100110000001100110011",
    zero_word & "00000000000000110111001010110011",
    zero_word & "00000000010100110110001100110011",
    zero_word & "00000000111100000000001010010011",
    zero_word & "00000001000000000000001100010011",
    zero_word & "00000000010100110000001100110011",
    zero_word & "00000000000000110111001010110011",
    zero_word & "00000000010100110110001100110011",
    zero_word & "00000000111100000000001010010011",
    zero_word & "00000001000000000000001100010011"
);
signal PC: integer;
signal index: integer;
signal lastData: doubleword;
constant ones_word: word := (others => '1');

-- Errors: <invalid PC> <misaligned> <protected region> <other> <other2> <other3>
signal error_out: std_logic_vector(5 downto 0);

type state is (idle, loading, storing, fetching);
signal curr_state: state;
signal next_state: state;

begin

-- Advance state
process(clk, rst)
begin
    if('1' = rst) then
        memory <= (others => "0000000000000000000000000000000000000000000000000000000000000000");
        lastData <= (others => '0');
        curr_state <= idle;
    elsif(rising_edge(clk)) then
        curr_state <= next_state;
    end if;
end process;


process(curr_state, clk)
begin
    error_out <= "000000";
    busy <= '1';    
    next_state <= curr_state;
    PC <= to_integer(unsigned(addr_instr));

    case curr_state is
        when idle => -- Idle, initiate work
            -- Allow core to proceed
            busy <= '0';

            if('1' = load) then             -- Handle loads and stores before fetching
                next_state <= loading;
            elsif('1' = store) then
                next_state <= storing;
            elsif('1' = ready_instr) then
                next_state <= fetching;
            end if;
        when fetching => -- Handle instruction fetch

            -- Validate PC fetch
            if( PC/8 <= 31) then
                if( PC mod 8 = 0 ) then
                    index <= PC;
                else
                    error_out(4) <= '1'; -- Misaligned error
                end if;
            else
                error_out(5) <= '1'; -- Memory OOB error
            end if;
            
            if('1' = load) then
                next_state <= loading;
            elsif('1' = store) then
                next_state <= storing;
            else
                next_state <= idle;
            end if;

        when loading => -- Handle load
            -- Validate data fetch
            if(to_integer(unsigned(addr_in)) <= 31) then
                -- Validate alignment
                case alignment is
                    when "1000" => -- Read doubleword
                        if( to_integer(unsigned(addr_in)) mod 8 = 0) then
                            lastData <= memory(to_integer(unsigned(addr_in)));
                        else
                            error_out(4) <= '1';
                        end if;                
                    when "0100" => -- Read half-word
                        if( to_integer(unsigned(addr_in)) mod 4 = 0) then
                            lastData <= (zero_word & ones_word) and memory(to_integer(unsigned(addr_in)));
                        else
                                error_out(4) <= '1';
                        end if;
                    when "0010" => -- Read two bytes
                        if( to_integer(unsigned(addr_in)) mod 2 = 0) then
                            lastData <= (zero_word & zero_word(15 downto 0) & ones_word(15 downto 0)) and memory(to_integer(unsigned(addr_in)));
                        else
                                error_out(4) <= '1';
                        end if;
                    when "0001" => -- Read single byte
                        if( to_integer(unsigned(addr_in)) mod 4 = 0) then
                            lastData <= (zero_word & zero_word(23 downto 0) & ones_word(7 downto 0)) and memory(to_integer(unsigned(addr_in)));
                        else
                                error_out(4) <= '1';
                        end if;
                    when others =>
                        error_out(4) <= '1';
                end case;
            else
                error_out(2) <= '1';
            end if; -- if valid data fetch ...           

            next_state <= idle;

        when others => -- Handle store            
                -- Validate data store
                if(to_integer(unsigned(addr_in)) <= 31) then
                    -- Validate alignment
                    case alignment is
                        when "1000" => -- Write doubleword
                            if( to_integer(unsigned(addr_in)) mod 8 = 0) then
                                memory(to_integer(unsigned(addr_in))) <= data_in;
                            else
                                error_out(4) <= '1';
                            end if;                
                        when "0100" => -- Write half-word
                            if( to_integer(unsigned(addr_in)) mod 4 = 0) then
                                memory(to_integer(unsigned(addr_in))) <= ((ones_word & zero_word) and memory(to_integer(unsigned(addr_in)))) or
                                                                         ((zero_word & ones_word) and data_in);
                            else
                                    error_out(4) <= '1';
                            end if;
                        when "0010" => -- Write two bytes
                            if( to_integer(unsigned(addr_in)) mod 2 = 0) then
                                memory(to_integer(unsigned(addr_in))) <= ((ones_word & ones_word(15 downto 0) & zero_word(15 downto 0)) and memory(to_integer(unsigned(addr_in)))) or
                                                                         ((zero_word & zero_word(15 downto 0) & ones_word(15 downto 0)) and data_in);
                            else
                                    error_out(4) <= '1';
                            end if;
                        when "0001" => -- Write single byte
                            if( to_integer(unsigned(addr_in)) mod 4 = 0) then
                                memory(to_integer(unsigned(addr_in))) <= ((ones_word & ones_word(23 downto 0) & zero_word(7 downto 0)) and memory(to_integer(unsigned(addr_in)))) or
                                                                         ((zero_word & zero_word(23 downto 0) & ones_word(7 downto 0)) and data_in);
                            else
                                    error_out(4) <= '1';
                            end if;
                        when others =>
                            error_out(4) <= '1';
                    end case; -- alignment
                else
                    error_out(2) <= '1';
                end if; -- if valid data store ...
                
                next_state <= idle;

        end case;
    
end process;

instr_out <= instructions(index/8) when index > 0 else instructions(0);
data_out <= lastData;
error <= error_out;

end Behavioral;
