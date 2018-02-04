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
        writeback_ack:  in std_logic;                   -- WB ready for input
        writeback_request:  out std_logic;              -- Signal WB results waiting
        MMU_load_complete:  in std_logic;               -- MMU load data is ready to be written back               
        ALU_halts: out std_logic_vector(4 downto 0);    -- Signal ALU pipeline modules to halt
        PC_select: out std_logic_vector(4 downto 0)     -- Select for PCnext mux
    );
end control;

architecture Behavioral of control is

-- High-level states of operation (distinct from privilege modes)
type state is (setup, teardown, normal, waiting, exception);
signal curr_state, next_state: state;

-- Control status registers followed by scratch
type CSR_t is array (0 to 64) of doubleword;
signal CSR: CSR_t;

-- If in waiting state, reason determines actions on exit
signal waiting_reason: std_logic_vector(2 downto 0);

begin

-- Advance state
update_state: process(clk,rst)
begin
    if(rising_edge(clk)) then
        if('1' = rst) then
            curr_state <= setup;
        else
            curr_state <= next_state;
        end if;
    end if;

end process;

-- Compute outputs
update_signals: process(curr_state)
begin
    -- default outputs
    next_state <= curr_state;
    
    -- adjust next state and outputs
    case curr_state is
        when setup => -- Bootloader code
            -- Reset CSR
            CSR <= (others => (zero_word & zero_word));
        when teardown => -- Maybe superflous
        when waiting =>
            case waiting_reason is
                when "000" => -- Waiting on MMU instruction
                    if('1' = instruction_ready) then
                        -- Resume normal mode
                        next_state <= normal;
                    end if;
                when "001" => -- Waiting on MMU to clear WB (store instructions)
                    if('1' = writeback_ack) then
                        next_state <= normal;
                    end if;
                when "010" => -- Waiting on mulhsu (one cycle)
                    -- always go back to normal, stalled one cycle
                    next_state <= normal;
                when "011" => -- Waiting on MMU load data
                    if('1' = MMU_load_complete) then
                        next_state <= normal;
                    end if;
                when others => -- Waiting for interrupt (special state when no work exists)
            end case;
        when exception => -- Interrupt to take
            -- Determine which of supervisor/machine interrupt vector to use
            -- Switch in exception address and perform jump
            -- return to normal mode to execute handler instructions
            next_state <= normal;
        when others => -- Normal operation
            next_state <= normal;
    end case;
end process;

end Behavioral;
