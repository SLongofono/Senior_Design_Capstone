----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Longofono
-- 
-- Create Date: 02/04/2018 01:34:35 PM
-- Module Name: PCNext_Mux - Behavioral
-- Description: MUX to switch in value for PC Next
-- 
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library config;
use work.config.all;

entity PCNext_Mux is
    Port(
        sel: in std_logic_vector(3 downto 0);
        ALU_result: in word;
        bootloader: in word;
        branch_target: in word;
        curr_PC: in word;
        PC_plus_four: in word;
        PC_next: out word
    );
end PCNext_Mux;

architecture Behavioral of PCNext_Mux is

begin

    PC_next <=  ALU_result when sel = "000" else
                bootloader when sel = "001" else
                branch_target when sel = "010" else
                curr_PC when sel = "011" else
                PC_plus_four;

end Behavioral;
