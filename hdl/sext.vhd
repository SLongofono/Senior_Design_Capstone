----------------------------------------------------------------------------------
-- Engineer: Longofono
-- Create Date: 02/11/2018 03:24:43 PM
-- Module Name: sext - Behavioral
-- Description: Sign extender for immediate values
-- 
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library config;
use work.config.all;

entity sext is
    Port(
        imm12: in std_logic_vector(11 downto 0);
        imm20: in std_logic_vector(19 downto 0);
        output_imm12: out std_logic_vector(63 downto 0);
        output_imm20: out std_logic_vector(63 downto 0)
    );
end sext;

architecture Behavioral of sext is

begin

output_imm12(63 downto 12) <= (others => imm12(11));
output_imm12(11 downto 0) <= imm12;
output_imm20(63 downto 20) <= (others => imm20(19));
output_imm20(19 downto 0) <= imm20;

end Behavioral;
