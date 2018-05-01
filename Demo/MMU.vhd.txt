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

library unisim;
use unisim.VCOMPONENTS.ALL;


entity MMU is
    Port(
        clk: in std_logic;                      -- 100 Mhz Clock
        rst: in std_logic;                      -- Active high reset
        addr_in: in doubleword;                 -- 64-bits address in
        data_in: in doubleword;                 -- 64-bits data in
        satp: in doubleword;                    -- Control register
        mode: in std_logic_vector(1 downto 0);  -- Current mode (Machine, Supervisor, Etc)
        store: in std_logic;                    -- High to toggle store 
        load: in std_logic;                     -- High to toggle load
        busy: out std_logic := '0';             -- High when busy
        ready_instr: in std_logic;              -- Can fetch next instruction (might be redundant)
        addr_instr: in doubleword;              -- Instruction Address (AKA PC)
        alignment: in std_logic_vector(3 downto 0); --Mask
        data_out: out doubleword;               -- 64-Bits data out
        instr_out: out word;              -- 64-Bits instruction out
        error: out std_logic_vector(5 downto 0);-- Error
        
        -- LEDS out
        LED: out std_logic_vector(15 downto 0);

        -- UART out
        UART_TXD: out std_logic;
        UART_RXD: in std_logic;

        -- DDR2 Signals
        ddr2_addr : out STD_LOGIC_VECTOR (12 downto 0);
        ddr2_ba : out STD_LOGIC_VECTOR (2 downto 0);
        ddr2_ras_n : out STD_LOGIC;
        ddr2_cas_n : out STD_LOGIC;
        ddr2_we_n : out STD_LOGIC;
        ddr2_ck_p : out std_logic_vector(0 downto 0);
        ddr2_ck_n : out std_logic_vector(0 downto 0);
        ddr2_cke : out std_logic_vector(0 downto 0);
        ddr2_cs_n : out std_logic_vector(0 downto 0);
        ddr2_dm : out STD_LOGIC_VECTOR (1 downto 0);
        ddr2_odt : out std_logic_vector(0 downto 0);
        ddr2_dq : inout STD_LOGIC_VECTOR (15 downto 0);
        ddr2_dqs_p : inout STD_LOGIC_VECTOR (1 downto 0);
        ddr2_dqs_n : inout STD_LOGIC_VECTOR (1 downto 0);

        -- ROM SPI signals
        sck: out std_logic;  -- Special gated sck for the ROM STARTUPE2 generic 
        cs_n: out STD_LOGIC;
        dq: inout std_logic_vector(3 downto 0));
end MMU;

architecture Behavioral of MMU is

-- Components
component ram_controller is
    Port ( clk_200,clk_100 : in STD_LOGIC;
           rst : in STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR(15 DOWNTO 0);
           data_out : out STD_LOGIC_VECTOR(15 DOWNTO 0);
           write, read: in STD_LOGIC;
           mask_lb, mask_ub: in std_logic;
           done: out STD_LOGIC;
           contr_addr_in : in STD_LOGIC_VECTOR(26 DOWNTO 0);
           ddr2_addr : out STD_LOGIC_VECTOR (12 downto 0);
           ddr2_ba : out STD_LOGIC_VECTOR (2 downto 0);
           ddr2_ras_n : out STD_LOGIC;
           ddr2_cas_n : out STD_LOGIC;
           ddr2_we_n : out STD_LOGIC;
           ddr2_ck_p : out std_logic_vector(0 downto 0);
           ddr2_ck_n : out std_logic_vector(0 downto 0);
           ddr2_cke : out std_logic_vector(0 downto 0);
           ddr2_cs_n : out std_logic_vector(0 downto 0);
           ddr2_dm : out STD_LOGIC_VECTOR (1 downto 0);
           ddr2_odt : out std_logic_vector(0 downto 0);
           ddr2_dq : inout STD_LOGIC_VECTOR (15 downto 0);
           ddr2_dqs_p : inout STD_LOGIC_VECTOR (1 downto 0);
           ddr2_dqs_n : inout STD_LOGIC_VECTOR (1 downto 0));
end component;


