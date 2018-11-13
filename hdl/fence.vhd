----------------------------------------------------------------------------------
-- Engineer: Longofono
-- 
-- Create Date: 01/11/2018 04:18:22 PM
-- Module Name: fence - Behavioral
-- Description: Shift register
-- 
-- Additional Comments:
--  This is a buffer to preserved the next instruction when the MMU is busy handling
--  a load or store instruction
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library config;
use work.config.all;

entity fence is
  Port(
    clk:            in std_logic;   -- System clock
    rst:            in std_logic;   -- System reset
    halt:           in std_logic;   -- Do nothing when high
    ready_input:    in std_logic;   -- Previous stage has data to be written back
    ready_output:   in std_logic;   -- Next stage is ready to accept data
    output_OK:      out std_logic;  -- Write data and address are valid
    input_OK:       out std_logic;  -- Read data and address recorded
    input_data:     in doubleword;  -- Data from previous stage
    input_address:  in doubleword;  -- Destination for input data
    output_data:    out doubleword; -- Data to be written to next stage
    output_address: out doubleword  -- Destination for output data
  );
end fence;

architecture Behavioral of fence is

-- Two states represent waiting or not waiting to dump the registers
-- Moore machine with inputs read, write, and halt, synchronous reset
type state is (state_idle, state_writing);

signal curr_state:  state;
signal next_state:  state;
signal last_data:   doubleword;
signal last_addr:   doubleword;
signal s_output_ack: std_logic;
signal s_input_ack: std_logic;

begin

-- Advance State
process(clk, rst)
begin
    if('1' = rst) then
        curr_state <= state_idle;
    elsif(rising_edge(clk)) then
        curr_state <= next_state;
    end if;
end process;

-- Compute outputs
-- Needs to be sensitive to new input in case MMU stalls
process(input_data, ready_input, rst, clk, curr_state)
begin
    input_OK <= '0';
    output_OK <= '0';
    next_state <= curr_state;
    
    if('1' = rst) then
        last_data <= (others => '0');
        last_addr <= (others => '0');
    elsif('0' = halt) then -- Do nothing unless halt is low
        case curr_state is
            when state_writing =>   -- Case pending write
                output_OK <= '1';  -- signal outbound data is valid

                if('1' = ready_output) then    -- Case outbound ready for data
                    next_state <= state_idle;   -- Transition to idle state to get more input
                end if;
                
            when state_idle =>  -- Case no pending write
                input_OK <= '1'; -- signal input that data is accepted
                if('1' = ready_input) then -- Case input has new data
                    last_addr <= input_address; -- Update latches
                    last_data <= input_data;
                    next_state <= state_writing;  -- Transition to write pending state
                end if;
        end case;
    end if; -- rst/halt
end process;

output_address <= last_addr;
output_data <= last_data;

end Behavioral;
