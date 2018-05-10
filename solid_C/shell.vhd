library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.config.all;

entity shell is
    Port(
        clk_100: in std_logic;
        clk_25: in std_logic;
        rst: in std_logic;
        status: out std_logic;
        DEBUG_halt: in std_logic;

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
end shell;

architecture Behavioral of shell is

--------------------------------------------------------------------------------
-- Components Forward Declarations
--------------------------------------------------------------------------------

component simple_core is
    Port(
        status: out std_logic;                          -- LED blinkenlites
        clk: in std_logic;                              -- System clock (100 MHz)
        rst: in std_logic;                              -- Tied to switch SW0

        DEBUG_halt: in std_logic;
        
        SUM:            out std_logic;
        MXR:            out std_logic;
        MTIP:           in  std_logic;
        MSIP:           in  std_logic;

        MMU_addr_in:    out doubleword;                    -- 64-bits address for load/store/fetch
        MMU_data_in:    out doubleword;                    -- 64-bits data for store
        MMU_satp:       out doubleword;                    -- Signals address translation privilege
        MMU_mode:       out std_logic_vector(1 downto 0);  -- Current operating mode (Machine, Supervisor, Etc)
        MMU_type:       out std_logic_vector(1 downto 0);  -- High to toggle store / low means load
        MMU_done:       in  std_logic;                     -- High when busy
        MMU_request:    out std_logic;                     -- request has been made
        MMU_num_bytes:  out std_logic_vector(1 downto 0);  -- alignment in bytes
        MMU_data_out:   in  doubleword;                    -- 64-Bits data out for load
        MMU_error:      in  std_logic_vector(6 downto 0);  -- Error bits from MMU
        MMU_debug_phys: in  doubleword;
        MMU_debug_virt: in  doubleword
    );
end component;

component MMU is
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
end component;

--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------
signal s_MMU_addr_in:    doubleword;                    -- 64-bits address for load/store/fetch
signal s_MMU_data_in:    doubleword;                    -- 64-bits data for store
signal s_MMU_satp:       doubleword;                    -- Signals address translation privilege
signal s_MMU_mode:       std_logic_vector(1 downto 0);  -- Current operating mode (Machine, Supervisor, Etc)
signal s_MMU_type:       std_logic_vector(1 downto 0);  -- High to toggle store / low means load
signal s_MMU_done:       std_logic;                     -- High when busy
signal s_MMU_request:    std_logic;                     -- request has been made
signal s_MMU_num_bytes:  std_logic_vector(1 downto 0);  -- alignment in bytes
signal s_MMU_data_out:   doubleword;                    -- 64-Bits data out for load
signal s_MMU_error:      std_logic_vector(6 downto 0);  -- Error bits from MMU
signal s_MMU_debug_phys: doubleword;
signal s_MMU_debug_virt: doubleword;

signal s_SUM:            std_logic;
signal s_MXR:            std_logic;
signal s_MTIP:           std_logic;
signal s_MSIP:           std_logic;

signal s_LED:            std_logic_vector(15 downto 0);

signal s_MEM_request: std_logic;
signal s_MEM_status:  std_logic;

begin

LED( 11 downto 0 ) <= s_LED( 11 downto 0 );
LED(12) <= s_MMU_request;
LED(13) <= s_MMU_done;
LED(14) <= s_MEM_request;
LED(15) <= s_MEM_status;

MEM_request   <= s_MEM_request;
s_MEM_status  <= MEM_status;

--------------------------------------------------------------------------------
-- Instantiations
--------------------------------------------------------------------------------
bestCore: simple_core
    port map(
        status  => status,
        clk     => clk_25,
        rst     => rst,

        DEBUG_halt => DEBUG_halt,
        
        SUM     => s_SUM,
        MXR     => s_MXR,
        MTIP    => s_MTIP,
        MSIP    => s_MSIP,

        MMU_addr_in     => s_MMU_addr_in,
        MMU_data_in     => s_MMU_data_in,
        MMU_satp        => s_MMU_satp,
        MMU_mode        => s_MMU_mode,
        MMU_type        => s_MMU_type,
        MMU_done        => s_MMU_done,
        MMU_request     => s_MMU_request,
        MMU_num_bytes   => s_MMU_num_bytes,
        MMU_data_out    => s_MMU_data_out,
        MMU_error       => s_MMU_error,
        MMU_debug_phys  => s_MMU_debug_phys,
        MMU_debug_virt  => s_MMU_debug_virt
    );
    
memmy: MMU
    port map(
        clk_100     => clk_100,
        clk         => clk_25,
        rst         => rst,
        addr_in     => s_MMU_addr_in,
        data_in     => s_MMU_data_in,
        satp        => s_MMU_satp,
        mode        => s_MMU_mode,
        r_type      => s_MMU_type,
        done        => s_MMU_done,
        request     => s_MMU_request,
        num_bytes   => s_MMU_num_bytes,
        data_out    => s_MMU_data_out,
        error       => s_MMU_error,
        debug_phys  => s_MMU_debug_phys,
        debug_virt  => s_MMU_debug_virt,
        
        SUM     => s_SUM,
        MXR     => s_MXR,
        MTIP    => s_MTIP,
        MSIP    => s_MSIP,
        
        -- LEDS out
        LED     => s_LED,

        -- UART out
        UART_TXD => UART_TXD,
        UART_RXD => UART_RXD,
        
        -- ROM / RAM lines --
        MEM_addr        => MEM_addr,
        MEM_data_in     => MEM_data_in,
        MEM_data_out    => MEM_data_out,
        MEM_ram         => MEM_ram,
        MEM_write       => MEM_write,
        MEM_request     => s_MEM_request,
        MEM_status      => s_MEM_status,
        MEM_err         => MEM_err
    );

--------------------------------------------------------------------------------
-- Do Work
--------------------------------------------------------------------------------



end Behavioral;