component ROM_controller_SPI is
 Port (clk_25, rst, read: in STD_LOGIC;
       si_i: out STD_LOGIC;
       cs_n: out STD_LOGIC;
       wp: out std_logic;
       si_t: out std_logic;
       wp_t: out std_logic; 
       address_in: in STD_LOGIC_VECTOR(23 downto 0);
       qd: in STD_LOGIC_VECTOR(3 downto 0);
       data_out: out STD_LOGIC_VECTOR(63 downto 0);
       --pragma synthesis_off
        counter: out integer;
       --pragma synthesis_on
     --  command_int, address_int, reg_one_int, reg_two_int: inout integer;
       done: out STD_LOGIC
       );
end component;

component clk_wiz_0
    port(
    clk_in1 : in std_logic;
    clk_100MHz_o: out std_logic;
    clk_200MHz_o: out std_logic;
    clk_25MHz_o: out std_logic;
    locked: out std_logic);
end component;

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
   
   component SPIFlashModule is
   port(clk, reset, io_flash_en, io_flash_write, io_read_id: in std_logic;
        io_quad_io: in std_logic_vector(3 downto 0);
        io_flash_addr:  in std_logic_vector(23 downto 0);
        io_flash_data_in: in std_logic_vector(31 downto 0);
        io_flash_data_out: out std_logic_vector(31 downto 0);
        io_state_to_cpu: out std_logic_vector(11 downto 0);
        io_sck_gate, io_SI, io_WP, io_tri_si, io_tri_wp, io_cs, io_ready: out std_logic);
   end component;

constant ROM_period : integer := 150;

type instsmem is array(0 to 100) of word;
signal instr_mem: instsmem := (others => (others => '0'));
signal ROM_mem: instsmem := (
0  => x"00001137",
1  => x"8071011b",
2  => x"01411113",
3  => x"0040006f",
4  => x"01300793",
5  => x"01b79793",
6  => x"00100713",
7  => x"00e79023",
8  => x"098017b7",
9 =>  x"00000697",
10 => x"09468693",
11 => x"02100713",
12 => x"00479793",
13 => x"00100593",
14 => x"0047c603",
15 => x"0ff67613",
16 => x"fe060ce3",
17 => x"00e781a3",
18 => x"00b782a3",
19 => x"00168693",
20 => x"0006c703",
21 => x"fe0712e3",
22 => x"09801737",
23 => x"01300513",
24 => x"00100693",
25 => x"00471713",
26 => x"00100593",
27 => x"01b51513",
28 => x"00174783",
29 => x"0ff7f793",
30 => x"fe078ce3",
31 => x"00074603",
32 => x"0016869b",
33 => x"03069693",
34 => x"00b70123",
35 => x"0306d693",
36 => x"0ff67613",
37 => x"00d51023",
38 => x"00474783",
39 => x"0ff7f793",
40 => x"fe078ce3",
41 => x"00c701a3",
42 => x"00b702a3",
43 => x"fc5ff06f",
46 => x"45212121",
47 => x"204F4843",
48 => x"56524553",
49 => x"45522121",
50 => x"0000A021",
others => (others => '0'));

-- SPI signals
signal io_flash_en:        std_logic;
signal io_flash_write:     std_logic;
signal io_quad_io:         std_logic_vector(3 downto 0);
signal io_flash_addr:      std_logic_vector(23 downto 0);
signal io_flash_data_in:   std_logic_vector(31 downto 0);
signal io_flash_data_out:  std_logic_vector(63 downto 0);
signal io_read_id:         std_logic;
signal io_state_to_cpu:    std_logic_vector(11 downto 0);
signal io_SI, io_WP, io_tri_si, io_tri_wp, io_cs, io_ready: std_logic;
signal io_srl, io_cr : std_logic_vector(7 downto 0);
signal io_sckgate: std_logic;   
signal io_rst: std_logic;
type MMU_state is (idle, loading, storing, fetching, decode_state,page_walk,loading_ram_page_walk, loading_ram, loading_rom, done_uart_rx, done_uart_tx, storing_ram);
signal curr_state:    MMU_state := idle;
signal next_state:    MMU_state := idle;
signal paused_state : MMU_state := idle; --Bit of a misnomer, this is 

signal LED_reg: std_logic_vector(15 downto 0);

