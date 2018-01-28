----------------------------------------------------------------------------------
-- Engineer: Longofono
-- 
-- Create Date: 01/11/2018 04:18:22 PM
-- Module Name: writeback - Behavioral
-- Description: Writeback shift register
-- 
-- Additional Comments:
--  This is an output buffer for the ALU stage for the control unit.  This is included 
--  to allow a simple two-bit control of writeback data.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library config;
use work.config.all;

entity writeback is
  Port(
    clk:            in std_logic;   -- System clock
    rst:            in std_logic;   -- System reset
    halt:           in std_logic;   -- Do nothing when high
    ready_input:    in std_logic;   -- Control has data to be written back
    ready_output:   in std_logic;   -- MMU is ready to accept data
    output_OK:      out std_logic;  -- Write data and address are valid
    input_OK:       out std_logic;  -- Read data and address recorded
    input_data:     in doubleword;  -- Data from previous stage
    input_address:  in word;        -- MMU Destination for input data
    output_data:    out doubleword; -- Data to be written to MMU
    output_address: out word        -- MMU destination for output data
  );
end writeback;

architecture Behavioral of writeback is

-- Two states represent waiting or not waiting to dump the registers
-- Moore machine with inputs read, write, and halt, synchronous reset
type state is (state_idle, state_writing);

signal curr_state:  state;
signal next_state:  state;
signal last_data:   doubleword;
signal last_addr:   word;
signal s_output_ack: std_logic;
signal s_input_ack: std_logic;

begin

-- Advance State
process(clk, rst)
begin
    if(rising_edge(clk)) then
        if('1' = rst) then
            curr_state <= state_idle;
        else
            curr_state <= next_state;
        end if;
    end if;
end process;

-- Compute outputs
-- Needs to be sensitive to clock in case MMU stalls, we
-- want to check for updates at each rising edge
process(clk, rst, curr_state)
begin
    if(rising_edge(clk)) then
        input_OK <= '0';
        output_OK <= '0';
        output_data <= last_data;
        output_address <= last_addr;
        next_state <= curr_state;

        if('1' = rst) then    
            last_data <= (others => '0');
            last_addr <= (others => '0');
            output_data <= (others => '0');
            output_address <= (others => '0');
            next_state <= state_idle;
        elsif('0' = halt) then -- Do nothing unless halt is low
            case curr_state is
                when state_writing =>   -- Case pending write
                    output_OK <= '1';  -- signal MMU data is valid

                    if('1' = ready_output) then    -- Case MMU ready for data
                        next_state <= state_idle;   -- Transition to idle state to get more input
                    end if;
                    
                when state_idle =>  -- Case no pending write

                    if('1' = ready_input) then -- Case control has new data
                        last_addr <= input_address; -- Update latches
                        last_data <= input_data;
                        input_OK <= '1'; -- signal control that data is accepted
                        next_state <= state_writing;  -- Transition to write pending state
                    end if;
            end case;
        end if; -- rst/halt
    end if; --  rising edge
end process;

end Behavioral;
