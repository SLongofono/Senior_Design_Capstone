---------------------------------------------------------------------------------- 
-- Engineer: Longofono
-- 
-- Create Date: 02/04/2018 02:45:16 PM
-- Module Name: load_store - Behavioral
-- Description: Handles loading, storing, and signalling between core, control, and MMU 
-- 
-- Additional Comments:
-- If storing, addr will be the MMU destination address and data will be the data to be written there
-- If loading, addr will be the MMU source address and data will be an encoding of the number of bytes to load
-- Encoding is as follows:
-- One byte (LB, LBU)   -> 0x0
-- Two bytes (LH, LHU)  -> 0x1
-- Four bytes (LW, LWU) -> 0x2
-- Eight bytes (LD)     -> 0x3
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library config;
use work.config.all;

-- If loading, we need to know:
-- Memory address to load from (register file holds base, instruction holds offset
-- Register address to load to

-- If storing, we need to know:
-- Register address to store from
-- Memory address to store to (register file holds base, instruction holds offset

entity load_store is
    Port(
        instr: in instr_t;                       -- Current instruction type
        imm12: in std_logic_vector(11 downto 0); -- offset value
        rs1: in reg_t;                           -- rs1 for S-type and I-type
        rs2: in reg_t;                           -- rs2 for S-type
        addr: out doubleword;                    -- Destination address
        data: out doubleword                     -- Data to be stored
    );
end load_store;

architecture Behavioral of load_store is

-- Latch for modifying data and address piecewise
signal s_data: doubleword;
signal s_addr: doubleword;

begin

process(instr)
begin
-- Encoding for load data is as follows:
-- One byte (LB, LBU)   -> 0x0
-- Two bytes (LH, LHU)  -> 0x1
-- Four bytes (LW, LWU) -> 0x2
-- Eight bytes (LD)     -> 0x3
    case instr is
        when instr_LB =>
            -- Load byte
            s_addr <= std_logic_vector(signed(rs1) + signed(imm12));
            s_data <= (others => '0');
        when instr_LBU =>
            -- Load byte, unsigned
            s_addr <= std_logic_vector(signed(rs1) + signed(imm12));
            s_data <= (others => '0');
        when instr_LD =>
            -- Load doubleword
            s_addr <= std_logic_vector(signed(rs1) + signed(imm12));
            s_data <= (1 downto 0 => '1', others => '0');
        when instr_LH =>
            -- Load half word
            s_addr <= std_logic_vector(signed(rs1) + signed(imm12));
            s_data <= (0 => '1', others => '0');
        when instr_LHU =>
            -- Load half word, unsigned
            s_addr <= std_logic_vector(signed(rs1) + signed(imm12));
            s_data <= (0 => '1', others => '0');
        when instr_LW =>
            -- Load word
            s_addr <= std_logic_vector(signed(rs1) + signed(imm12));
            s_data <= (1 => '1', others => '0');
        when instr_LWU =>
            -- Load word, unsigned
            s_addr <= std_logic_vector(signed(rs1) + signed(imm12));
            s_data <= (1 => '1', others => '0');
        when instr_SB =>
            -- Store byte
            s_addr <= std_logic_vector(signed(rs1) + signed(imm12));
            s_data(63 downto 8) <= (others => '0');
            s_data(7 downto 0) <= rs2(7 downto 0);
        when instr_SD =>
            -- Store doubleword
            s_addr <= std_logic_vector(signed(rs1) + signed(imm12));
            s_data <= rs2;
        when instr_SH =>
            -- Store half word
            s_addr <= std_logic_vector(signed(rs1) + signed(imm12));
            s_data(63 downto 16) <= (others => '0');
            s_data(15 downto 0) <= rs2(15 downto 0);
        when instr_SW =>
            -- Store word
            s_addr <= std_logic_vector(signed(rs1) + signed(imm12));
            s_data(63 downto 32) <= (others => '0');
            s_data(31 downto 0) <= rs2(31 downto 0);
        when others =>
            s_addr <= (others => '0');
            s_data <= (others => '0');
    end case;

data <= s_data;
addr <= s_addr;

end process;

end Behavioral;