-- RAM signals
signal w_en: std_logic := '0';
signal RAM_en, ROM_en: std_logic := '0';
type RAM_state is (idle, read_low, read_low_mid, read_upper_mid, read_upper,write_low, write_low_mid, write_upper_mid, write_upper, done);
signal RAM_curr_state : RAM_state := idle;
signal RAM_next_state : RAM_state := idle;
signal RAM_masks: std_logic_vector(7 downto 0);
signal RAM_timeout_counter: integer:= 0;
signal RAM_data_in: std_logic_vector(15 downto 0);
signal RAM_data_out: std_logic_vector(15 downto 0);
signal RAM_address_in: std_logic_vector(26 downto 0);
signal RAM_lb, RAM_ub: std_logic := '1';

signal s_RAM_data_out: doubleword := (others => '0'); -- The register holding the ram doubleword
signal ROM_done, RAM_done: std_logic := '0';
signal BRAM_toggle : std_logic_vector(1 downto 0) := "00";

--32 Bits acceses for ROM, either, too slow
type ROM_state is (idle, reading_lower, reading_higher, done);
signal ROM_curr_state : ROM_state := idle;
signal ROM_next_state : ROM_state := idle;
signal gated_clk: std_logic := '0';
signal s_ROM_data_out: doubleword := (others => '0'); --Register holding the rom doubleword
signal ROM_address_in : std_logic_vector(23 downto 0);
signal s_ROM_done: std_logic;
-- UART out data signal, for reading UART registers
signal ROM_Counter: integer := 0;
signal UART_out: STD_LOGIC_VECTOR(7 downto 0);
signal UART_toggle : std_logic := '0';

signal SATP_mode: std_logic_vector(63 downto 0) := (others => '0');
signal SATP_PPN: std_logic_vector(63 downto 0) := (others => '0');

signal s_internal_data : std_logic_vector(63 downto 0);
signal s_internal_address: doubleword;

signal clk_100, clk_200, clk_25, locked: std_logic;

signal page_address_in: doubleword := (others => '0');
signal uart_data_in, uart_data_out: std_logic_vector(7 downto 0);
signal uart_data_available, uart_ready: std_logic;
signal uart_reset_read, uart_send: std_logic;
signal UART_data: doubleword;

signal m_timer: integer := 0;

Type PAGE_WALK_STATE is (idle,level_i_read, level_i_decode, done);
signal PAGE_WALK_next_state, PAGE_WALK_current_state: PAGE_WALK_STATE := idle;
signal s_page_walk,page_walk_request_read, page_walk_done: std_logic := '0';
signal page_walk_address_out, page_address_final: doubleword;

signal Intermitent_Address_In: doubleword;

signal addr_in_latch: doubleword;

-- Debugging
signal s_debugging_out: std_logic_vector(5 downto 0);
signal qd: std_logic_vector(3 downto 0);

signal gated_clock, clock_gate: std_logic;
signal io_sck_gate: std_logic;
begin

clk_wizard: clk_wiz_0 
port map(
    clk_in1 =>clk,
    clk_100MHz_o => clk_100,
    clk_200MHz_o => clk_200,
    clk_25MHz_o => clk_25,
    locked => locked
);

myRAMController: ram_controller port map
(
    clk_200 => clk_200, 
    clk_100 => clk_100,
    rst        => rst, 
    data_in    => RAM_data_in,
    data_out   => RAM_data_out,
    mask_lb => RAM_lb,
    mask_ub => RAM_ub,
    done       => RAM_done,
    write      => w_en, 
    read       => RAM_en, 
    contr_addr_in  => RAM_address_in, 
    ddr2_addr  => ddr2_addr , 
    ddr2_ba    => ddr2_ba   , 
    ddr2_ras_n => ddr2_ras_n, 
    ddr2_cas_n => ddr2_cas_n, 
    ddr2_we_n  => ddr2_we_n , 
    ddr2_ck_p  => ddr2_ck_p , 
    ddr2_ck_n  => ddr2_ck_n , 
    ddr2_cke   => ddr2_cke  , 
    ddr2_cs_n  => ddr2_cs_n , 
    ddr2_dm    => ddr2_dm   , 
    ddr2_odt   => ddr2_odt  ,
    ddr2_dq    => ddr2_dq   , 
    ddr2_dqs_p => ddr2_dqs_p, 
    ddr2_dqs_n => ddr2_dqs_n 
    );



