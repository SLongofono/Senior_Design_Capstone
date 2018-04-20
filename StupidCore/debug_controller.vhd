----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/31/2017 03:31:33 PM
-- Design Name: 
-- Module Name: Debug_Controller - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library config;
use work.config.all;

entity Debug_Controller is
    port (clk,RST: in STD_LOGIC;
          HALT: out STD_LOGIC;
          REGGIE: in regfile_arr;
          PC_IN: in doubleword;
          UART_RXD: in STD_LOGIC;
          UART_TXD 	: out  STD_LOGIC);
end Debug_Controller;

architecture Behavioral of Debug_Controller is
   
    component UART_RX_CTRL is
    port  (UART_RX:    in  STD_LOGIC;
           CLK:        in  STD_LOGIC;
           DATA:       out STD_LOGIC_VECTOR (7 downto 0);
           READ_DATA:  out STD_LOGIC;
           RESET_READ: in  STD_LOGIC
    );
    end component;
   
   component UART_TX_CTRL is
    port( SEND : in  STD_LOGIC;
              DATA : in  STD_LOGIC_VECTOR (7 downto 0);
              CLK : in  STD_LOGIC;
              READY : out  STD_LOGIC;
              UART_TX : out  STD_LOGIC);
   end component;
    -- Types
    type CHAR_ARRAY is array (integer range<>) of std_logic_vector(7 downto 0);
    type UART_STATE_TYPE is (IDLE, RECEIVE, UNPAUSE, DECODE, REGISTERS, PC, STEP, STEP_HI, STEP_LO, SEND_CHAR, REGFILE, SEND_CHAR_2, SEND_CHAR_3, SEND_CHAR_4, WAIT_CHAR, KEEP_WAITING_CHAR, LD_REGISTERS_STR, RESET_LO, RESET_HI);
    type BOUNDS is array (integer range<>) of integer;
    
    -- Constants
    constant MAX_STR_LEN : integer := 750;
    constant MAX_REGISTER_LEN : integer := 23;
    constant RESET_CNTR_MAX : std_logic_vector(17 downto 0) := "110000110101000000";-- 100,000,000 * 0.002 = 200,000 = clk cycles per 2 ms
    
    -- Signals
    signal uart_curr_state, uart_next_state : UART_STATE_TYPE := idle;
    signal uartRdy, uartSend ,uartTX: std_logic;
    signal uartData: std_logic_vector(7 downto 0);
    signal sendStr : CHAR_ARRAY(0 to (MAX_STR_LEN - 1)) := ( others => (others => '0'));
    signal reset_cntr : std_logic_vector (17 downto 0) := (others=>'0');

    -- String counters
    signal reggie_counter : integer := 0;
    signal reggie_str_counter : integer := 12;
    signal reggie_counter_counter : integer := 0;
    signal strEnd, strIndex: natural := 0;
    signal strConcatCtr: integer := 0;

    signal pc_str_counter: integer := 0;
    signal pc_reg: doubleword := (others => '0');

    -- CPU halt interface
    signal halt_l : std_logic := '1';

    -- UART RX and TX signals
    signal uart_data_in: STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal data_available, reset_read: STD_LOGIC;
    
    signal rx_str : CHAR_ARRAY(30 DOWNTO 0);
    signal rx_str_ctr : integer := 0;
    
    signal d_clk: std_logic := '0';


    begin
    DEBUG_UART_TX: UART_TX_CTRL port map(SEND => uartSend,
		                       DATA => uartData,
		                       CLK => CLK,
		                       READY => uartRdy,
		                       UART_TX => UART_TXD );

    DEBUG_UART_RX: UART_RX_CTRL
        port map(
          UART_RX => UART_RXD,
          CLK => CLK,
          DATA => uart_data_in,
          READ_DATA => data_available,
          RESET_READ => reset_read
        );
           
    --State Machine transition
    DEBUG_FSM: process(clk, rst) begin
        if(rst = '1') then
            uart_curr_state <= IDLE;
        elsif(rising_edge(clk)) then
            uart_curr_state <= uart_next_state;
        end if;
    end process;
   
    HALT <= halt_l;

    -- Generate the debug clock d_clk
    D_CLK_GEN: process(clk) begin
        if(rising_edge(clk)) then
            if(halt_l = '0') then
                d_clk <= d_clk xor '1';
            end if;
        end if;
    end process;

    DEBUG_FSM_TRANSITION: process(clk, rst) begin
        if(rst = '1') then
            strConcatCtr <= 0;
            reggie_str_counter <= 0;
            reset_read <= '1';
            uart_next_state <= IDLE;
            strIndex <= 0;
            halt_l <= '1';
        elsif(rising_edge(clk)) then
            case uart_curr_state is
            
                -- State IDLE: Nothing happening
                when IDLE =>
                    reggie_counter_counter <= 0;
                    reggie_str_counter <= 0;
                    strConcatCtr <= 0;
                    strEnd <= 735;
                    uartSend <= '0';
                    strIndex <= 0;
                    reset_read <= '0';
                    reggie_counter <= 0;
                    pc_str_counter <= 0;
                    uart_next_state <= IDLE; 
                    -- Default go to IDLE
                    if(data_available = '1' AND uartRdy = '1' ) then    -- If we have data and not outputing anything
                        rx_str(0) <= uart_data_in;                      -- Save the data
                        uart_next_state <= DECODE;
                    end if;
                    
                -- State DECODE: Decode what function the user is accessing
                when DECODE =>
                    if(rx_str(0) = X"72") then
                        uart_next_state <= REGFILE;
                    elsif(rx_str(0) = X"73") then
                        uart_next_state <= STEP;
                    elsif(rx_str(0) = X"75") then
                        uart_next_state <= UNPAUSE;
                    elsif(rx_str(0) = X"70") then
                        uart_next_state <= PC;
                        strEnd <= 23;
                        pc_reg <= PC_IN;
                    else
                        uart_next_state <= IDLE;
                    end if;
                    
                -- State REGFILE: Print out the entire register file
                -- TODO: change this to make it less crappy
                -- reggie_counter indicates how many registers should be printed
                -- reggie_counter_counter is the length of the string printed per register
                when REGFILE =>
                    uart_next_state <= REGFILE;
                    if( reggie_counter_counter = 23) then
                        reggie_counter <= reggie_counter + 1;
                    end if;
                    if(reggie_counter >= 31) then
                        uart_next_state <= REGISTERS;
                    else
                        reggie_str_counter <= reggie_str_counter + 1;
                        case reggie_str_counter is
                        when 0  => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= X"72";
                                   reggie_counter_counter <= 0;
                        when 1  => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(std_logic_vector(to_unsigned(reggie_counter, 4)));
                                   reggie_counter_counter <= 1;
                        when 2  => if(reggie_counter = 32) then
                                    sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(X"2");
                                   elsif(reggie_counter > 15) then
                                    sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(X"1");
                                   else
                                    sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(X"0");
                                   end if;
                                   reggie_counter_counter <= 2;                                                                                       
                        when 3  => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= X"78";
                                   reggie_counter_counter <= 2;
                        when 4 =>  sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(63  downto 60));
                                   reggie_counter_counter <= 3;
                        when 5 =>  sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(59  downto 56));
                                   reggie_counter_counter <= 4;
                        when 6 =>  sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(55  downto 52));
                                   reggie_counter_counter <= 5;
                        when 7 =>  sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(51  downto 48));
                                   reggie_counter_counter <= 6;
                        when 8 =>  sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(47  downto 44));
                                   reggie_counter_counter <= 7;
                        when 9 =>  sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(43  downto 40));
                                   reggie_counter_counter <= 8;
                        when 10 =>  sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(39  downto 36));
                                   reggie_counter_counter <= 9;
                        when 11 => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(35  downto 32));
                                   reggie_counter_counter <= 10;
                        when 12 => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(31  downto 28));
                                   reggie_counter_counter <= 11;
                        when 13 => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(27  downto 24));
                                   reggie_counter_counter <= 12;
                        when 14 => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(23  downto 20));
                                   reggie_counter_counter <= 13;
                        when 15 => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(19  downto 16));
                                   reggie_counter_counter <= 14;
                        when 16 => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(15  downto 12));
                                   reggie_counter_counter <= 15;
                        when 17 => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(11  downto 8));
                                   reggie_counter_counter <= 16;
                        when 18 => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(7  downto 4));
                                   reggie_counter_counter <= 17;
                        when 19 => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= HEX_TO_ASCII(reggie(reggie_counter)(3  downto 0));
                                   reggie_counter_counter <= 18;                                                                                                                     
                        when 20  => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <= X"20";
                                   reggie_counter_counter <= 19;
                        when 21 => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter)  <= X"0A";
                                   reggie_counter_counter <= 20;
                        when 22 => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <=  X"0A";
                                   reggie_counter_counter <= 21;
                        when 23 => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <=  X"0A";
                                   reggie_counter_counter <= 22;
                        when 24 => sendStr(reggie_counter * MAX_REGISTER_LEN + reggie_str_counter) <=  X"0A";
                                   reggie_counter_counter <= 23;
                                   reggie_str_counter <= 0;
                        when others => sendStr(24) <= X"20";
                        end case;
                    end if;
                    
                when PC =>
                        uart_next_state <= PC;
                        if(pc_str_counter > 21) then
                            uart_next_state <= SEND_CHAR;
                        else
                        pc_str_counter <= pc_str_counter + 1;
                         case pc_str_counter is
                            when 1  => sendStr(pc_str_counter) <= X"50";
                            when 2  => sendStr(pc_str_counter) <= X"43";
                            when 3  => sendStr(pc_str_counter) <= X"3A";
                            when 4  => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(63  downto 60));
                            when 5  => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(59  downto 56));
                            when 6  => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(55  downto 52));
                            when 7  => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(51  downto 48));
                            when 8  => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(47  downto 44));
                            when 9  => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(43  downto 40));
                            when 10 => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(39  downto 36));
                            when 11 => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(35  downto 32));
                            when 12 => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(31  downto 28));
                            when 13 => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(27  downto 24));
                            when 14 => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(23  downto 20));
                            when 15 => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(19  downto 16));
                            when 16 => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(15  downto 12));
                            when 17 => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(11  downto 8));
                            when 18 => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(7  downto 4));
                            when 19 => sendStr(pc_str_counter) <= HEX_TO_ASCII(PC_reg(3  downto 0));
                            when 20 => sendStr(pc_str_counter) <= X"20";
                            when 21 => sendStr(pc_str_counter)  <= X"0A";
                            when 22 => sendStr(pc_str_counter) <=  X"0A";
                            when 23 => sendStr(pc_str_counter) <=  X"0A";
                            when 24 => sendStr(pc_str_counter) <=  X"0A";
                            when others => sendStr(24) <= X"20";
                            end case;
                        end if;
                -- State STEP: Step one clock cycle
                -- halt_l is 0, allows the CPU to continue for one clock cycle
                when STEP =>
                    halt_l <= '0';
                    uart_next_state <= STEP_HI;
                    
                -- State STEP_HI: One step done
                -- halt_l is 1, halts the processor
                when STEP_HI =>
                    halt_l <= '1';
                    uart_next_state <= STEP_LO;
                    
                -- State STEP_LO: One step done
                -- If the user wants to skip 2 clock cycles instead of one,
                -- STEP_HI can set halt_l to 0 and STEP_LO can be set to 1
                -- This can be 
                when STEP_LO =>
                    halt_l <= '1';
                    uart_next_state <= RESET_LO;
                    
                -- State REGISTERS: Once the strings are prepared, send the characters
                when REGISTERS =>
                    uart_next_state <= SEND_CHAR;
                    
                -- State SEND_CHAR: Tell the UART controller to print things
                when SEND_CHAR =>
                    strIndex <= strIndex + 1;
                    uartSend <= '1';
                    uartData <= sendStr(strIndex);
                    uart_next_state <= WAIT_CHAR;
                
                -- State WAIT_CHAR: Checks if the entirety of the string
                -- has been sent
                when WAIT_CHAR =>
                    uart_next_state <= WAIT_CHAR;
                    if(strEnd <= strIndex) then
                        uart_next_state <= RESET_LO;
                    elsif(uartRdy = '1') then
                        uart_next_state <= SEND_CHAR;
                    end if;
                    
                -- State RESET_LO: Resets the RX_UART to flush whatever it
                -- had as an input to prepare for the next function
                when RESET_LO =>
                    reset_read <= '1';
                    uart_next_state <= RESET_HI;
                
                -- State RESET_HI:
                when RESET_HI =>
                    reset_read <= '0';
                    uart_next_state <= IDLE;
                    
                -- State UNPAUSE: Lifts the halt_l, allowing the CPU to run normally
                when UNPAUSE =>
                    halt_l <= '0';
                    uart_next_state <= RESET_LO;
                    
                when OTHERS =>
                    uart_next_state <= IDLE;
            end case;
        end if;
    end process;

end Behavioral;
