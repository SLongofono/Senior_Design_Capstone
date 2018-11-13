----------------------------------------------------------------------------
-- UART_RX_CTRL.vhd -- Simple UART RX controller
-- Written by Hamster
-- Modified by Warren Toomey
--
-- This component may be used to transfer data over a UART device. It will
-- receive a byte of serial data and transmit it over an 8-bit bus. The 
-- serialized data has to have the following characteristics:
--   *9600 Baud Rate
--   *8 data bits, LSB first
--   *1 stop bit
--   *no parity
--                                      
-- Port Descriptions:
--    UART_RX - This is the serial signal line from the UART.
--        CLK - A 100 MHz clock is expected.
--       DATA - The parallel data to be read.
--  READ_DATA - Signal flag indicating when data is ready to be read.
-- RESET_READ - Data has been read, which turns off READ_DATA
----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity UART_RX_CTRL is
    port ( UART_RX: in   STD_LOGIC;
        CLK:        in   STD_LOGIC;
        DATA:       out  STD_LOGIC_VECTOR (7 downto 0);
        READ_DATA:  out  STD_LOGIC := '0';
        RESET_READ: in   STD_LOGIC
    );
end UART_RX_CTRL;

architecture behavioral of UART_RX_CTRL is
    
    constant FREQ : integer := 100000000;  -- 100MHz Nexys4 CLK
    constant BAUD : integer := 9600;       -- Bit rate of serial comms
    
    -- A counter of clock cycles. We sample the incoming
    -- serial signal at 1.5x the serial bit duration to
    -- skip the start bit and get halfway into the first
    -- data bit. After that, we skip whole bit durations
    -- to sample midway through the other data bits
    signal   count   : integer := 0;
    constant sample_0: integer := 3 * FREQ/(BAUD*2)-1;
    constant sample_1: integer := 5 * FREQ/(BAUD*2)-1;
    constant sample_2: integer := 7 * FREQ/(BAUD*2)-1;
    constant sample_3: integer := 9 * FREQ/(BAUD*2)-1;
    constant sample_4: integer := 11 * FREQ/(BAUD*2)-1;
    constant sample_5: integer := 13 * FREQ/(BAUD*2)-1;
    constant sample_6: integer := 15 * FREQ/(BAUD*2)-1;
    constant sample_7: integer := 17 * FREQ/(BAUD*2)-1;
    constant stop_bit: integer := 19 * FREQ/(BAUD*2)-1;
    
    -- The bits from the serial input accumulate here
    signal byte: std_logic_vector(7 downto 0) := (others => '0');
    
begin
    rx_state_process : process (CLK)
    begin
        if (rising_edge(CLK)) then
            
            -- The data has been read, so lower the flag
            -- that indicates new data has arrived
            if (RESET_READ = '1') then
                READ_DATA <= '0';
            end if;
            
	    -- Sample the serial line several times to find
	    -- the eight data bits and the stop bit
            case count is 
                when sample_0 => byte <= UART_RX & byte(7 downto 1);
                when sample_1 => byte <= UART_RX & byte(7 downto 1);
                when sample_2 => byte <= UART_RX & byte(7 downto 1);
                when sample_3 => byte <= UART_RX & byte(7 downto 1);
                when sample_4 => byte <= UART_RX & byte(7 downto 1);
                when sample_5 => byte <= UART_RX & byte(7 downto 1);
                when sample_6 => byte <= UART_RX & byte(7 downto 1);
                when sample_7 => byte <= UART_RX & byte(7 downto 1);
                when stop_bit =>  
                    -- Send out the data when we see a valid stop bit
                    if UART_RX = '1' then 
                        DATA <= byte;
                        READ_DATA <= '1';
                    end if;
                when others =>
                    null;
            end case;
            
            -- Reset the counter when we reach the stop bit
            if count = stop_bit then
                count <= 0;
            elsif count = 0 then
                if UART_RX = '0' then -- Start bit just seen, so start counting
                    count <= count + 1;   
                end if;
            else
                count <= count + 1;   
            end if;
        end if;
    end process;
end behavioral;