myROMController: ROM_controller_SPI port map(clk_25 => clk_25, rst => io_rst, read =>io_flash_en,
    address_in => ROM_address_in, data_out => io_flash_data_out,
    si_i =>io_SI, wp => io_WP, si_t => io_tri_si, wp_t => io_tri_wp, 
    cs_n => io_cs, qd => qd, done =>s_ROM_done);

--myROMController: SPIFlashModule port map(
--  clk => clk_25, reset => io_rst, io_flash_en => io_flash_en, io_flash_write => io_flash_write, io_read_id => io_read_id,
--        io_quad_io => qd, io_flash_addr => ROM_address_in, io_flash_data_in => io_flash_data_in,
--        io_flash_data_out => io_flash_data_out, io_state_to_cpu => io_state_to_cpu,
--        io_sck_gate => io_sckgate, io_SI => io_SI, io_WP => io_WP, io_tri_si => io_tri_si, io_tri_wp => io_tri_wp, io_cs => io_cs, 
--        io_ready => io_ready);
        
cs_n <= io_cs;

myUARTTX: UART_TX_CTRL port map
(
  SEND => uart_send,
  DATA => uart_data_out,
  CLK => CLK,
  READY => uart_ready,
  UART_TX => UART_TXD 
  );

myUARTRX: UART_RX_CTRL port map
(
  UART_RX => UART_RXD,
  CLK => CLK,
  DATA => uart_data_in,
  READ_DATA => uart_data_available,
  RESET_READ => uart_reset_read
  );
           

-- Advance state
STATE_ADVANCE: process(clk, rst, RAM_done, ROM_done)
begin
    if('1' = rst) then
        curr_state <= idle;
        ROM_curr_state <= idle;
        RAM_curr_state <= idle;
        PAGE_WALK_current_state <= idle;
        m_timer <= 0;
    elsif(rising_edge(clk)) then
        curr_state <= next_state;
        RAM_curr_state <= RAM_next_state;
        ROM_curr_state <= ROM_next_state;
        PAGE_WALK_current_state <= PAGE_WALK_next_state;
        m_timer <= m_timer + 1;
    end if;
end process;

