library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM_Controller is
    Port ( clk_200,clk_100 : in STD_LOGIC;
           rst : in STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR(15 DOWNTO 0);
           data_out : out STD_LOGIC_VECTOR(15 DOWNTO 0);
           mask_lb, mask_ub: in std_logic;
           done: out STD_LOGIC;
           write, read: in STD_LOGIC;
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
end RAM_Controller;

architecture Behavioral of RAM_Controller is

component ram2ddrxadc
    port(
     clk_200MHz_i         : in    std_logic; -- 200 MHz system clock
     rst_i                : in    std_logic; -- active high system reset
     device_temp_i        : in    std_logic_vector(11 downto 0);
     
     -- RAM interface
     -- The RAM is accessing 2 bytes per access
     ram_a                : in    std_logic_vector(26 downto 0); -- input address
     ram_dq_i             : in    std_logic_vector(15 downto 0); -- input data
     ram_dq_o             : out   std_logic_vector(15 downto 0); -- output data
     ram_cen              : in    std_logic;                     -- chip enable
     ram_oen              : in    std_logic;                     -- output enable
     ram_wen              : in    std_logic;                     -- write enable
     ram_ub               : in    std_logic;                     -- upper byte
     ram_lb               : in    std_logic;                     -- lower byte
     
     -- DDR2 interface
     ddr2_addr            : out   std_logic_vector(12 downto 0);
     ddr2_ba              : out   std_logic_vector(2 downto 0);
     ddr2_ras_n           : out   std_logic;
     ddr2_cas_n           : out   std_logic;
     ddr2_we_n            : out   std_logic;
     ddr2_ck_p            : out   std_logic_vector(0 downto 0);
     ddr2_ck_n            : out   std_logic_vector(0 downto 0);
     ddr2_cke             : out   std_logic_vector(0 downto 0);
     ddr2_cs_n            : out   std_logic_vector(0 downto 0);
     ddr2_dm              : out   std_logic_vector(1 downto 0);
     ddr2_odt             : out   std_logic_vector(0 downto 0);
     ddr2_dq              : inout std_logic_vector(15 downto 0);
     ddr2_dqs_p           : inout std_logic_vector(1 downto 0);
     ddr2_dqs_n           : inout std_logic_vector(1 downto 0)
    );
    end component;


-- Physical RAM Pin Signals
signal ram_cen, ram_oen, ram_wen, ram_ub, ram_lb: std_logic;
signal ram_dq_o, ram_dq_i: std_logic_vector (15 downto 0);

type memory_states IS (IDLE_STATE, PREPARE_STATE, READ_STATE, WRITE_STATE, INTERMITENT_STATE);

-- Where current state and next_state are pretty self-forward, last state will check
signal current_state, next_state, last_state: memory_states := IDLE_STATE;


signal temp_data_write, temp_data_read: std_logic_vector(63 downto 0);
signal ram_a: std_logic_vector(26 downto 0);

-- Result
signal read_out: std_logic_vector(15 downto 0) := (others => '0');


-- Counters
signal hundred_nano_seconds_elapsed, wait_counter : integer range 0 to 150 := 0;
signal s_read : std_logic := '0'; 

signal writeOnce, readOnce : std_logic := '0';
begin

ram2ddr: ram2ddrxadc 
port map(
        clk_200MHz_i=>clk_200,
        rst_i=>rst,                
        device_temp_i=>"000000000000",        
        ram_a=>ram_a,     
        ram_dq_i=>ram_dq_o,             
        ram_dq_o=>ram_dq_i,             
        ram_cen=>ram_cen,              
        ram_oen=>ram_oen,               
        ram_wen=>ram_wen,              
        ram_ub=>ram_ub,               
        ram_lb=>ram_lb,               
       
        ddr2_addr=>ddr2_addr,            
        ddr2_ba=>ddr2_ba,              
        ddr2_ras_n=>ddr2_ras_n,           
        ddr2_cas_n=>ddr2_cas_n,           
        ddr2_we_n=>ddr2_we_n,            
        ddr2_ck_p=>ddr2_ck_p,            
        ddr2_ck_n=>ddr2_ck_n,            
        ddr2_cke=>ddr2_cke,             
        ddr2_cs_n=>ddr2_cs_n,            
        ddr2_dm=>ddr2_dm,              
        ddr2_odt=>ddr2_odt,             
        ddr2_dq=>ddr2_dq,              
        ddr2_dqs_p=>ddr2_dqs_p,           
        ddr2_dqs_n=>ddr2_dqs_n        
);

process(clk_100,rst) begin
    if(rst = '1') then
        current_state <= IDLE_STATE;
    elsif(rising_edge(clk_100)) then
        current_state <= next_state;
    end if;
end process;

process(current_state, rst, clk_100) begin
    
    if(rst = '1') then
        read_out <= (others => '0');
        readOnce <= '0';
        writeOnce <= '0';

    elsif(rising_edge(clk_100)) then
    next_state <= current_state;
    
    case current_state is
    -- State IDLE_STATE: Disable chip enable, write and read
    when IDLE_STATE =>
        ram_cen <= '1';
        ram_oen <= '1';
        ram_wen <= '1';
        if(read = '1') then
            s_read <= '1';
            next_state <= PREPARE_STATE; 
        elsif(write = '1') then 
            s_read <= '0';
            next_state <= PREPARE_STATE;
        end if;

    -- State PREPARE_STATE: Assert whatever needs to be asserted
    when PREPARE_STATE =>
        -- Reset the counters
        hundred_nano_seconds_elapsed <= 0;
        wait_counter <= 0;
        -- Read
        if(s_read = '1') then
            readOnce <= '1';
            ram_oen <= '0';
            ram_cen <= '0';
            ram_lb <= '0';
            ram_ub <= '0';
            ram_wen <= '1';
            next_state <= READ_STATE;
        -- Write
        else
            writeOnce <= '1';
            ram_oen <= '1';
            ram_cen <= '0';
            ram_lb <= '0';
            ram_ub <= '0';
            ram_wen <= '0';
            next_state <= WRITE_STATE;
        end if;

    -- State READ_STATE: Waits until the delta time indicated by the 
    -- data sheet has elapsed to finish reading
    when READ_STATE =>
        hundred_nano_seconds_elapsed <= hundred_nano_seconds_elapsed + 1;

        -- Wait till the necessary clock cycles elapsed while it's recording the data
        if(hundred_nano_seconds_elapsed > 22) then
           read_out <= ram_dq_i;
           next_state <= INTERMITENT_STATE;
        end if;

    -- Once we're at the write state, the upper and lower byte masks had been asserted
    -- to start writing, after which we are free to select the mask combination we need.
    when WRITE_STATE =>
        ram_lb <= mask_lb;
        ram_ub <= mask_ub;
        hundred_nano_seconds_elapsed <= hundred_nano_seconds_elapsed + 1;
        
        if(hundred_nano_seconds_elapsed > 27) then
            next_state <= INTERMITENT_STATE;
            -- Dummy read_out to signal we are done writing
            read_out <= (5 => '1', others => '0');
        end if;

    -- State INTERMITENT_STATE: The done flag will be raised to allow the MMU
    -- to continue onto the next byte
    when INTERMITENT_STATE =>
        read_out <= ram_dq_i;
        next_state <= IDLE_STATE;
    when others =>
        next_state <= IDLE_STATE;
    end case;
    end if;
end process;

ram_dq_o <= data_in;
ram_a <= contr_addr_in;
data_out <= read_out;
done <= '1' when current_state = INTERMITENT_STATE else '0';
end Behavioral;
