----------------------------------------------------------------------------------
-- Engineer: Cesar Avalos B
-- Create Date: 01/28/2018 07:53:02 PM
-- Module Name: MMU_stub - Behavioral
-- Description: Full flegded MMU to feed instructions and store data, supports SV39
--
-- Additional Comments: Mk. VIII
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library config;
use work.config.all;

use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MMU is
    Port(
        clk_100:        in std_logic;                       -- 100 Mhz Clock
        clk:            in std_logic;
        rst:            in std_logic;                       -- Active high reset
        addr_in:        in doubleword;                      -- 64-bits address in
        data_in:        in doubleword;                      -- 64-bits data in
        satp:           in doubleword;                      -- Control register
        mode:           in std_logic_vector(1 downto 0);    -- Current mode (Machine, Supervisor, Etc)
        r_type:         in std_logic_vector(1 downto 0);    -- High to toggle store
        done:           out std_logic;                      -- High when busy
        request:        in std_logic;                       -- CPU request
        num_bytes:      in std_logic_vector(1 downto 0);    --Mask
        data_out:       out doubleword;                     -- 64-Bits data out
        error:          out std_logic_vector(6 downto 0);   -- Error
        debug_phys:     out  doubleword;
        debug_virt:     out  doubleword;
        
        SUM:            in std_logic;
        MXR:            in std_logic;
        MTIP:           out std_logic;
        MSIP:           out std_logic;
        
        -- LEDS out
        LED: out std_logic_vector(15 downto 0);

        -- UART out
        UART_TXD: out std_logic;
        UART_RXD: in std_logic;
        
        -- ROM / RAM lines --
        MEM_addr:       out std_logic_vector(26 downto 0);
        MEM_data_in:    out std_logic_vector(7 downto 0);
        MEM_data_out:   in  std_logic_vector(7 downto 0); 
        MEM_ram:        out std_logic;
        MEM_write:      out std_logic;
        MEM_request:    out std_logic;
        MEM_status:     in  std_logic;
        MEM_err:        in  std_logic
    );
end MMU;

architecture Behavioral of MMU is

-- Components --
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

-- Signals --
type MMU_state is ( INIT, IDLE, SETUP, FINISH, FAULT, ALIGN_FAULT,
                    PAGE_WALK, PAGE_DECODE, PAGE_FAULT, PAGE_LEAF,
                    BUS_ACCESS, ACCESS_MSIP, ACCESS_TIME_CMP, ACCESS_TIME,
                    ACCESS_UART, ACCESS_LEDS, ACCESS_ROM, ACCESS_RAM,
                    ACCESS_MEM_WRITE, ACCESS_MEM_WRITE_WAIT, ACCESS_MEM_WRITE_WAIT_B,
                    ACCESS_MEM_READ,  ACCESS_MEM_READ_WAIT,  ACCESS_MEM_READ_WAIT_B );
signal curr_state, bus_ret_state, bus_err_ret_state :    MMU_state;
signal init_counter : integer := 0;

signal m_time       : doubleword;
signal m_time_cmp   : doubleword;
signal s_MSIP       : std_logic;

-- latched input request
signal s_addr_in:        doubleword;
signal s_data_in:        doubleword;
signal s_mode:           std_logic_vector(1 downto 0);
signal s_r_type:         std_logic_vector(1 downto 0);
signal s_num_bytes:      std_logic_vector(1 downto 0);

-- Page Walk Signals --
signal vpn          : vpn_arr;
signal pt_base      : doubleword;
signal pte          : doubleword;
signal page_index   : integer;

-- Bus request --
signal bus_address      : doubleword;
signal bus_num_bytes    : std_logic_vector(1 downto 0);
signal bus_data_write   : doubleword;
signal bus_data_read    : doubleword;
signal bus_write        : std_logic;

-- UART SIGNALS --
signal uart_send            : std_logic;
signal uart_data_out        : std_logic_vector(7 downto 0);
signal uart_ready           : std_logic;
signal uart_data_in         : std_logic_vector(7 downto 0);
signal uart_data_available  : std_logic;
signal uart_reset_read      : std_logic;