MMU_FSM: process(clk, rst) 
 -- variable s_internal_address: doubleword := (others => '0'); --Realized Physical Address
 -- variable paused_state: MMU_state; -- When we find the mode from SATP, we resume from the state saved here 
  begin
  if rst = '1' then
    s_internal_address <= (others => '0');
    instr_out <= (others => '0');
    error <= (others => '0');
    io_flash_write <= '0';
    io_read_id <= '0';
    next_state <= idle;
    busy <= '0';
    BRAM_toggle <= "11";
    LED <= (others => '0');
    UART_data <= (others => '0');
    data_out <= (others => '0');
  elsif(rising_edge(clk)) then
    busy <= '1';
    next_state <= curr_state;
    case curr_state is

      -- Idling by like the leech you are MMU arent U
      when idle =>
          busy <= '1';
          UART_toggle <= '0';
          s_debugging_out <= "000000";
        --s_internal_address <= addr_in;
          uart_reset_read <= '0';
          uart_send <= '0';
        if(load = '1') then
          next_state <= decode_state;
          paused_state <= loading;
          s_internal_address <= addr_in;
        elsif(store = '1') then
          next_state <= decode_state;
          paused_state <= storing;
          s_internal_address <= addr_in;
        elsif(ready_instr = '1') then
          next_state <= decode_state;
          s_internal_address <= addr_instr;
          paused_state <= fetching;
        else
          busy <= '0';
        end if;

      -- Figure out what state are we at
      when decode_state =>
        s_debugging_out <= "000001";
        case satp_mode(3 downto 0) is
          when x"0" => -- No translation is assumed
            next_state <= paused_state;
          when others =>
            next_state <= page_walk; --SV39 is assumed whenever anything else is written, no SV48 shenanigans
        end case;

      -- Walk the thing blue page walk line
      when page_walk =>
        s_debugging_out <= "000010";
        s_page_walk <= '1'; --We enable the page walk process
        if(page_walk_done = '1') then --Page walk is done
          s_internal_address <= page_walk_address_out; -- We assign the newly discovered address
          next_state <= paused_state; --Resume wherever we left off matey
        elsif(page_walk_request_read = '1') then
           RAM_en <= '1';
        end if;

        -- Intermediate fetching state, just check if there is any misalignment errors
        when fetching =>
        busy <= '1';
        s_debugging_out <= "000011";
          --Fetches have to be aligned
          if(unsigned(s_internal_address) mod 4 > 0) then
            error(4) <= '1'; -- Misaligned error, geback geback
            next_state <= idle;
          elsif( s_internal_address(31 downto 16) = x"0000" ) then
                next_state <= idle;
                instr_out <= instr_mem(to_integer(unsigned(addr_instr(31 downto 0)))/4); --Block RAM access
          else
                --s_internal_address <= std_logic_vector(unsigned(addr_instr)/2);
                next_state <= loading; --Loading instructions from elsewhere
          end if;

      -- Loading states
      when loading =>
        s_debugging_out <= "000100";
        if(s_internal_address(31 downto 16) = x"0000" ) then --BRAM
          next_state <= idle; --Instruction already goes out here, so no need to do anything,
          -- We do this to preserve the instr_out port, even though it's really not necesary.
       elsif(s_internal_address(31 downto 16) = x"9801") then --UART Registers
          next_state <= idle; -- By default go to idle
          UART_toggle <= '1';
          case s_internal_address(3 downto 0) is
            when X"0" => data_out <= zero_word & zero_word(31 downto 8) & uart_data_in;
            when X"1" => data_out <= zero_word & zero_word(31 downto 1) & uart_data_available;
            when X"2" => data_out <= zero_word & zero_word(31 downto 1) & uart_reset_read;
            when X"3" => data_out <= zero_word & zero_word(31 downto 8) & uart_data_out;
            when X"4" => data_out <= zero_word & zero_word(31 downto 1) & uart_ready;
            when X"5" => data_out <= zero_word & zero_word(31 downto 1) & uart_send;
            when others => NULL;
          end case;
        elsif(s_internal_address(31 downto 24) = x"98") then --LEDS Registers
          next_state <= idle;
        elsif(s_internal_address(31 downto 24) = x"97") then --m_clock Register
          next_state <= idle;
        elsif(s_internal_address(31 downto 28) = x"9") then --ROM
           next_state <= loading_rom;
        elsif(s_internal_address(31 downto 28) = x"8") then --RAM
          next_state <= loading_ram;
        else
          next_state <= idle;
        end if;

      -- Special load cases
      when loading_rom =>
        s_debugging_out <= "000101";
        ROM_en <= '1';
        if(ROM_counter > (2 * ROM_period)) then
          ROM_en <= '0';
          if(paused_state = fetching) then
              instr_out <= s_ROM_data_out(31 downto 0);
          else
              data_out <= s_ROM_data_out;
          end if;
          next_state <= idle;
        end if;

      when loading_ram =>
      s_debugging_out <= "000110";
          RAM_en <= '1';
          if(ROM_done = '1') then
            if(paused_state = fetching) then
                 instr_out <= s_RAM_data_out(31 downto 0);
            end if;
            next_state <= idle;
          end if;

      -- Stores and such
      when storing =>
        s_debugging_out <= "000111";
        next_state <= idle; -- By default go back
        if(addr_in(31 downto 16) = x"9801") then    --UART
          case addr_in(3 downto 0) is
            when X"0" => NULL; -- Nothing here really, why would you write to buffer in?
            when X"1" => NULL; -- Why?
            when X"2" => uart_reset_read <= '1';
                         next_state <= done_uart_rx;
            when X"3" => uart_data_out <= data_in(7 downto 0);
            when X"4" => NULL; -- No no no write
            when X"5" => uart_send <= '1'; -- Assuming if you are writing is to send something
                         next_state <= done_uart_tx; -- After writing to this register we reset it automatically
            when others => UART_data <= (others => '0');
          end case;
        elsif(addr_in(31 downto 24) = x"98") then --LEDS
          LED <= data_in(15 downto 0) OR data_in(31 downto 16);
          next_state <= idle;
        elsif(addr_in(31 downto 24) = x"97") then --m_clock
          next_state <= idle;
  --      elsif(addr_in(31 downto 28) = x"9") then --ROM
   --       next_state <= idle; --Can't write to ROM, I mean you could, but hwhy? Don't write to ROM
        elsif(addr_in(31 downto 28) = x"8") then --RAM
          next_state <= storing_ram;
        end if;

      -- Special stores section
      when storing_ram =>
        s_debugging_out <= "001000";
        w_en <= '1';
        if(RAM_done = '1') then
            w_en <= '0';
            next_state <= idle;
        end if;

      -- Special done states, to reset whatever needs to be reset
      when done_uart_tx =>
        uart_send <= '0';
        if(uart_ready = '0') then
            next_state <= done_uart_tx;
        else
            next_state <= idle;
        end if;
      when done_uart_rx =>
        uart_reset_read <= '0';
        next_state <= idle;
      when others =>
    end case;
  end if; 
