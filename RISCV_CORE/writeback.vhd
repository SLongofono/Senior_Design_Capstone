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
    read:           in std_logic;   -- MMU requests read
    write:          in std_logic;   -- Control requests write
    write_ack:      out std_logic;  -- Write data and address are valid
    read_ack:       out std_logic;  -- Read data and address recorded
    read_data:      in doubleword;  -- Data from previous stage
    read_address:   in word;        -- MMU Destination for read data
    write_data:     out doubleword; -- Data to be written to MMU
    write_address:  out word        -- MMU destination for write data
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
signal s_write_ack: std_logic;
signal s_read_ack: std_logic;

begin

-- Advance State
process(clk, rst)
begin
    if(rising_edge(clk)) then
        if('1' = rst) then
            curr_state <= state_idle;
            next_state <= state_idle;
            last_data <= (others => '0');
            last_addr <= (others => '0');
            s_write_ack <= '0';
            s_read_ack <= '0';
        else
            curr_state <= next_state;
        end if;
    end if;
end process;

-- Compute outputs
process(curr_state)
begin
    next_state <= curr_state;
    s_write_ack <= '0';
    s_read_ack <= '0';
    
    if('0' = halt) then -- Do nothing unless halt is low
        case curr_state is
            when state_writing =>   -- Case pending write
                if('1' = write) then    -- Case MMU ready for input, signal that write data and addr are ready
                    s_write_ack <= '1';
                    next_state <= state_idle;
                end if;
                
            when others =>  -- Case no pending write
                if('1' = read) then -- Case control has new read data, read and change to write pending state
                    last_addr <= read_address;
                    last_data <= read_data;
                    s_read_ack <= '1';
                    next_state <= state_writing;
                end if;
        end case;
    end if;
end process;

write_ack <= s_write_ack;
read_ack <= s_read_ack;
write_data <= last_data;
write_address <= last_addr;

end Behavioral;