-- EXTERNAL MEMORY SIGNALS
signal mem_buff         : byte_arr;
signal mem_buff_index   : integer;
signal mem_buff_max     : integer;
signal s_MEM_addr       : std_logic_vector(26 downto 0);

begin

        myUARTTX: UART_TX_CTRL port map
        (
            SEND => uart_send,
            DATA => uart_data_out,
            CLK => clk_100,
            READY => uart_ready,
            UART_TX => UART_TXD 
        );
        
        myUARTRX: UART_RX_CTRL port map
        (
            UART_RX => UART_RXD,
            CLK => clk_100,
            DATA => uart_data_in,
            READ_DATA => uart_data_available,
            RESET_READ => uart_reset_read
        );
           
MSIP <= s_MSIP;


MMU_FSM: process( clk )
    variable bus_address_top  : doubleword;
begin if(rising_edge(clk)) then
    m_time <= m_time + 1;
    if( m_time >= m_time_cmp ) then
        MTIP <= '1';
    else
        MTIP <= '0';
    end if;
    
    case curr_state is
        when INIT =>
            init_counter <= init_counter + 1;
            if( init_counter > INIT_WAIT ) then
                curr_state  <= idle;
            end if;
            
            done        <= '0';
            LED         <= (others => '0');
            MEM_request <= '0';
            m_time      <= ALL_ZERO;
            m_time_cmp  <= ALL_ZERO;
            uart_send       <= '0';
            uart_reset_read <= '0';
            debug_phys      <= ALL_ZERO;
            debug_virt      <= ALL_ZERO;
            data_out        <= ALL_ZERO;
            
            MTIP       <= '0';
            s_MSIP       <= '0';
        when idle =>
            done    <= '0';
            if(request = '1') then
                curr_state <= SETUP;
            end if;
        
        when SETUP =>
                s_addr_in   <= addr_in;
                s_data_in   <= data_in;
                s_mode      <= mode;
                s_r_type    <= r_type;
                s_num_bytes <= num_bytes;
                
                if( r_type = MEM_FETCH ) then
                    debug_virt <= addr_in;
                end if;
                
                case satp(SATP_MODE_H downto SATP_MODE_L) is
                    when SATP_MODE_SV39 =>
                        page_index  <= 2;
                        vpn(2)   <= s_addr_in(38 downto 30);
                        vpn(1)   <= s_addr_in(29 downto 21);
                        vpn(0)   <= s_addr_in(20 downto 12);
                        pt_base  <= zero_byte & satp(SATP_PPN_H downto SATP_PPN_L) & zero_byte & "0000";
                        curr_state <= PAGE_WALK;
                    when others =>
                        bus_address         <= addr_in;
                        bus_num_bytes       <= num_bytes;
                        bus_ret_state       <= FINISH;
                        bus_err_ret_state   <= FAULT;
                        curr_state          <= BUS_ACCESS;
                        if( r_type = MEM_STORE ) then
                            bus_write           <= '1';
                            bus_data_write      <= data_in;
                        else
                            bus_write           <= '0';
                        end if;
                end case;
        
        when PAGE_FAULT =>
                if( request = '0' ) then
                    curr_state          <= IDLE;
                end if;
                
                if(    s_r_type = MEM_FETCH ) then
                    error <= CAUSE_INSTRUCTION_PAGE_FAULT;
                elsif( s_r_type = MEM_LOAD ) then
                    error <= CAUSE_LOAD_PAGE_FAULT;
                else
                    error <= CAUSE_STORE_AMO_PAGE_FAULT;
                end if;
                
                done <= '1';
        
        when ALIGN_FAULT =>
                if( request = '0' ) then
                    curr_state          <= IDLE;
                end if;
                
                if(    s_r_type = MEM_FETCH ) then
                    error <= CAUSE_INSTRUCTION_ADDRESS_MISALIGNED;
                elsif( s_r_type = MEM_LOAD ) then
                    error <= CAUSE_LOAD_ADDRESS_MISALIGNED;
                else
                    error <= CAUSE_STORE_AMO_ADDRESS_MISALIGNED;
                end if;
                
                done <= '1';
                
        when FAULT =>
                if( request = '0' ) then
                    curr_state          <= IDLE;
                end if;
                
                if(    s_r_type = MEM_FETCH ) then
                    error <= CAUSE_INSTRUCTION_ACCESS_FAULT;
                elsif( s_r_type = MEM_LOAD ) then
                    error <= CAUSE_LOAD_ACCESS_FAULT;
                else
                    error <= CAUSE_STORE_AMO_ACCESS_FAULT;
                end if;
                
                done <= '1';
        
        
        when PAGE_WALK =>
                bus_address         <= pt_base(63 downto 12) & vpn(page_index) & "000";
                bus_num_bytes       <= MEM_BYTES_8;
                bus_write           <= '0';
                bus_ret_state       <= PAGE_DECODE;
                bus_err_ret_state   <= PAGE_FAULT;
                curr_state          <= BUS_ACCESS;
        
        when PAGE_DECODE =>
                if(     (bus_data_read(PTE_V) = '0') 
                    or ((bus_data_read(PTE_R) = '0') and (bus_data_read(PTE_W) = '1')))
                then
                    curr_state <= PAGE_FAULT;
                elsif( (bus_data_read(PTE_R) = '1') or (bus_data_read(PTE_X) = '1') ) then
                    pte         <= bus_data_read;
                    curr_state  <= PAGE_LEAF;
                else
                    -- node
                    pt_base <= zero_byte & bus_data_read(PTE_PPN_H downto PTE_PPN_L) & zero_byte & "0000";
                    page_index <= page_index - 1;
                    if( page_index = 0 ) then
                        curr_state <= PAGE_FAULT;
                    else
                        curr_state <= PAGE_WALK;
                    end if;
                end if;
        
        when PAGE_LEAF =>
                if(     (s_r_type = MEM_FETCH) and (pte(PTE_X) = '0') ) then
                    curr_state <= PAGE_FAULT;
                elsif( ((s_r_type = MEM_LOAD ) and (pte(PTE_R) = '0'))
                        and ((MXR = '0') or ((MXR = '1') and (pte(PTE_X) = '0')))  )
                then
                    curr_state <= PAGE_FAULT;
                elsif( (s_r_type = MEM_STORE) and (pte(PTE_W) = '0')) then
                    curr_state <= PAGE_FAULT;
                elsif( (s_mode = USER_MODE) and (pte(PTE_U) = '0') ) then
                    curr_state <= PAGE_FAULT;
                elsif( (s_mode = SUPERVISOR_MODE) and (pte(PTE_U) = '1') and (SUM = '0') ) then
                    curr_state <= PAGE_FAULT;
                else
                    if(    (page_index = 1) and ( pte(18 downto 10) /= "000000000" ) ) then
                        curr_state <= PAGE_FAULT;
                    elsif( (page_index = 2) and ( pte(27 downto 10) /= "000000000000000000" ) ) then
                        curr_state <= PAGE_FAULT;
                    elsif( (pte(PTE_A) = '0') or ( (pte(PTE_D) = '0') and (s_r_type = MEM_LOAD) ) ) then
                        curr_state <= PAGE_FAULT;
                    else
                        bus_address(63 downto 56) <= zero_byte;
                        if( page_index = 0 ) then
                            bus_address(55 downto 12) <= pte(53 downto 10);
                        elsif( page_index = 1 ) then
                            bus_address(55 downto 12) <= pte(53 downto 19) & "000000000";
                        else
                            bus_address(55 downto 12) <= pte(53 downto 28) & "000000000000000000";
                        end if;
                        
                        bus_address(11 downto 0) <= s_addr_in(11 downto 0);
                        bus_num_bytes            <= s_num_bytes;
                        bus_ret_state            <= FINISH;
                        bus_err_ret_state        <= FAULT;
                        curr_state               <= BUS_ACCESS;
                        if( s_r_type = MEM_STORE ) then
                            bus_write           <= '1';
                        else
                            bus_write           <= '0';
                            bus_data_write      <= s_data_in;
                        end if;
                    end if;
                end if;
                    
        when BUS_ACCESS =>
                if(    (bus_num_bytes = MEM_BYTES_8) and (bus_address(2 downto 0) /= "000") ) then
                    curr_state  <= ALIGN_FAULT;
                elsif( (bus_num_bytes = MEM_BYTES_4) and (bus_address(1 downto 0) /= "00" ) ) then
                    curr_state  <= ALIGN_FAULT;
                elsif( (bus_num_bytes = MEM_BYTES_2) and (bus_address(0) /= '0' ) ) then
                    curr_state  <= ALIGN_FAULT;
                else
                    if(    bus_num_bytes = MEM_BYTES_8 ) then
                        bus_address_top := bus_address + 7;
                    elsif( bus_num_bytes = MEM_BYTES_4 ) then
                        bus_address_top := bus_address + 3;
                    elsif( bus_num_bytes = MEM_BYTES_2 ) then
                        bus_address_top := bus_address + 1;
                    else
                        bus_address_top := bus_address;
                    end if;
                    
                    
                    if( bus_address(63 downto 32) /= x"00000000" ) then
                        curr_state  <= bus_err_ret_state;
                    elsif( bus_address(31 downto 16) = x"0200" ) then
                        if(   ( bus_address(15 downto 0) >= x"0000" ) and ( bus_address_top(15 downto 0) < x"0004" ) ) then
                            curr_state  <= ACCESS_MSIP;
                        elsif(( bus_address(15 downto 0) >= x"4000" ) and ( bus_address_top(15 downto 0) < x"4008" ) ) then
                            curr_state  <= ACCESS_TIME_CMP;
                        elsif(( bus_address(15 downto 0) >= x"bff8" ) and ( bus_address_top(15 downto 0) < x"c000" ) ) then
                            curr_state  <= ACCESS_TIME;
                        else
                            curr_state  <= bus_err_ret_state;
                        end if;
                    elsif( bus_address = x"000000008FFFFFFC" ) then
                        bus_data_read(31 downto 0) <= x"00000013";
                        curr_state  <= FINISH;
                    elsif( bus_address(31 downto 20) = x"980" ) then
                        if(   ( bus_address(19 downto 0) >= x"10000" ) and ( bus_address_top(19 downto 0) < x"10006" ) ) then
                            curr_state  <= ACCESS_UART;
                        elsif(( bus_address(19 downto 0) >= x"00000" ) and ( bus_address_top(19 downto 0) < x"00002" ) ) then
                            curr_state  <= ACCESS_LEDS;
                        else
                            curr_state  <= bus_err_ret_state;
                        end if;
                    elsif( bus_address(31 downto 28) = x"9"  ) then
                        if(   ( bus_address(27 downto 24) >= x"0" ) and ( bus_address_top(27 downto 24) < x"8" ) ) then
                            curr_state  <= ACCESS_ROM;
                            MEM_ram     <= '0';
                        else
                            curr_state  <= bus_err_ret_state;
                        end if;
                    elsif( bus_address(31 downto 28) = x"8"  ) then
                        if(   ( bus_address(27 downto 24) >= x"0" ) and ( bus_address_top(27 downto 24) < x"8" ) ) then
                            curr_state  <= ACCESS_RAM;
                            MEM_ram     <= '1';
                        else
                            curr_state  <= bus_err_ret_state;
                        end if;
                    else
                        curr_state  <= bus_err_ret_state;
                    end if;
                end if;
                
                
        when FINISH =>
                if( request = '0' ) then
                    curr_state          <= IDLE;
                end if;
                            
                if( bus_write = '0') then
                    data_out <= bus_data_read;
                end if;
                
                uart_send       <= '0';
                uart_reset_read <= '0';
                
                if( s_r_type = MEM_FETCH ) then
                    debug_phys      <= bus_address;
                end if;
                
                done        <= '1';
                error       <= MEM_ERR_NONE;
                
                        
        when ACCESS_MSIP =>
                if( bus_write = '1') then
                    if( bus_data_write(0) = '1' ) then
                        s_MSIP <= '1';
                    else
                        s_MSIP <= '0';
                    end if;
                else
                    bus_data_read(63 downto 1) <= ALL_ZERO(63 downto 1);
                    if( s_MSIP = '1' ) then
                        bus_data_read(0) <= '1';
                    else
                        bus_data_read(0) <= '0';
                    end if;
                end if;
                
                curr_state  <= bus_ret_state;
        
        
        when ACCESS_TIME_CMP =>
                if( bus_num_bytes = MEM_BYTES_8 ) then
                    if( bus_write = '1') then
                        m_time_cmp <= bus_data_write;
                    else
                        bus_data_read <= m_time_cmp;
                    end if;
                    
                    curr_state  <= bus_ret_state;
                else
                    curr_state  <= bus_err_ret_state;
                end if;
        
        when ACCESS_TIME =>
                if( bus_num_bytes = MEM_BYTES_8 ) then
                    if( bus_write = '1') then
                        m_time <= bus_data_write;
                    else
                        bus_data_read <= m_time;
                    end if;
                    
                    curr_state  <= bus_ret_state;
                else
                    curr_state  <= bus_err_ret_state;
                end if;
        
        when ACCESS_UART =>
                if( bus_num_bytes = MEM_BYTES_1 ) then
                    if( bus_write = '1') then
                        case bus_address(3 downto 0) is
                            when X"0" =>  curr_state        <= bus_err_ret_state;
                            when X"1" =>  curr_state        <= bus_err_ret_state;
                            when X"2" =>  uart_reset_read   <= '1';
                                          curr_state        <= bus_ret_state;
                            
                            when X"3" =>  uart_data_out <= bus_data_write(7 downto 0);
                                          curr_state    <= bus_ret_state;
                            when X"4" =>  curr_state    <= bus_err_ret_state;
                            when X"5" =>  uart_send     <= '1';
                                          curr_state    <= bus_ret_state;
                            
                            when others => curr_state        <= bus_err_ret_state;
                        end case;
                    else
                        case bus_address(3 downto 0) is
                            when X"0" =>  bus_data_read(7 downto 0) <= uart_data_in;
                                          curr_state                <= bus_ret_state;
                            when X"1" =>  
                                    if( uart_data_available = '1' ) then
                                        bus_data_read(7 downto 0) <= x"01";
                                    else
                                        bus_data_read(7 downto 0) <= x"00";
                                    end if;
                                    
                                    curr_state  <= bus_ret_state;
                            when X"2" =>  curr_state    <= bus_err_ret_state;
                            
                            when X"3" =>  curr_state    <= bus_err_ret_state;
                            when X"4" =>  
                                    if( uart_ready = '1' ) then
                                        bus_data_read(7 downto 0) <= x"01";
                                    else
                                        bus_data_read(7 downto 0) <= x"00";
                                    end if;
                                    
                                    curr_state  <= bus_ret_state;
                            when X"5" =>  curr_state    <= bus_err_ret_state;
                            
                            when others => curr_state        <= bus_err_ret_state;
                        end case;
                    end if;
                else
                    curr_state  <= bus_err_ret_state;
                end if;
        
        
        when ACCESS_LEDS =>
                if( ( bus_num_bytes = MEM_BYTES_2 ) and ( bus_write = '1' ) ) then
                    LED <= bus_data_write(15 downto 0);
                    curr_state  <= bus_ret_state;
                else
                    curr_state    <= bus_err_ret_state;
                end if;
        
        
        when ACCESS_ROM | ACCESS_RAM =>
                mem_buff_index <= 0;
                s_MEM_addr     <= bus_address(26 downto 0);
                if(    bus_num_bytes = MEM_BYTES_8 ) then
                    mem_buff_max <= 8;
                elsif( bus_num_bytes = MEM_BYTES_4 ) then
                    mem_buff_max <= 4;
                elsif( bus_num_bytes = MEM_BYTES_2 ) then
                    mem_buff_max <= 2;
                else
                    mem_buff_max <= 1;
                end if;
                
                if( bus_write = '1' ) then
                    MEM_write <= '1';
                    if(    bus_num_bytes = MEM_BYTES_8 ) then
                        mem_buff(0) <= bus_data_write(7 downto 0);   mem_buff(1) <= bus_data_write(15 downto 8);
                        mem_buff(2) <= bus_data_write(23 downto 16); mem_buff(3) <= bus_data_write(31 downto 24);
                        mem_buff(4) <= bus_data_write(39 downto 32); mem_buff(5) <= bus_data_write(47 downto 40);
                        mem_buff(6) <= bus_data_write(55 downto 48); mem_buff(7) <= bus_data_write(63 downto 56);
                    elsif( bus_num_bytes = MEM_BYTES_4 ) then
                        mem_buff(0) <= bus_data_write(7 downto 0);   mem_buff(1) <= bus_data_write(15 downto 8);
                        mem_buff(2) <= bus_data_write(23 downto 16); mem_buff(3) <= bus_data_write(31 downto 24);
                    elsif( bus_num_bytes = MEM_BYTES_2 ) then
                        mem_buff(0) <= bus_data_write(7 downto 0);   mem_buff(1) <= bus_data_write(15 downto 8);
                    else
                        mem_buff(0) <= bus_data_write(7 downto 0);
                    end if;
                    
                    curr_state    <= ACCESS_MEM_WRITE;
                else
                    MEM_write  <= '0';
                    curr_state <= ACCESS_MEM_READ;
                end if;
        
        when ACCESS_MEM_WRITE =>
                if( mem_buff_index = mem_buff_max ) then
                    curr_state  <= bus_ret_state;
                else
                    if( MEM_status = '0' ) then
                        mem_buff_index  <= mem_buff_index + 1;
                        s_MEM_addr      <= s_MEM_addr + 1;
                        MEM_addr        <= s_MEM_addr;
                        MEM_data_in     <= mem_buff(mem_buff_index);
                        MEM_request     <= '1';
                        curr_state      <= ACCESS_MEM_WRITE_WAIT;
                    end if;
                end if;
        
        when ACCESS_MEM_WRITE_WAIT =>
                if( MEM_status = '1' ) then
                    curr_state <= ACCESS_MEM_WRITE_WAIT_B;
                end if;
        
        when ACCESS_MEM_WRITE_WAIT_B =>
                MEM_request <= '0';
                
                if( MEM_err = '1') then
                    curr_state  <= bus_err_ret_state;
                else
                    curr_state  <= ACCESS_MEM_WRITE;
                end if;
        
        when ACCESS_MEM_READ =>
                if( mem_buff_index = mem_buff_max ) then
                    curr_state  <= bus_ret_state;
                    if(    bus_num_bytes = MEM_BYTES_8 ) then
                        bus_data_read(7 downto 0)   <= mem_buff(0); bus_data_read(15 downto 8)  <= mem_buff(1);
                        bus_data_read(23 downto 16) <= mem_buff(2); bus_data_read(31 downto 24) <= mem_buff(3);
                        bus_data_read(39 downto 32) <= mem_buff(4); bus_data_read(47 downto 40) <= mem_buff(5);
                        bus_data_read(55 downto 48) <= mem_buff(6); bus_data_read(63 downto 56) <= mem_buff(7);
                    elsif( bus_num_bytes = MEM_BYTES_4 ) then
                        bus_data_read(7 downto 0)   <= mem_buff(0); bus_data_read(15 downto 8)  <= mem_buff(1);
                        bus_data_read(23 downto 16) <= mem_buff(2); bus_data_read(31 downto 24) <= mem_buff(3);
                    elsif( bus_num_bytes = MEM_BYTES_2 ) then
                        bus_data_read(7 downto 0)   <= mem_buff(0); bus_data_read(15 downto 8)  <= mem_buff(1);
                    else
                        bus_data_read(7 downto 0)   <= mem_buff(0);
                    end if;
                else
                    if( MEM_status = '0' ) then
                        MEM_addr        <= s_MEM_addr;
                        MEM_request     <= '1';
                        curr_state      <= ACCESS_MEM_READ_WAIT;
                    end if;
                end if;
        
        when ACCESS_MEM_READ_WAIT =>
                if( MEM_status = '1' ) then
                    curr_state <= ACCESS_MEM_READ_WAIT_B;
                end if;
        
        when ACCESS_MEM_READ_WAIT_B =>
                MEM_request <= '0';
                
                if( MEM_err = '1') then
                    curr_state  <= bus_err_ret_state;
                else
                    curr_state  <= ACCESS_MEM_READ;
                    s_MEM_addr      <= s_MEM_addr + 1;
                    mem_buff_index  <= mem_buff_index + 1;
                    mem_buff(mem_buff_index) <= MEM_data_out;
                end if;           
    end case;
    
    if('1' = rst) then
        curr_state   <= INIT;
        init_counter <= 0;
    end if;
end if; end process;

end Behavioral;