end process;

-- Walk the page
PAGE_WALK_FSM: process(clk, rst, s_page_walk)
  variable level: Integer := 0;
  begin
  if(rst = '1') then

  elsif(rising_edge(clk)) then
    PAGE_WALK_next_state <= PAGE_WALK_current_state;
    case PAGE_WALK_current_state is 
      when idle =>
        if(s_page_walk = '1') then
          page_address_in <= "00000000" & SATP_PPN(43 downto 0) & addr_in(31 downto 22) & "00";--SATP PPN will give us the root page table location
          PAGE_WALK_next_state <= level_i_read;
          level := 0; --Start at level 0
        end if;
      when level_i_read =>
        if(level < 3) then
          page_walk_request_read <= '1';
          if(RAM_done = '1') then
            level := level + 1;
            PAGE_WALK_next_state <= level_i_decode;
          end if;
        else
          --Raise exception here
          --More levels than 3
          PAGE_WALK_next_state <= done;
        end if;
      when level_i_decode =>
          PAGE_WALK_next_state <= idle;
          if(s_RAM_data_out(0) = '0') then --Invalid PTE Raise the roof
            NULL;
          elsif(s_RAM_data_out(1) = '0' and s_RAM_data_out(7) = '1') then -- Not Valid and Dirty
            NULL;
          elsif(s_RAM_data_out(1) = '1' or s_RAM_data_out(3) = '1') then --So far this address is final
            -- Check if the PTE is in user mode and we are in user mode
            if(mode = "00" and s_RAM_data_out(4) = '1') then
                page_walk_next_state <= done;
                page_address_final <= s_RAM_data_out(63 downto 13) & s_internal_address(12 downto 0);
            -- If the PTE U bit is '0' and we are in Supervisor mode, it's still good
            -- We leave this separate in case other actions need to happen in S mode
            elsif(mode = "01" and s_RAM_data_out(4) = '0') then
                -- If PTE A is 0 or PTE D is 0 and we are storing, then we could raise an exception
                -- or set the bits to 1 ourselves
                if(s_RAM_data_out(6) = '0' or (paused_state = storing and s_RAM_data_out(7) = '0')) then
                    -- Raise exception
                end if;
                page_walk_next_state <= done;
                page_address_final <= s_RAM_data_out(63 downto 13) & s_internal_address(12 downto 0);
            else
                page_walk_next_state <= idle;
                --Raise exception when the user has no permission to access this PTE
            end if;
            page_walk_done <= '1';
          else -- We still have to dig deeper m8
            page_walk_next_state <= level_i_read;
            page_address_in <= "00000000" & SATP_PPN(43 downto 0) & s_internal_address(31 downto 22) & "00";
          end if;
      when done =>
        PAGE_WALK_next_state <= idle;
    end case;
  end if;
end process;

--busy <= '0' when curr_state = idle else '1';

-- Z high impedance
dq(0) <= 'Z' when io_tri_si = '1' else io_SI;
dq(1) <= 'Z';
dq(2) <= 'Z' when io_tri_wp = '1' else io_WP;
dq(3) <= 'Z';

