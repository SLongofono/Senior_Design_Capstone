----------------------------------------------------------------------------------
-- Engineer: Longofono
-- 
-- Create Date: 11/27/2017 08:36:56 AM
-- Module Name: regfile - Behavioral
-- Description: 

-- Additional Comments:

----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library config;
use work.config.all;

entity regfile is
    Port(
        clk:            in std_logic;
        rst:            in std_logic;
        read_addr_1:    in std_logic_vector(4 downto 0);    -- Register source read_data_1
        read_addr_2:    in std_logic_vector(4 downto 0);    -- Register source read_data_2
        write_addr:     in std_logic_vector(4 downto 0);    -- Write dest write_data
        write_data:     in doubleword;                      -- Data to be written
        halt:           in std_logic;                       -- Control, do nothing on high
        write_en:       in std_logic;                       -- write_data is valid
        read_data_1:    out doubleword;                     -- Data from read_addr_1
        read_data_2:    out doubleword;                     -- Data from read_addr_2
        write_error:    out std_logic;                      -- Writing to constant, HW exception
        debug_out:      out regfile_arr                     -- Copy of regfile contents for debugger
    );
end regfile;

architecture Behavioral of regfile is

-- Contents of regfile, all zeros
signal reggie: regfile_arr := (others => (others => '0'));

begin

-- Synchronous write
process(clk, rst)
begin
    if('1' = halt) then
        -- Do nothing
    else
        write_error <= '0';
        if('1' = rst) then
            reggie <= (others => (others => '0'));
        elsif(rising_edge(clk)) then
            if('1' = write_en) then
                if("00000" = write_addr) then
                    write_error <= '1';
                else
                    reggie(to_integer(unsigned(write_addr))) <= write_data;
                end if; -- write_error
            end if; -- write_en
        end if; -- rst
    end if; -- halt
end process;

-- Asynchronous read
read_data_1 <= reggie(to_integer(unsigned(read_addr_1)));
read_data_2 <= reggie(to_integer(unsigned(read_addr_2)));

-- Asynchronous debug out
debug_out <= reggie;

end Behavioral;