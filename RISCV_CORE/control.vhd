----------------------------------------------------------------------------------
-- Engineer: Longofono
-- 
-- Create Date: 02/04/2018 01:13:09 PM
-- Module Name: control - Behavioral
-- Description: Control unit for RISCV core
-- 
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library config;
use work.config.all;

entity control is
    Port(
        clk:    in std_logic;                           -- System clock
        rst:    in std_logic;                           -- System reset
        instruction_ready:  in std_logic;               -- IM ready
        writeback_ack:  in std_logic;                   -- WB ready
        writeback_request:  out std_logic;              -- Signal WB results waiting               
        ALU_halts: out std_logic_vector(4 downto 0);    -- Signal ALU pipeline modules to halt
        PC_select: out std_logic_vector(4 downto 0)     -- Select for PCnext mux
    );
end control;

architecture Behavioral of control is

type state is (setup, teardown, normal, waiting, exception);
type t_CSR is array (31 downto 0) of doubleword;
signal currState, nextState: state;
signal CSR: t_CSR;

begin

-- Advance state
update_state: process(clk,rst)
begin
    if(rising_edge(clk)) then
        if('1' = rst) then
            currState <= setup;
        else
            currState <= nextState;
        end if;
    end if;

end process;

-- Compute outputs
update_signals: process(currState)
begin
    -- default outputs
    nextState <= currState;
    
    -- adjust next state and outputs
    case currState is
        when setup => -- Bootloader code
            -- Reset CSR
            CSR <= (others => (zero_word & zero_word));
        when teardown => -- Maybe superflous
        when waiting => -- Stalled on MMU or mulhsu
        when exception => -- Interrupt to take
        when others => -- Normal operation
    end case;
end process;

end Behavioral;