qd(0) <= dq(0) when io_tri_si = '1' else 'Z';
qd(1) <= dq(1);
qd(2) <= dq(2) when io_tri_wp = '1' else 'Z';
qd(3) <= dq(3); 

gated_clock <= '0' when gated_clk = '1' else not(clk_25); 

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
              USRCCLKO => gated_clock,               -- 1-bit input: User CCLK input
              USRCCLKTS => '0',              -- 1-bit input: User CCLK 3-state enable input
              USRDONEO => '1',               -- 1-bit input: User DONE pin output control
              USRDONETS => '0'               -- 1-bit input: User DONE 3-state enable output
           );

-- ROM SPI Clock Generation
ROM_CLK: process(clk_25, rst) begin
    if(rst = '1') then 
        gated_clk <= '1';
    elsif(rising_edge(clk_25)) then
        if (io_cs = '0') then
            gated_clk <= '0';
        else
            gated_clk <= '1';
        end if;
    end if;
end process;



---- ROM State Machine
---- To enable rom set ROM_en high
---- Will wait for 600 cycles and give back a 64 bit word
ROM_FSM: process(clk,rst) 
  begin
  if(rst = '1') then
    io_rst <= '1';
    ROM_next_state <= idle;
  elsif(rising_edge(clk)) then
    if(ROM_curr_state /= idle) then
        ROM_counter <= ROM_counter + 1; -- Wait a good amount of time to let the device react
    end if;
    ROM_next_state <= ROM_curr_state;
    case ROM_curr_state is
      when idle =>
          ROM_next_state <= idle;
          ROM_counter <= 0;
          io_rst <= '0';
        if(ROM_en = '1') then
          ROM_done <= '0';
          --io_rst <= '0';
          ROM_address_in <= s_internal_address(23 downto 0); --24 Bits in
          ROM_next_state <= reading_lower;
        end if;
      when reading_lower =>
        ROM_next_state <= reading_lower;
        io_flash_en <= '1';
        if(ROM_counter > (2 * ROM_period)) then
          s_ROM_data_out <= io_flash_data_out;
          ROM_next_state <= done;
          --ROM_address_in <= std_logic_vector(unsigned(s_internal_address(23 downto 0)) + 4); --24 Bits in
        end if;
      when reading_higher =>
      when done =>
        ROM_done <= '1';
        if(ROM_en <= '0') then
            ROM_next_state <= idle;
        end if;
        io_rst <= '1';
        end case;
   end if;
end process;

-- RAM State Machine 
-- For reading from RAM, the ideal waiting time is of 230 ns
-- For writing into RAM, the ideal waiting time is of 270 ns
-- To make things easier we use 300 ns for both cases. 
RAM_FSM: process(clk, RAM_en, w_en) 
    variable RAM_counter :integer := 0;
    begin
    if(rising_edge(clk)) then
      if(RAM_curr_state /= idle) then
        RAM_counter := RAM_counter + 1;
      else
        RAM_counter := 0;
      end if;
    RAM_next_state <= RAM_curr_state;
    -- Forget about it
    -- If for whatever reason we take long than
    -- 1200 cycles, timeout and throw some error
    if(RAM_timeout_counter >= 1200) then
        RAM_next_state <= idle;
    else
      case RAM_curr_state is
      -- Idle state, read before write
      when idle =>
        RAM_ub <= '1';
        RAM_lb <= '1';
        if(RAM_en = '1') then
          RAM_next_state <= read_low;
        elsif(w_en = '1') then
          RAM_next_state <= write_low;
        end if;
      -- Load States
      when read_low =>
          if(RAM_counter > 30) then
              s_RAM_data_out(15 downto 0) <= RAM_data_out;
              RAM_next_state <= read_low_mid;
              RAM_counter := 0;
          end if;
      when read_low_mid =>
          if(RAM_counter > 30) then --Valid Data
              s_RAM_data_out(31 downto 16) <= RAM_data_out;
              RAM_next_state <= read_upper_mid;
              RAM_counter := 0;
          end if;
      when read_upper_mid =>
          if(RAM_counter > 30) then
              s_RAM_data_out(47 downto 32) <= RAM_data_out;
              RAM_next_state <= read_upper;
              RAM_counter := 0;
          end if;
      when read_upper =>
          if(RAM_counter > 30) then
              s_RAM_data_out(63 downto 48) <= RAM_data_out;
              RAM_next_state <= done;
              RAM_counter := 0;
          end if;
      -- Store States (LSB first)
      -- Bytes 1 and 2
      when write_low =>
        --Alignment 0001 means Byte-wise access
        if(alignment(0) = '1') then
            RAM_ub <= '0'; --Disable the upper byte from controller
        end if;
        if(RAM_counter > 30) then
            if(alignment(0) = '1') then 
                RAM_next_state <= done;
            else 
                RAM_next_state <= write_low_mid;
            end if;
            RAM_counter := 0;
        -- Alignment 0100 means Upper Word access
        elsif(alignment(2) = '1') then
            RAM_counter := 0;
            RAM_next_state <= write_upper_mid;
        end if;
      -- Byte 3 and 4
      when write_low_mid =>
        RAM_ub <= '1';
        RAM_lb <= '1';
        if(RAM_counter > 30) then --Valid Data
            -- Alignment 0010 is Lower Word access
            if(alignment(1) = '1') then
                RAM_next_state <= done;
            else
                RAM_next_state <= write_upper_mid;
                RAM_counter := 0;
            end if;
        end if;
      -- Bytes 5 and 6
      when write_upper_mid =>
        RAM_ub <= '1';
        RAM_lb <= '1';
        if(RAM_counter > 30) then
            RAM_next_state <= write_upper;
            RAM_counter := 0;
        end if;
      when write_upper =>
        RAM_ub <= '1';
        RAM_lb <= '1';
        if(RAM_counter > 30) then
              RAM_next_state <= done;
              RAM_counter := 0;
        end if;
      -- We are done here
      when others =>
        RAM_next_state <= idle;
      end case;
      end if;
    end if;
