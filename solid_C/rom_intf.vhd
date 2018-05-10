library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library config;
use work.config.all;

use IEEE.NUMERIC_STD.ALL;

library unisim;
use unisim.VCOMPONENTS.ALL;

entity rom_intf is
    Port ( 
        memAddress       : in  STD_LOGIC_VECTOR (26 downto 0);
        dataIn           : in  STD_LOGIC_VECTOR (7 downto 0);
        dataOut          : out STD_LOGIC_VECTOR (7 downto 0);
        valid            : in  STD_LOGIC;
        done             : out STD_LOGIC;
        write            : in  STD_LOGIC;
        chip_select      : in  STD_LOGIC;
        err              : out STD_LOGIC;
        clk, rst         : in  STD_LOGIC;
        
        -- ROM SPI signals 
        cs_n: out STD_LOGIC;
        dq: inout std_logic_vector(3 downto 0)
    );
end rom_intf;

architecture Behavioral of rom_intf is

type ROM_state is ( INIT, IDLE, SETUP, SETUP_HOLD, FINISH,
                    COMMAND_SET, COMMAND_SEND, COMMAND_HOLD_LOW, COMMAND_HOLD_HIGH,
                    ADDR_SET,    ADDR_SEND,    ADDR_HOLD_LOW,    ADDR_HOLD_HIGH, 
                    DATA_READ,   DATA_SET,     DATA_HOLD_LOW,    DATA_HOLD_HIGH);
signal curr_state : ROM_state := idle;
signal init_counter : integer := 0;

signal s_memAddress     : STD_LOGIC_VECTOR (23 downto 0);
signal s_dataIn         : STD_LOGIC_VECTOR (7 downto 0);

signal sck: std_logic;

constant SPI_OUT : integer := 1;
constant SPI_IN  : integer := 0;
constant READ_COMMAND : STD_LOGIC_VECTOR (7 downto 0) := x"03";

signal count : integer;

begin

STARTUPE2_inst : STARTUPE2
    generic map (
        PROG_USR => "FALSE",    -- Activate program event security feature. Requires encrypted bitstreams.
        SIM_CCLK_FREQ => 10.0    -- Set the Configuration Clock Frequency(ns) for simulation.
    )
    port map (
        CFGCLK => open,                -- 1-bit output: Configuration main clock output
        CFGMCLK => open,               -- 1-bit output: Configuration internal oscillator clock output
        EOS => open,                   -- 1-bit output: Active high output signal indicating the End Of Startup.
        PREQ => open,                  -- 1-bit output: PROGRAM request to fabric output
        CLK => '0',                    -- 1-bit input: User start-up clock input
        GSR => '0',                    -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
        GTS => '0',                    -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
        KEYCLEARB => '0',              -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
        PACK => '0',                   -- 1-bit input: PROGRAM acknowledge input
        USRCCLKO => sck,               -- 1-bit input: User CCLK input
        USRCCLKTS => '0',              -- 1-bit input: User CCLK 3-state enable input
        USRDONEO => '1',               -- 1-bit input: User DONE pin output control
        USRDONETS => '0'               -- 1-bit input: User DONE 3-state enable output
    );


ROM_FSM: process( clk ) 
begin if(rising_edge(clk)) then
    case curr_state is
        when INIT =>
            init_counter <= init_counter + 1;
            if( init_counter > INIT_WAIT ) then
                curr_state  <= idle;
            end if;
            
            done    <= '0';
            cs_n    <= '1';
            sck     <= '0';
            
            dq(SPI_OUT) <= 'Z';
            dq(SPI_IN)  <= 'Z';
            dq(2)       <= 'Z';
            dq(3)       <= 'Z';
        
        when IDLE =>
            done    <= '0';
            cs_n    <= '1';
            sck     <= '0';
            
            dq(SPI_OUT) <= 'Z';
            dq(SPI_IN)  <= 'Z';
            
            if((valid = '1') and (chip_select = '1')) then
                curr_state  <= SETUP;
            end if;
            
        when SETUP =>
            if( (memAddress(26 downto 24) /= "000") or (write = '1')) then
                err         <= '1';
                done        <= '1';
                curr_state  <= IDLE;
            else
                s_memAddress    <= MemAddress(23 downto 0);
                s_dataIn        <= DataIn;
                cs_n            <= '0';
                sck             <= '0';
                count           <= 7;
                curr_state      <= SETUP_HOLD;
            end if;
        
        when SETUP_HOLD =>
                curr_state      <= COMMAND_SET;
        
            
        when COMMAND_SET =>
            sck         <= '0';
            dq(SPI_IN)  <= READ_COMMAND(count);
            curr_state  <= COMMAND_HOLD_LOW;
        
        when COMMAND_HOLD_LOW =>
            curr_state  <= COMMAND_SEND;
        
        when COMMAND_SEND =>
            sck         <= '1';
            curr_state  <= COMMAND_HOLD_HIGH;
        
        when COMMAND_HOLD_HIGH =>
            if( count = 0 ) then
                count       <= 23;
                curr_state  <= ADDR_SET;
            else
                count       <= count - 1;
                curr_state  <= COMMAND_SET;
            end if;
        
        
        
        when ADDR_SET =>
            sck         <= '0';
            dq(SPI_IN)  <= s_memAddress(count);
            curr_state  <= ADDR_HOLD_LOW;
        
        when ADDR_HOLD_LOW =>
            curr_state  <= ADDR_SEND;
        
        when ADDR_SEND =>
            sck         <= '1';
            curr_state  <= ADDR_HOLD_HIGH;
        
        when ADDR_HOLD_HIGH =>
            if( count = 0 ) then
                count       <= 8;
                curr_state  <= DATA_READ;
            else
                count       <= count - 1;
                curr_state  <= ADDR_SET;
            end if;
        
        
        when DATA_READ =>
            sck     <= '0';
            if( count /= 8) then
                dataOut(count) <= dq(SPI_OUT);
            end if;
            curr_state  <= DATA_HOLD_LOW;
        
        when DATA_HOLD_LOW =>
            curr_state  <= DATA_SET;
        
        when DATA_SET =>
            sck         <= '1';
            curr_state  <= DATA_HOLD_HIGH;
        
        when DATA_HOLD_HIGH =>
            if( count = 0 ) then
                curr_state  <= FINISH;
            else
                count       <= count - 1;
                curr_state  <= DATA_READ;
            end if;
            
        
        when FINISH =>
            done <= '1';
            dq(SPI_IN)  <= 'Z';
            sck         <= '0';
            cs_n        <= '1';
            if(valid <= '0') then
                curr_state <= IDLE;
            end if;
    end case;
    
    if('1' = rst) then
        curr_state   <= INIT;
        init_counter <= 0;
    end if;
end if; end process;

end Behavioral;