end process;

-- Latches the last obtained datas (dati, datum? datae?)
--LAST_OBTAINED_DATA: process(clk,rst, UART_toggle) begin
--  if(rst = '1') then
--    data_out <= (others => '0');
--  elsif(rising_edge(clk)) then
--    if(RAM_curr_state = done) then
--      data_out <= s_RAM_data_out;
--    elsif(ROM_curr_state = done) then
--      data_out <= s_ROM_data_out;
--    elsif(UART_toggle = '1') then
--      data_out(7 downto 0) <= UART_data(7 downto 0);
--      data_out(63 downto 8) <= (others => '0');
--    end if;
--  end if;
--end process;

-- Muxes for addresses and data
-- Intermitent address is internal RAM address, whenever we need to use the RAM
-- to access something else, we will make use of this intermitent_address_in signal 
Intermitent_Address_In <= addr_in when s_page_walk = '0' else page_address_in;
s_internal_data <= data_in; --For the moment this is right

-- Might change this to sequential logic if needed, I don't think it necessary
RAM_address_in <= std_logic_vector(unsigned(Intermitent_Address_In(26 downto 0)) + 0) when RAM_curr_state = idle or RAM_curr_state = read_low or RAM_curr_state = write_low else
                  std_logic_vector(unsigned(Intermitent_Address_In(26 downto 0)) + 2) when RAM_curr_state = read_low_mid or RAM_curr_state = write_low_mid else
                  std_logic_vector(unsigned(Intermitent_Address_In(26 downto 0)) + 4) when RAM_curr_state = read_upper_mid or RAM_curr_state = write_upper_mid else
                  std_logic_vector(unsigned(Intermitent_Address_In(26 downto 0)) + 6) when RAM_curr_state = read_upper or RAM_curr_state = write_upper
                  else (others => '0');

RAM_data_in <= s_internal_data(15 downto 0 ) when RAM_curr_state = idle or RAM_curr_state = write_low else
               s_internal_data(31 downto 16) when RAM_curr_state = write_low_mid else
               s_internal_data(47 downto 32) when RAM_curr_state = write_upper_mid else
               s_internal_data(63 downto 48) when RAM_curr_state = write_upper else
               (others => '0');

-- The CSR telling us where the page table start
SATP_mode(3 downto 0)  <= satp(63 downto 60);
SATP_PPN(43 downto 0)  <= satp(43 downto 0);

end Behavioral;
