----------------------------------------------------------------------------------
-- Engineer: Longofono
--
-- Create Date: 02/10/2018 06:05:22 PM
-- Module Name: simple_core - Behavioral
-- Description: Incremental build of the simplified processor core
--
-- Additional Comments: 
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library config;
use work.config.all;

entity simple_core is
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
end simple_core;

architecture Behavioral of simple_core is

----------------------------------------------------------------------------------
-- Component instantiation
----------------------------------------------------------------------------------
component ALU is
    port(
        clk:        in std_logic;                       -- System clock
        rst:        in std_logic;                       -- Reset
        ctrl:       in instr_t;                         -- Operation
        rs1:        in doubleword;                      -- Source 1
        rs2:        in doubleword;                      -- Source 2
        shamt:      in std_logic_vector(4 downto 0);    -- shift amount
        rout:       out doubleword;                     -- Output Result
        error:      out std_logic;                      -- signal exception
        overflow:   out std_logic;                      -- signal overflow
        zero:       out std_logic                       -- signal zero result
    );
end component;

component decoder is
    Port(
        instr       : in std_logic_vector(31 downto 0);
        instr_code  : out instr_t;
        funct3      : out funct3_t;
        funct6      : out funct6_t;
        funct7      : out funct7_t;
        imm12       : out std_logic_vector(11 downto 0); -- I, B, and S Immediates
        imm20       : out std_logic_vector(19 downto 0); -- U and J Immediates
        opcode      : out opcode_t;
        rs1         : out reg_t;
        rs2         : out reg_t;
        rs3         : out reg_t;
        rd          : out reg_t;
        shamt       : out std_logic_vector(4 downto 0);
        csr         : out std_logic_vector(31 downto 20);
        sext_imm12  : out std_logic_vector(63 downto 0);
        sext_imm20  : out std_logic_vector(63 downto 0);
        reg_A       : out integer;
        reg_B       : out integer;
        reg_C       : out integer;
        reg_D       : out integer
    );
end component;

----------------------------------------------------------------------------------
-- Signals and constants
----------------------------------------------------------------------------------

-- Decoded instruction parts
signal s_save_instr: word;
signal s_output_data: word;
signal s_instr_code: instr_t;                       -- Exact instruction encoding
signal s_opcode: opcode_t;                          -- Opcode category abstraction
signal s_rs1: reg_t;                                -- Regfile read address
signal s_rs2: reg_t;                                -- Regfile read address
signal s_rs3: reg_t;                                -- Regfile read address
signal s_rd: reg_t;                                 -- Regfile write address
signal s_shamt: std_logic_vector(4 downto 0);       -- Shift amount, immediate shifts
signal s_imm12: std_logic_vector(11 downto 0);      -- Immediate value, 12 bit style
signal s_imm20: std_logic_vector(19 downto 0);      -- Immediate value, 20 bit style
signal s_csr_bits: std_logic_vector(11 downto 0);   -- CSR address for CSR instructions
signal s_functs: std_logic_vector(15 downto 0);     -- Holds concatenation of funct3, funct6, funct7
signal s_sext_12: doubleword;                       -- Sign extended immediate value
signal s_sext_20: doubleword;                       -- Sign extended immediate value
signal reg_A : integer;
signal reg_B : integer;
signal reg_C : integer;
signal reg_D : integer;

-- ALU connectors
signal s_ALU_input1: doubleword;
signal s_ALU_input2: doubleword;
signal s_ALU_result: doubleword;
signal s_ALU_Error: std_logic_vector(2 downto 0);

-- MMU connectors
signal mem_ret_data : doubleword;
signal s_MMU_input_addr: doubleword;
signal s_MMU_type: std_logic_vector(1 downto 0);
signal s_MMU_num_bytes: std_logic_vector(1 downto 0);       -- One-hot selection in bytes

-- High-level states of operation (distinct from  modes)
type state is ( INIT, FETCH, DECODE, DECODE_B, EXECUTE, FINISH_UP,
                TAKE_TRAP, TAKE_TRAP_SUPERVISOR, TAKE_TRAP_MACHINE, CHECK_INTERRUPT,
                MEM_A, MEM_B, MEM_C, LOAD_COMPLETE_UNSIGNED, LOAD_COMPLETE_SIGNED,
                CSR_CHECK_ACCESS, CSR_READ_CURRENT, CSR_OPERATOR, CSR_WRITE_BACK, CSR_WRITE_NEW,
                SUPERVISOR_RETURN, MACHINE_RETURN,
                DEBUG_DUMP, DEBUG_DUMP_REG, DEBUG_DUMP_CSR, DEBUG_GET_COMMAND, DEBUG_GET_ADDRESS,
                DEBUG_WRITE_DWORD,
                DEBUG_DO_COMMAND_STEP, DEBUG_DO_COMMAND_CONTINUE, DEBUG_DO_COMMAND_PHYS, DEBUG_DO_COMMAND_VIRT,
                DEBUG_READ_UART,  DEBUG_READ_UART_RDY,  DEBUG_READ_UART_DATA,  DEBUG_READ_UART_DONE,
                DEBUG_WRITE_UART, DEBUG_WRITE_UART_RDY, DEBUG_WRITE_UART_DATA, DEBUG_WRITE_UART_DONE,
                ATOMIC_DO_LOAD, ATOMIC_DO_OPERATION, ATOMIC_DO_STORE,
                ALU_RUN,   ALU_RUN_B, ALU_RUN_C, ALU_RUN_D, ALU_RUN_E, ALU_RUN_F, 
                ALU_RUN_G, ALU_RUN_H, ALU_RUN_I, ALU_RUN_J, ALU_RUN_K, ALU_RUN_L, WRITE_BACK );
signal curr_state, mem_ret_state, execute_ret_state, alu_ret_state : state;
signal s_debug_write_dwrod_ret, s_debug_get_addr_ret, s_debug_uart_ret : state;
signal init_counter : integer := 0;

-- Control status registers followed by scratch
signal csr          : regfile_arr;
signal pc           : doubleword;                       -- current program counter
signal s_PC_next    : doubleword;                       -- Next PC address
signal isa          : doubleword;
signal prv          : std_logic_vector(1 downto 0);
signal mstatus      : doubleword;
signal mepc         : doubleword;
signal mtval        : doubleword;
signal mscratch     : doubleword;
signal mtvec        : doubleword;
signal mcause       : doubleword;
signal minstret     : doubleword;
signal mie          : doubleword;
signal mip          : doubleword;
signal medeleg      : doubleword;
signal mideleg      : doubleword;
signal mcounteren   : doubleword;

signal scounteren   : doubleword;
signal sepc         : doubleword;
signal stval        : doubleword;
signal sscratch     : doubleword;
signal stvec        : doubleword;
signal satp         : doubleword;
signal scause       : doubleword;

signal cause        : doubleword;
signal epc          : doubleword;
signal tval         : doubleword;

signal load_reservation :   STD_LOGIC_VECTOR( 63 downto 0 );

-- Normal registers --
signal reg: regfile_arr;
signal reg_zero     : doubleword;
signal reg_ra       : doubleword;
signal reg_sp       : doubleword;
signal reg_gp       : doubleword;
signal reg_tp       : doubleword;
signal reg_t0       : doubleword;
signal reg_t1       : doubleword;
signal reg_t2       : doubleword;
signal reg_s0_fp    : doubleword;
signal reg_s1       : doubleword;
signal reg_a0       : doubleword;
signal reg_a1       : doubleword;
signal reg_a2       : doubleword;
signal reg_a3       : doubleword;
signal reg_a4       : doubleword;
signal reg_a5       : doubleword;
signal reg_a6       : doubleword;
signal reg_a7       : doubleword;
signal reg_s2       : doubleword;
signal reg_s3       : doubleword;
signal reg_s4       : doubleword;
signal reg_s5       : doubleword;
signal reg_s6       : doubleword;
signal reg_s7       : doubleword;
signal reg_s8       : doubleword;
signal reg_s9       : doubleword;
signal reg_s10      : doubleword;
signal reg_s11      : doubleword;
signal reg_t3       : doubleword;
signal reg_t4       : doubleword;
signal reg_t5       : doubleword;
signal reg_t6       : doubleword;

signal s_csr_should_write : std_logic;
signal s_csr_old_value : doubleword;
signal s_csr_mod_value : doubleword;

-- DEBUGGER --
signal s_debug_break        : std_logic;
signal s_debug_address      : doubleword;
signal s_debug_phys_address : doubleword;
signal s_debug_virt_address : doubleword;
signal s_debug_index        : integer;
signal s_debug_reg_index    : integer;
signal s_debug_dword_out    : doubleword;
signal s_debug_byte         : STD_LOGIC_VECTOR( 7 downto 0 );
signal s_debug_bytes        : byte_arr;
signal s_debug_access       : std_logic;

-- ATOMIC --
signal s_atomic_bytes     : STD_LOGIC_VECTOR( 1 downto 0 );
signal s_atomic_address   : doubleword;
signal s_atomic_output    : doubleword;

signal s_sext_12_shift_1  : STD_LOGIC_VECTOR( 63 downto 0 );
signal s_sext_20_shift_1  : STD_LOGIC_VECTOR( 63 downto 0 );
signal s_sext_20_shift_12 : STD_LOGIC_VECTOR( 63 downto 0 );

----------------------------------------------------------------------------------
-- Architecture Begin
----------------------------------------------------------------------------------
begin


----------------------------------------------------------------------------------
-- Component instantiations and mapping
----------------------------------------------------------------------------------

myDecode: decoder
    port map(
        instr => s_output_data,
        instr_code => s_instr_code,
        funct3 => s_functs(15 downto 13),
        funct6 => s_functs(12 downto 7),
        funct7 => s_functs(6 downto 0),
        imm12  => s_imm12,
        imm20  => s_imm20,
        opcode => s_opcode,
        rs1    => s_rs1,
        rs2    => s_rs2,
        rs3    => s_rs3,
        rd     => s_rd,
        shamt  => s_shamt,
        csr    => s_csr_bits,
        sext_imm12 => s_sext_12,
        sext_imm20 => s_sext_20,
        reg_A      => reg_A,
        reg_B      => reg_B,
        reg_C      => reg_C,
        reg_D      => reg_D
    );

myALU: ALU
    port map(
        clk => clk,
        rst => rst,
        ctrl => s_instr_code,
        rs1 => s_ALU_input1,
        rs2 => s_ALU_input2,
        shamt => s_shamt,
        rout => s_ALU_result,
        error => s_ALU_error(2),
        overflow => s_ALU_error(1),
        zero => s_ALU_error(0)
    );
    
s_sext_12_shift_1  <= s_sext_12(62 downto 0) & '0';
s_sext_20_shift_1  <= s_sext_20(62 downto 0) & '0';
s_sext_20_shift_12 <= s_sext_20(51 downto 0) & ALL_ZERO(11 downto 0);

----------------------------------------------------------------------------------
-- Main Logic
----------------------------------------------------------------------------------

process( clk )
    variable deleg              : STD_LOGIC_VECTOR( 63 downto 0 );
    variable cause_bit          : integer;
    
    --- CHECK_INTERRUPT ---
    variable pending_interrupts : STD_LOGIC_VECTOR( 63 downto 0 );
    variable m_enabled          : STD_LOGIC;
    variable s_enabled          : STD_LOGIC;
    variable enabled_interrupts : STD_LOGIC_VECTOR( 63 downto 0 );
    variable tmp_cause          : STD_LOGIC_VECTOR(  6 downto 0 );
    
    --- CSR ---
    variable csr_priv           : integer;
    variable csr_read_only      : STD_LOGIC_VECTOR(  1 downto 0 );
    variable csr_should_write   : std_logic;
    variable csr_type           : STD_LOGIC_VECTOR(  2 downto 0 );
    variable csr_error          : std_logic;
    variable csr_mask           : doubleword;
    
    -- ATOM --
    variable atomic_sext        : STD_LOGIC_VECTOR( 63 downto 0 );
    
begin if(rising_edge(clk)) then
    case curr_state is
        when INIT =>
            init_counter <= init_counter + 1;
            if( init_counter > INIT_WAIT ) then
                curr_state <= CHECK_INTERRUPT;
            end if;
            
            s_debug_break <= '0';
            pc          <= x"000000008FFFFFFC";
            s_PC_next   <= x"000000008FFFFFFC";
            s_debug_phys_address <= (others => '0');
            s_debug_virt_address <= (others => '0');
            load_reservation <= LOAD_RESERVATION_NONE;
            prv <= MACHINE_MODE;
            reg <= (others => (others => '0'));
            isa          <= x"8000000000141101"; -- isa supports 'aim' and 'us' modes
            
            -- the MMU drives MIP_MTIP and MIP_MSIP we start all other bits at 0
            mip(63 downto MIP_MTIP + 1) <= ALL_ZERO(63 downto MIP_MTIP + 1);
            mip(MIP_MTIP - 1 downto MIP_MSIP + 1) <= ALL_ZERO(MIP_MTIP - 1 downto MIP_MSIP + 1);
            mip(MIP_MSIP - 1 downto 0) <= ALL_ZERO(MIP_MSIP - 1 downto 0);
            
            mstatus      <= (others => '0');    mepc         <= (others => '0');    mtval        <= (others => '0');
            mscratch     <= (others => '0');    mtvec    <= x"000000008FFFFFFC";    mcause       <= (others => '0');
            minstret     <= (others => '0');    mie          <= (others => '0');
            medeleg      <= (others => '0');    mideleg      <= (others => '0');    mcounteren   <= (others => '0');
            
            scounteren   <= (others => '0');    sepc         <= (others => '0');    stval        <= (others => '0');
            sscratch     <= (others => '0');    stvec        <= (others => '0');    satp         <= (others => '0');
            scause       <= (others => '0');
            
            cause        <= (others => '0');    epc          <= (others => '0');    tval         <= (others => '0');
            
            s_debug_access <= '0';
            MMU_request  <= '0';
            
        when TAKE_TRAP =>
                --- cause should be in the generic cause register
                --- any bad addresses and values should be in tval
                
                -- if this was from an interrupt
                if( cause(CAUSE_INTERRUPT_BIT) = CAUSE_INTERRUPT ) then
                    -- use interrupt delegate
                    deleg := mideleg;
                else
                    -- use exception delegate
                    deleg := medeleg;
                end if;
                
                -- reservations are wiped out from traps
                load_reservation <= LOAD_RESERVATION_NONE;
                
                cause_bit := to_integer( unsigned ( cause( 62 downto 0 ) ) );
                
                -- if we are in supervisor or user mode
                if( ( prv <= SUPERVISOR_MODE ) and
                    ( cause_bit < 64 )         and
                    ( deleg(cause_bit) = '1' ) )
                then
                    curr_state <= TAKE_TRAP_SUPERVISOR;
                else
                    curr_state <= TAKE_TRAP_MACHINE;
                end if;
                
        when TAKE_TRAP_SUPERVISOR =>
                -- if we are in vectored mode and this is an interrupt
                if( ( stvec(TVEC_MODE_H downto TVEC_MODE_L) = TVEC_MODE_VECTORED ) and
                    ( cause(CAUSE_INTERRUPT_BIT) = CAUSE_INTERRUPT )  )
                then
                    -- jump to the base + the vector
                    --  vector is cause * 4 ( ignoring interrupt bit )
                    pc <= ( stvec( TVEC_BASE_H downto TVEC_BASE_L ) & ALL_ZERO( TVEC_BASE_L - 1 downto 0 ) )
                                 +
                                 ( cause( 61 downto 0 ) & "00" );
                else
                    -- Direct mode, go straight to the vector base
                    pc <= ( stvec( TVEC_BASE_H downto TVEC_BASE_L ) & ALL_ZERO( TVEC_BASE_L - 1 downto 0 ) );
                end if;
                
                -- transfer the trap values
                scause  <= cause;
                sepc    <= pc;
                stval   <= tval;
                
                -- save the Supervisor Interrupts Enabled bit
                mstatus(MSTATUS_SPIE) <= mstatus(MSTATUS_SIE);
                
                -- save the return privilage mode
                --  only 1 bit saved since only options are user and super
                mstatus(MSTATUS_SPP)  <= prv(0);
                
                -- disable supervisor interrupts
                mstatus(MSTATUS_SIE)  <= '0';
                
                -- set privilage mode to supervisor
                prv <= SUPERVISOR_MODE;
                
                -- return to normal instruction flow
                curr_state <= CHECK_INTERRUPT;
            
        when TAKE_TRAP_MACHINE =>
                -- if we are in vectored mode and this is an interrupt
                if( ( mtvec(TVEC_MODE_H downto TVEC_MODE_L) = TVEC_MODE_VECTORED ) and
                    ( cause(CAUSE_INTERRUPT_BIT) = CAUSE_INTERRUPT )  )
                then
                    -- jump to the base + the vector
                    --  vector is cause * 4 ( ignoring interrupt bit )
                    pc <= ( mtvec( TVEC_BASE_H downto TVEC_BASE_L ) & ALL_ZERO( TVEC_BASE_L - 1 downto 0 ) )
                          +
                          ( cause( 61 downto 0 ) & "00" );
                else
                    -- Direct mode, go straight to the vector base
                    pc <= ( mtvec( TVEC_BASE_H downto TVEC_BASE_L ) & ALL_ZERO( TVEC_BASE_L - 1 downto 0 ) );
                end if;
                
                -- transfer the trap values
                mcause  <= cause;
                mepc    <= pc;
                mtval   <= tval;
                
                -- save the Machine Interrupts Enabled bit
                mstatus(MSTATUS_MPIE) <= mstatus(MSTATUS_MIE);
                
                -- save the return privilage mode
                mstatus(MSTATUS_MPP_H downto MSTATUS_MPP_L)  <= prv;
                
                -- disable machine interrupts
                mstatus(MSTATUS_MIE)  <= '0';
                
                -- set privilage mode to machine mode
                prv <= MACHINE_MODE;
                
                -- return to normal instruction flow
                curr_state <= CHECK_INTERRUPT;
                
                
        when CHECK_INTERRUPT =>
                --- get interrupts that are pending and enabled
                pending_interrupts := mip and mie;
                
                --- are machine interrupts enabled
                if(   ( prv < MACHINE_MODE ) or
                    ( ( prv = MACHINE_MODE ) and ( mstatus(MSTATUS_MIE) = '1' ) ) )
                then
                    m_enabled := '1';
                else
                    m_enabled := '0';
                end if;
                
                --- get interrupts that machine mode should service
                if( m_enabled = '1' ) then
                    enabled_interrupts := pending_interrupts and not(mideleg);
                else
                    enabled_interrupts := ( others => '0');
                end if;
                
                --- are supervisor interrupts enabled
                if(   ( prv < SUPERVISOR_MODE )  or
                    ( ( prv = SUPERVISOR_MODE ) and ( mstatus(MSTATUS_SIE) = '1' ) ) )
                then
                    s_enabled := '1';
                else
                    s_enabled := '0';
                end if;
                
                --- if no machine interrupts can run see if supervisor ones can
                if( enabled_interrupts = ALL_ZERO ) then
                    if( s_enabled = '1' ) then
                        enabled_interrupts := ( pending_interrupts and mideleg );
                    end if;
                end if;
                
                if( enabled_interrupts /= ALL_ZERO ) then
                    if( enabled_interrupts(MIP_MEIP) = '1' ) then
                        tmp_cause := MIP_MEIP_CAUSE;
                    elsif( enabled_interrupts(MIP_SEIP) = '1' ) then
                        tmp_cause := MIP_SEIP_CAUSE;
                    elsif( enabled_interrupts(MIP_UEIP) = '1' ) then
                        tmp_cause := MIP_UEIP_CAUSE;
                    elsif( enabled_interrupts(MIP_MSIP) = '1' ) then
                        tmp_cause := MIP_MSIP_CAUSE;
                    elsif( enabled_interrupts(MIP_SSIP) = '1' ) then
                        tmp_cause := MIP_SSIP_CAUSE;
                    elsif( enabled_interrupts(MIP_USIP) = '1' ) then
                        tmp_cause := MIP_USIP_CAUSE;
                    elsif( enabled_interrupts(MIP_MTIP) = '1' ) then
                        tmp_cause := MIP_MTIP_CAUSE;
                    elsif( enabled_interrupts(MIP_STIP) = '1' ) then
                        tmp_cause := MIP_STIP_CAUSE;
                    elsif( enabled_interrupts(MIP_UTIP) = '1' ) then
                        tmp_cause := MIP_UTIP_CAUSE;
                    end if;
                    
                    curr_state <= TAKE_TRAP;
                    cause <= '1' & ALL_ZERO(55 downto 0) & tmp_cause;
                else
                    curr_state <= FETCH;
                end if;
        
        when FETCH =>
                s_PC_next           <= pc;
                s_MMU_input_addr    <= pc;
                s_MMU_type          <= MEM_FETCH;
                s_MMU_num_bytes     <= MEM_BYTES_4;
                mem_ret_state       <= DECODE;
                execute_ret_state   <= FINISH_UP;
                curr_state          <= MEM_A;


        when MEM_A =>
                -- wait for the MMU to not be busy
                if ( MMU_done = '0' ) then
                    if( s_debug_access = '1' ) then
                        MMU_mode  <= MACHINE_MODE;
                    else
                        MMU_mode  <= prv;
                    end if;
                    
                    -- If MPRV is high tell MMU our privilage is MPP
                    if( ( s_MMU_type /= MEM_FETCH ) and ( mstatus(MSTATUS_MPRV) = '1' ) ) then
                        MMU_mode <= mstatus(MSTATUS_MPP_H downto MSTATUS_MPP_L);
                    end if;
                    
                    -- make the request
                    MMU_request   <= '1';
                    curr_state  <= MEM_B;
                end if;
                
        
        when MEM_B =>
                if( MMU_done = '1' ) then
                    curr_state <= MEM_C;
                end if;
        
        when MEM_C =>
                MMU_request <= '0';
                curr_state <= mem_ret_state;
                
                -- If there was no error, then latch the returned data
                if( MMU_error = MEM_ERR_NONE ) then
                    if ( ( s_MMU_type = MEM_FETCH ) or ( s_MMU_type = MEM_LOAD ) ) then
                        mem_ret_data <= MMU_data_out;
                    end if;
                else
                    -- there was an error, take the trap
                    cause <= CAUSE_EXCEPTION_HIGH & MMU_error;
                    tval  <= s_MMU_input_addr;
                    curr_state <= TAKE_TRAP;
                end if;
                
                
        when DECODE =>
                -- put the fetched instruction on the decoder
                s_save_instr  <= mem_ret_data(31 downto 0);
                s_output_data <= mem_ret_data(31 downto 0);
                if( (MMU_debug_phys = s_debug_phys_address) or (MMU_debug_virt = s_debug_virt_address) 
                     or (s_debug_break = '1') or (DEBUG_halt = '1') )
                then
                    s_debug_access  <= '1';
                    curr_state      <= DEBUG_DUMP;
                else
                    curr_state <= DECODE_B;
                end if;
        
        when DECODE_B =>
                curr_state <= EXECUTE;
        
        when ALU_RUN   => curr_state <= ALU_RUN_B;
        
        when ALU_RUN_B   => curr_state <= ALU_RUN_C;
        
        when ALU_RUN_C   => curr_state <= ALU_RUN_D;
        
        when ALU_RUN_D   => curr_state <= ALU_RUN_E;
        
        when ALU_RUN_E   => curr_state <= ALU_RUN_L;
        
        --when ALU_RUN_F   => curr_state <= ALU_RUN_G;
        
        --when ALU_RUN_G   => curr_state <= ALU_RUN_H;
        
        --when ALU_RUN_H   => curr_state <= ALU_RUN_I;
        
        --when ALU_RUN_I   => curr_state <= ALU_RUN_J;
        
        --when ALU_RUN_J   => curr_state <= ALU_RUN_K;
        
        --when ALU_RUN_K   => curr_state <= ALU_RUN_L;
        
        when ALU_RUN_L => curr_state <= alu_ret_state;
        
        when WRITE_BACK =>
                reg(reg_D) <= s_ALU_result;
                curr_state <= execute_ret_state;
         
        
        when LOAD_COMPLETE_UNSIGNED =>
                if    (s_MMU_num_bytes = MEM_BYTES_1) then
                    reg(reg_D) <= ALL_ZERO(63 downto 8) & mem_ret_data(7 downto 0);
                elsif (s_MMU_num_bytes = MEM_BYTES_2) then
                    reg(reg_D) <= ALL_ZERO(63 downto 16) & mem_ret_data(15 downto 0);
                elsif (s_MMU_num_bytes = MEM_BYTES_4) then
                    reg(reg_D) <= ALL_ZERO(63 downto 32) & mem_ret_data(31 downto 0);
                else
                    reg(reg_D) <= mem_ret_data;
                end if;
                curr_state <= execute_ret_state;
                
        when LOAD_COMPLETE_SIGNED =>
                if    (s_MMU_num_bytes = MEM_BYTES_1) then
                    reg(reg_D)(63 downto  8) <= (others => mem_ret_data(7));
                    reg(reg_D)( 7 downto  0) <= mem_ret_data(7 downto  0);
                elsif (s_MMU_num_bytes = MEM_BYTES_2) then
                    reg(reg_D)(63 downto 16) <= (others => mem_ret_data(15));
                    reg(reg_D)(15 downto  0) <= mem_ret_data(15 downto  0);
                else
                    reg(reg_D)(63 downto 32) <= (others => mem_ret_data(31));
                    reg(reg_D)(31 downto  0) <= mem_ret_data(31 downto  0);
                end if;
                curr_state <= execute_ret_state;
                
        when EXECUTE =>  
                case s_opcode is
                    when ALUW_T =>   -- Case word, R-type ALU operations
                        -- REG signals
                        s_ALU_input1 <= reg(reg_A);
                        s_ALU_input2 <= reg(reg_B);

                        curr_state    <= ALU_RUN;
                        alu_ret_state <= WRITE_BACK;
                    
                    when LUI_T =>
                        s_ALU_input1  <= reg(reg_A);
                        s_ALU_input2  <= s_sext_20;
                        curr_state    <= ALU_RUN;
                        alu_ret_state <= WRITE_BACK;
                    
                    when ALU_T =>   -- Case regular, R-type ALU operations
                        -- REG signals
                        s_ALU_input1 <= reg(reg_A);
                        s_ALU_input2 <= reg(reg_B);

                        curr_state <= ALU_RUN;
                        alu_ret_state <= WRITE_BACK;

                    when ALUI_T =>  -- Case regular, I-type ALU operations
                        -- REG signals
                        s_ALU_input1 <= reg(reg_A);
                        s_ALU_input2 <= s_sext_12;

                        curr_state <= ALU_RUN;
                        alu_ret_state <= WRITE_BACK;
                    
                    when ALUIW_T =>  -- Case word, I-type ALU operations
                        -- REG signals
                        s_ALU_input1 <= reg(reg_A);
                        s_ALU_input2 <= s_sext_12;
                        curr_state    <= ALU_RUN;
                        alu_ret_state <= WRITE_BACK;
                    
                    when LOAD_T =>
                        curr_state          <= MEM_A;
                        s_MMU_type          <= MEM_LOAD;
                        s_MMU_input_addr    <= reg(reg_A) + s_sext_12;
                        
                        case s_instr_code is
                            when instr_LB =>
                                s_MMU_num_bytes     <= MEM_BYTES_1;
                                mem_ret_state       <= LOAD_COMPLETE_SIGNED;
                            when instr_LBU =>
                                s_MMU_num_bytes     <= MEM_BYTES_1;
                                mem_ret_state       <= LOAD_COMPLETE_UNSIGNED;
                            when instr_LH =>
                                s_MMU_num_bytes     <= MEM_BYTES_2;
                                mem_ret_state       <= LOAD_COMPLETE_SIGNED;
                            when instr_LHU =>
                                s_MMU_num_bytes     <= MEM_BYTES_2;
                                mem_ret_state       <= LOAD_COMPLETE_UNSIGNED;
                            when instr_LW =>
                                s_MMU_num_bytes     <= MEM_BYTES_4;
                                mem_ret_state       <= LOAD_COMPLETE_SIGNED;
                            when instr_LWU =>
                                s_MMU_num_bytes     <= MEM_BYTES_4;
                                mem_ret_state       <= LOAD_COMPLETE_UNSIGNED;
                            when others =>
                                s_MMU_num_bytes     <= MEM_BYTES_8;
                                mem_ret_state       <= LOAD_COMPLETE_UNSIGNED;
                        end case;
                        
                        
                    when STORE_T =>
                        s_MMU_input_addr <= reg(reg_A) + s_sext_12;
                        MMU_data_in      <= reg(reg_B);
                        curr_state          <= MEM_A;
                        s_MMU_type          <= MEM_STORE;
                        mem_ret_state       <= execute_ret_state;

                        case s_instr_code is
                            when instr_SB =>
                                s_MMU_num_bytes     <= MEM_BYTES_1;
                            when instr_SH =>
                                s_MMU_num_bytes     <= MEM_BYTES_2;
                            when instr_SW =>
                                s_MMU_num_bytes     <= MEM_BYTES_4;
                            when others =>  -- store doubleword
                                s_MMU_num_bytes     <= MEM_BYTES_8;
                        end case;
                        
                    when BRANCH_T =>
                        curr_state   <= execute_ret_state;
                        case s_instr_code is
                         when instr_BEQ =>
                             if( reg(reg_A) = reg(reg_B) ) then
                                s_PC_next <= pc + s_sext_12_shift_1;
                             end if;
                         when instr_BNE =>
                             if( reg(reg_A) /= reg(reg_B) ) then
                                 s_PC_next <= pc + s_sext_12_shift_1;
                             end if;
                         when instr_BLT =>
                             if( signed(reg(reg_A)) < signed(reg(reg_B)) ) then
                                 s_PC_next <= pc + s_sext_12_shift_1;
                             end if;
                         when instr_BGE =>
                             if( signed(reg(reg_A)) >= signed(reg(reg_B)) ) then
                                 s_PC_next <= pc + s_sext_12_shift_1;
                             end if;
                         when instr_BLTU =>
                             if( reg(reg_A) < reg(reg_B) ) then
                                 s_PC_next <= pc + s_sext_12_shift_1;
                             end if;
                         when others => --instr_BGEU
                             if( reg(reg_A) >= reg(reg_B) ) then
                                 s_PC_next <= pc + s_sext_12_shift_1;
                             end if;
                        end case;

                    when JAL_T =>
                        reg(reg_D)   <= pc + 4;
                        curr_state   <= execute_ret_state;
                        s_PC_next    <= pc + s_sext_20_shift_1;
                        
                    when JALR_T =>
                        curr_state   <= execute_ret_state;
                        reg(reg_D)   <= pc + 4;
                        s_PC_next    <= reg(reg_A) + s_sext_12;
                        s_PC_next(0) <= '0';
                    
                    when AUIPC_T =>
                        curr_state      <= execute_ret_state;
                        reg(reg_D)      <= pc + s_sext_20_shift_12;
                    
                    when CSR_T =>
                        case s_instr_code is
                            when instr_EBREAK   =>
                                s_debug_break  <= '1';
                                curr_state    <= execute_ret_state;
                            when instr_ECALL    =>
                                -- environment call
                                if( prv = USER_MODE ) then
                                    cause <= CAUSE_EXCEPTION_HIGH & CAUSE_ENV_CALL_U_MODE;
                                elsif( prv = SUPERVISOR_MODE ) then
                                    cause <= CAUSE_EXCEPTION_HIGH & CAUSE_ENV_CALL_S_MODE;
                                else
                                    cause <= CAUSE_EXCEPTION_HIGH & CAUSE_ENV_CALL_M_MODE;
                                end if;
                                curr_state <= TAKE_TRAP;
                            when instr_SRET     =>   curr_state   <= SUPERVISOR_RETURN;
                            when instr_MRET     =>   curr_state   <= MACHINE_RETURN;
                            when instr_WFI      =>
                                -- noop, no interrupts that drive the system to wait for.
                                curr_state    <= execute_ret_state;
                            when instr_SFENCEVM =>
                                -- noop, we don't have a tlb to flush.
                                -- supposed to throw an error in certain privilage modes, but does nothing.
                                curr_state    <= execute_ret_state;
                            when instr_CSRRW    =>   curr_state   <= CSR_CHECK_ACCESS;
                            when instr_CSRRS    =>   curr_state   <= CSR_CHECK_ACCESS;
                            when instr_CSRRC    =>   curr_state   <= CSR_CHECK_ACCESS;
                            when instr_CSRRWI   =>   curr_state   <= CSR_CHECK_ACCESS;
                            when instr_CSRRSI   =>   curr_state   <= CSR_CHECK_ACCESS;
                            when instr_CSRRCI   =>   curr_state   <= CSR_CHECK_ACCESS;
                            when others         =>
                                cause <= CAUSE_EXCEPTION_HIGH & CAUSE_ILLEGAL_INSTRUCTION;
                                tval  <= zero_word & s_output_data;
                                curr_state <= TAKE_TRAP;
                        end case;
                    
                    
                    when ATOM_T =>
                        if( ( s_instr_code = instr_SCD ) or ( s_instr_code = instr_SCW ) ) then
                            if ( ( load_reservation /= LOAD_RESERVATION_NONE ) and ( load_reservation = reg(reg_A) ) ) then
                                curr_state <= ATOMIC_DO_STORE;
                                s_atomic_output <= reg(reg_B);
                                reg(reg_D) <= x"0000000000000001";
                            else
                                curr_state <= execute_ret_state;
                                reg(reg_D) <= x"0000000000000000";
                            end if;
                            
                        else
                            curr_state <= ATOMIC_DO_LOAD;
                        end if;
                        
                        if(    ( s_instr_code = instr_LRD )      or ( s_instr_code = instr_SCD )
                            or ( s_instr_code = instr_AMOSWAPD ) or ( s_instr_code = instr_AMOADDD )
                            or ( s_instr_code = instr_AMOXORD )  or ( s_instr_code = instr_AMOANDD )
                            or ( s_instr_code = instr_AMOORD )   or ( s_instr_code = instr_AMOMIND )
                            or ( s_instr_code = instr_AMOMAXD )  or ( s_instr_code = instr_AMOMINUD )
                            or ( s_instr_code = instr_AMOMAXUD ) ) then
                            s_atomic_bytes <= MEM_BYTES_8;
                        else
                            s_atomic_bytes <= MEM_BYTES_4;
                        end if;
                        
                        s_atomic_address <= reg(reg_A);
                    
                    
                    when FENCE_T =>
                        -- noop, we have no out of order accesses or caches
                        curr_state    <= execute_ret_state;
                    
                    when others =>
                        -- trap on the unknown instruction
                        cause <= CAUSE_EXCEPTION_HIGH & CAUSE_ILLEGAL_INSTRUCTION;
                        tval  <= zero_word & s_output_data;
                        curr_state <= TAKE_TRAP;
                end case;
        
        when SUPERVISOR_RETURN =>
            if( ( prv = USER_MODE ) or ( (mstatus(MSTATUS_TSR) = '1') and (prv = SUPERVISOR_MODE) ) ) then
                cause <= CAUSE_EXCEPTION_HIGH & CAUSE_ILLEGAL_INSTRUCTION;
                tval  <= zero_word & s_output_data;
                curr_state <= TAKE_TRAP;
            elsif( sepc(1 downto 0) /= "00" ) then
                cause <= CAUSE_EXCEPTION_HIGH & CAUSE_INSTRUCTION_ADDRESS_MISALIGNED;
                tval  <= sepc;
                curr_state <= TAKE_TRAP;
            else
                s_PC_next <= sepc;
                pc        <= x"0000000000000005";
                load_reservation <= LOAD_RESERVATION_NONE;
                
                mstatus(MSTATUS_SIE)  <= mstatus(MSTATUS_SPIE);
                mstatus(MSTATUS_SPIE) <= '1';
                prv <= '0' & mstatus(MSTATUS_SPP);
                mstatus(MSTATUS_SPP) <= '0';
                
                curr_state    <= execute_ret_state;
            end if;
        
        when MACHINE_RETURN =>
            if( prv /= MACHINE_MODE ) then
                cause <= CAUSE_EXCEPTION_HIGH & CAUSE_ILLEGAL_INSTRUCTION;
                tval  <= zero_word & s_output_data;
                curr_state <= TAKE_TRAP;
            elsif( mepc(1 downto 0) /= "00" ) then
                cause <= CAUSE_EXCEPTION_HIGH & CAUSE_INSTRUCTION_ADDRESS_MISALIGNED;
                tval  <= mepc;
                curr_state <= TAKE_TRAP;
            else
                s_PC_next <= mepc;
                pc        <= x"0000000000000005";
                load_reservation <= LOAD_RESERVATION_NONE;
                
                mstatus(MSTATUS_MIE)  <= mstatus(MSTATUS_MPIE);
                mstatus(MSTATUS_MPIE) <= '1';
                prv <= mstatus(MSTATUS_MPP_H downto MSTATUS_MPP_L);
                mstatus(MSTATUS_MPP_H downto MSTATUS_MPP_L) <= USER_MODE;
                
                curr_state    <= execute_ret_state;
            end if;
            
        when ATOMIC_DO_LOAD =>
            if(  ((s_atomic_bytes = MEM_BYTES_8) and (s_atomic_address(2 downto 0) /= "000"))
              or ((s_atomic_bytes = MEM_BYTES_4) and (s_atomic_address(1 downto 0) /= "00"))  )
            then
                cause <= CAUSE_EXCEPTION_HIGH & CAUSE_STORE_AMO_ADDRESS_MISALIGNED;
                tval  <= s_atomic_address;
                curr_state <= TAKE_TRAP;
            else
                curr_state          <= MEM_A;
                s_MMU_type          <= MEM_LOAD;
                s_MMU_input_addr    <= s_atomic_address;
                s_MMU_num_bytes     <= s_atomic_bytes;
                mem_ret_state       <= ATOMIC_DO_OPERATION;
            end if;
        
        when ATOMIC_DO_OPERATION =>
            if( s_atomic_bytes = MEM_BYTES_4 ) then
                if( mem_ret_data(31) = '1' ) then
                    atomic_sext := ones_word & mem_ret_data( 31 downto 0 );
                else
                    atomic_sext := zero_word & mem_ret_data( 31 downto 0 );
                end if;
            else
                atomic_sext := mem_ret_data;
            end if;
            
            reg(reg_D) <= atomic_sext;
            
            if( ( s_instr_code = instr_LRD ) or ( s_instr_code = instr_LRW ) ) then
                load_reservation <= s_atomic_address;
                curr_state <= execute_ret_state;
            else
                curr_state <= ATOMIC_DO_STORE;
                if( (s_instr_code = instr_AMOSWAPD) or (s_instr_code = instr_AMOSWAPW) ) then
                    s_atomic_output <= reg(reg_B);
                elsif( (s_instr_code = instr_AMOADDD) or (s_instr_code = instr_AMOADDW)) then
                    s_atomic_output <= reg(reg_B) + atomic_sext;
                elsif( (s_instr_code = instr_AMOANDD) or (s_instr_code = instr_AMOANDW)) then
                    s_atomic_output <= reg(reg_B) and atomic_sext;
                elsif( (s_instr_code = instr_AMOORD) or (s_instr_code = instr_AMOORW)) then
                    s_atomic_output <= reg(reg_B) or atomic_sext;
                elsif( (s_instr_code = instr_AMOXORD) or (s_instr_code = instr_AMOXORW)) then
                    s_atomic_output <= reg(reg_B) xor atomic_sext;
                elsif( (s_instr_code = instr_AMOXORD) or (s_instr_code = instr_AMOXORW)) then
                    s_atomic_output <= reg(reg_B) xor atomic_sext;
                elsif( (s_instr_code = instr_AMOMAXD) or (s_instr_code = instr_AMOMAXW)) then
                    if( reg(reg_B) > atomic_sext ) then
                        s_atomic_output <= reg(reg_B);
                    else
                        s_atomic_output <= atomic_sext;
                    end if;
                elsif( (s_instr_code = instr_AMOMIND) or (s_instr_code = instr_AMOMINW)) then
                    if( reg(reg_B) < atomic_sext ) then
                        s_atomic_output <= reg(reg_B);
                    else
                        s_atomic_output <= atomic_sext;
                    end if;
                elsif( (s_instr_code = instr_AMOMAXUD) or (s_instr_code = instr_AMOMAXUW)) then
                    if( unsigned(reg(reg_B)) > unsigned(atomic_sext) ) then
                        s_atomic_output <= reg(reg_B);
                    else
                        s_atomic_output <= atomic_sext;
                    end if;
                elsif( (s_instr_code = instr_AMOMINUD) or (s_instr_code = instr_AMOMINUW)) then
                    if( unsigned(reg(reg_B)) < unsigned(atomic_sext) ) then
                        s_atomic_output <= reg(reg_B);
                    else
                        s_atomic_output <= atomic_sext;
                    end if;
                end if;
            end if;
        
        when ATOMIC_DO_STORE =>
            s_MMU_input_addr    <= s_atomic_address;
            MMU_data_in         <= s_atomic_output;
            s_MMU_type          <= MEM_STORE;
            s_MMU_num_bytes     <= s_atomic_bytes;
            mem_ret_state       <= execute_ret_state;
            curr_state          <= MEM_A;
        
        when CSR_CHECK_ACCESS =>
                csr_priv           := to_integer(unsigned(s_csr_bits(9 downto 8)));
                csr_read_only      := s_csr_bits(11 downto 10);
                csr_should_write   := '0';
                s_csr_should_write <= '0';
                csr_type           := s_functs(15 downto 13);
                -- RW instructions always write, RS and RC do not write if not changing
                --      which is if rs1 is zero register or bit field is all 0's
                if(    (csr_type = FUNC3_CSRRW) or (csr_type = FUNC3_CSRRWI) ) then
                    csr_should_write   := '1';
                    s_csr_should_write <= '1';
                elsif(    (csr_type = FUNC3_CSRRS ) or (csr_type = FUNC3_CSRRC)
                       or (csr_type = FUNC3_CSRRSI) or (csr_type = FUNC3_CSRRCI)) then
                    if( reg_A /= 0 ) then
                        csr_should_write   := '1';
                        s_csr_should_write <= '1';
                    end if;
                end if;
                
                -- if we want to write or just do not have access throw trap
                if(    ( (csr_should_write = '1') and (csr_read_only = CSR_RO) )
                    or ( to_integer(unsigned(prv)) < csr_priv )  )
                then
                    cause <= CAUSE_EXCEPTION_HIGH & CAUSE_ILLEGAL_INSTRUCTION;
                    tval  <= zero_word & s_output_data;
                    curr_state <= TAKE_TRAP;
                else
                    curr_state <= CSR_READ_CURRENT;
                end if;
        
        when CSR_READ_CURRENT =>
            csr_error := '0';
            case s_csr_bits is
                
                when CSR_ADDR_CYCLE | CSR_ADDR_INSTRET | CSR_ADDR_MCYCLE | CSR_ADDR_MINSTRET =>
                    if( (scounteren(0) = '0') and prv = USER_MODE ) then
                        -- Error if user mode not allowed to read
                        csr_error := '1';
                    elsif( (mcounteren(0) = '0') and prv = SUPERVISOR_MODE ) then
                        -- Error if supervisor mode not allowed to read
                        csr_error := '1';
                    else
                        s_csr_old_value <= minstret;
                    end if;
                    
                when CSR_ADDR_HPMCOUNTER3 | CSR_ADDR_HPMCOUNTER4 | CSR_ADDR_HPMCOUNTER5 | CSR_ADDR_HPMCOUNTER6 | CSR_ADDR_HPMCOUNTER7 |
                     CSR_ADDR_HPMCOUNTER8 | CSR_ADDR_HPMCOUNTER9 | CSR_ADDR_HPMCOUNTER10 | CSR_ADDR_HPMCOUNTER11 | CSR_ADDR_HPMCOUNTER12 |
                     CSR_ADDR_HPMCOUNTER13| CSR_ADDR_HPMCOUNTER14 | CSR_ADDR_HPMCOUNTER15 | CSR_ADDR_HPMCOUNTER16 | CSR_ADDR_HPMCOUNTER17 |
                     CSR_ADDR_HPMCOUNTER18| CSR_ADDR_HPMCOUNTER19 |  CSR_ADDR_HPMCOUNTER20 | CSR_ADDR_HPMCOUNTER21 | CSR_ADDR_HPMCOUNTER22 |
                     CSR_ADDR_HPMCOUNTER23| CSR_ADDR_HPMCOUNTER24 | CSR_ADDR_HPMCOUNTER25 | CSR_ADDR_HPMCOUNTER26 | CSR_ADDR_HPMCOUNTER27 |
                     CSR_ADDR_HPMCOUNTER28| CSR_ADDR_HPMCOUNTER29 | CSR_ADDR_HPMCOUNTER30 | CSR_ADDR_HPMCOUNTER31 =>
        
                    -- From notes: *counteren(x) needs to be checked, where x = 1 << integer(address(4 downto 0))
                    -- Since this is always a single bit, just convert directly to an integer and use it to index the register
                    -- Example: hpmcounter17 -> x = 1 << 17 = (0100000000000000000)_2.  Or, just use bit 17.
                    if( (scounteren( to_integer(unsigned(s_csr_bits(4 downto 0))) ) = '0') and (prv = USER_MODE) ) then
                       -- Error if user mode not allowed to read
                        csr_error := '1';
                    elsif( (mcounteren( to_integer(unsigned(s_csr_bits(4 downto 0))) ) = '0') and prv = SUPERVISOR_MODE ) then
                       -- Error if supervisor mode not allowed to read
                        csr_error := '1';
                    else
                        s_csr_old_value <= ALL_ZERO;
                    end if;
                when CSR_ADDR_SSTATUS =>
                    if( mstatus( 16 downto 15 ) = "11" or mstatus( 14 downto 13 ) = "11") then
                        s_csr_old_value <= mstatus and x"000000000005e122";
                    else
                        s_csr_old_value <= mstatus and x"800000000005e122";
                    end if;
                when CSR_ADDR_SIE =>
                    s_csr_old_value <= mie and mideleg;
                when CSR_ADDR_STVEC =>
                    s_csr_old_value <= stvec;
                when CSR_ADDR_SCOUNTEREN =>
                    s_csr_old_value <= scounteren;
                when CSR_ADDR_SSCRATCH =>
                    s_csr_old_value <= sscratch;
                when CSR_ADDR_SEPC =>
                    s_csr_old_value <= sepc;
                when CSR_ADDR_SCAUSE =>
                    s_csr_old_value <= scause;
                when CSR_ADDR_STVAL =>
                    s_csr_old_value <= stval;
                when CSR_ADDR_SIP =>
                    s_csr_old_value <= mip and mideleg;
                when CSR_ADDR_SATP =>
                    if( mstatus( 20 ) = '1' and not (prv = MACHINE_MODE)) then
                        -- Error if not in machine mode
                        csr_error := '1';
                    else
                        s_csr_old_value <= satp;
                    end if;
                when CSR_ADDR_MVENDORID =>
                    s_csr_old_value <= zero_word & zero_word;
                when CSR_ADDR_MARCHID =>
                    s_csr_old_value <= zero_word & zero_word;
                when CSR_ADDR_MIMPID =>
                    s_csr_old_value <= zero_word & zero_word;
                when CSR_ADDR_MHARTID =>
                    s_csr_old_value <= zero_word & zero_word;
                when CSR_ADDR_MSTATUS =>
                    s_csr_old_value <= mstatus;
                when CSR_ADDR_MISA =>
                    s_csr_old_value <= isa;
                when CSR_ADDR_MEDELEG =>
                    s_csr_old_value <= medeleg;
                when CSR_ADDR_MIDELEG =>
                    s_csr_old_value <= mideleg;
                when CSR_ADDR_MIE =>
                    s_csr_old_value <= mie;
                when CSR_ADDR_MTVEC =>
                    s_csr_old_value <= mtvec;
                when CSR_ADDR_MCOUNTEREN =>
                    s_csr_old_value <= mcounteren;
                when CSR_ADDR_MSCRATCH =>
                    s_csr_old_value <= mscratch;
                when CSR_ADDR_MEPC =>
                    s_csr_old_value <= mepc;
                when CSR_ADDR_MCAUSE =>
                    s_csr_old_value <= mcause;
                when CSR_ADDR_MTVAL =>
                    s_csr_old_value <= mtval;
                when CSR_ADDR_MIP =>
                    s_csr_old_value <= mip;
                when CSR_ADDR_MHPMCOUNTER3  | CSR_ADDR_MHPMCOUNTER4  | CSR_ADDR_MHPMCOUNTER5  | CSR_ADDR_MHPMCOUNTER6  |
                     CSR_ADDR_MHPMCOUNTER7  | CSR_ADDR_MHPMCOUNTER8  | CSR_ADDR_MHPMCOUNTER9  | CSR_ADDR_MHPMCOUNTER10 |
                     CSR_ADDR_MHPMCOUNTER11 | CSR_ADDR_MHPMCOUNTER12 | CSR_ADDR_MHPMCOUNTER13 | CSR_ADDR_MHPMCOUNTER14 |
                     CSR_ADDR_MHPMCOUNTER15 | CSR_ADDR_MHPMCOUNTER16 | CSR_ADDR_MHPMCOUNTER17 | CSR_ADDR_MHPMCOUNTER18 |
                     CSR_ADDR_MHPMCOUNTER19 | CSR_ADDR_MHPMCOUNTER20 | CSR_ADDR_MHPMCOUNTER21 | CSR_ADDR_MHPMCOUNTER22 |
                     CSR_ADDR_MHPMCOUNTER23 | CSR_ADDR_MHPMCOUNTER24 | CSR_ADDR_MHPMCOUNTER25 | CSR_ADDR_MHPMCOUNTER26 |
                     CSR_ADDR_MHPMCOUNTER27 | CSR_ADDR_MHPMCOUNTER28 | CSR_ADDR_MHPMCOUNTER29 | CSR_ADDR_MHPMCOUNTER30 |
                     CSR_ADDR_MHPMCOUNTER31     =>
                        s_csr_old_value <= ALL_ZERO;
                
                when CSR_ADDR_MHPMEVENT3  | CSR_ADDR_MHPMEVENT4  | CSR_ADDR_MHPMEVENT5  | CSR_ADDR_MHPMEVENT6  |
                     CSR_ADDR_MHPMEVENT7  | CSR_ADDR_MHPMEVENT8  | CSR_ADDR_MHPMEVENT9  | CSR_ADDR_MHPMEVENT10 |
                     CSR_ADDR_MHPMEVENT11 | CSR_ADDR_MHPMEVENT12 | CSR_ADDR_MHPMEVENT13 | CSR_ADDR_MHPMEVENT14 |
                     CSR_ADDR_MHPMEVENT15 | CSR_ADDR_MHPMEVENT16 | CSR_ADDR_MHPMEVENT17 | CSR_ADDR_MHPMEVENT18 |
                     CSR_ADDR_MHPMEVENT19 | CSR_ADDR_MHPMEVENT20 | CSR_ADDR_MHPMEVENT21 | CSR_ADDR_MHPMEVENT22 |
                     CSR_ADDR_MHPMEVENT23 | CSR_ADDR_MHPMEVENT24 | CSR_ADDR_MHPMEVENT25 | CSR_ADDR_MHPMEVENT26 |
                     CSR_ADDR_MHPMEVENT27 | CSR_ADDR_MHPMEVENT28 | CSR_ADDR_MHPMEVENT29 | CSR_ADDR_MHPMEVENT30 |
                     CSR_ADDR_MHPMEVENT31       =>
                        s_csr_old_value <= ALL_ZERO;
                
                when others                     =>
                    -- All others not implemented, set trap
                    csr_error := '1';
            end case;
            
            if( csr_error = '1' ) then
                cause <= CAUSE_EXCEPTION_HIGH & CAUSE_ILLEGAL_INSTRUCTION;
                tval  <= zero_word & s_output_data;
                curr_state <= TAKE_TRAP;
            else
                curr_state <= CSR_OPERATOR;
            end if;
        
        
        when CSR_OPERATOR =>
                csr_type  := s_functs(15 downto 13);
                if( s_csr_should_write = '1' ) then
                    if( csr_type(2) = '0' ) then
                        csr_mask := reg(reg_A);
                    else
                        csr_mask := ALL_ZERO(63 downto 5) & s_rs1;
                    end if;
                    
                    if(    ('0' & csr_type(1 downto 0)) = FUNC3_CSRRW ) then
                        s_csr_mod_value <= csr_mask;
                    elsif( ('0' & csr_type(1 downto 0)) = FUNC3_CSRRC ) then
                        s_csr_mod_value <= s_csr_old_value and not csr_mask;
                    else
                        s_csr_mod_value <= s_csr_old_value or csr_mask;
                    end if;
                    
                    curr_state <= CSR_WRITE_NEW;
                else
                    curr_state <= CSR_WRITE_BACK;
                end if;
        
        
        when CSR_WRITE_NEW =>
            curr_state <= CSR_WRITE_BACK;
            case s_csr_bits is
                when CSR_ADDR_MCYCLE | CSR_ADDR_MINSTRET =>
                    minstret <= s_csr_mod_value;
                when CSR_ADDR_SSTATUS =>
                        mstatus(18) <= s_csr_mod_value(18); -- Update Smode portion of MSTATUS
                        mstatus(16 downto 15) <= s_csr_mod_value(16 downto 15);
                        mstatus(14 downto 13) <= s_csr_mod_value(14 downto 13);
                        mstatus(8) <= s_csr_mod_value(8);
                        mstatus(5) <= s_csr_mod_value(5);
                        mstatus(1) <= s_csr_mod_value(1);
                when CSR_ADDR_SIE =>
                        mie(12) <= s_csr_mod_value(12) and mideleg(12);
                        mie(9) <= s_csr_mod_value(9) and mideleg(9);
                        mie(7) <= s_csr_mod_value(7) and mideleg(7);
                        mie(5) <= s_csr_mod_value(5) and mideleg(5);
                        mie(3) <= s_csr_mod_value(3) and mideleg(3);
                        mie(1) <= s_csr_mod_value(1) and mideleg(1);
                when CSR_ADDR_STVEC =>
                        stvec(63 downto 2) <= s_csr_mod_value(63 downto 2);
                when CSR_ADDR_SCOUNTEREN =>
                        scounteren <= s_csr_mod_value;
                when CSR_ADDR_SSCRATCH =>
                        sscratch <= s_csr_mod_value;
                when CSR_ADDR_SEPC =>
                        sepc <= s_csr_mod_value;
                when CSR_ADDR_SCAUSE =>
                        scause <= s_csr_mod_value;
                when CSR_ADDR_STVAL =>
                        stval <= s_csr_mod_value;
                when CSR_ADDR_SIP =>
                        mip(1) <= s_csr_mod_value(1) and mideleg(1);
                when CSR_ADDR_SATP =>
                        if( (s_csr_mod_value(63 downto 60) = "0000") or
                            (s_csr_mod_value(63 downto 60) = "1000") or
                            (s_csr_mod_value(63 downto 60) = "1001") ) then
                                satp(63 downto 60) <= s_csr_mod_value(63 downto 60);
                                satp(43 downto 0) <= s_csr_mod_value(43 downto 0);
                        end if;
                when CSR_ADDR_MSTATUS =>
                        -- update status
                        if(s_csr_mod_value(14 downto 13) = "00") then -- if not dirty
                            mstatus(22 downto 17) <= s_csr_mod_value(22 downto 17);
                            mstatus(14 downto 11) <= s_csr_mod_value(14 downto 11);
                            mstatus( 8 ) <= s_csr_mod_value(8);
                            mstatus( 7 ) <= s_csr_mod_value(7);
                            mstatus( 5 ) <= s_csr_mod_value(5);
                            mstatus( 3 ) <= s_csr_mod_value(3);
                            mstatus( 1 ) <= s_csr_mod_value(1);
                            mstatus( 63 ) <= '0';
                        else
                            mstatus(22 downto 17) <= s_csr_mod_value(22 downto 17);
                            mstatus(14 downto 11) <= s_csr_mod_value(14 downto 11);
                            mstatus( 8 ) <= s_csr_mod_value(8);
                            mstatus( 7 ) <= s_csr_mod_value(7);
                            mstatus( 5 ) <= s_csr_mod_value(5);
                            mstatus( 3 ) <= s_csr_mod_value(3);
                            mstatus( 1 ) <= s_csr_mod_value(1);
                            mstatus( 63 ) <= '1';
                        end if;
                when CSR_ADDR_MISA =>
                when CSR_ADDR_MEDELEG =>
                        medeleg <= s_csr_mod_value;
                when CSR_ADDR_MIDELEG =>
                        mideleg(12) <= s_csr_mod_value(12);
                        mideleg(9) <= s_csr_mod_value(9);
                        mideleg(5) <= s_csr_mod_value(5);
                        mideleg(1) <= s_csr_mod_value(1);
                when CSR_ADDR_MIE =>
                        mie(12) <= s_csr_mod_value(12);
                        mie(9) <= s_csr_mod_value(9);
                        mie(7) <= s_csr_mod_value(7);
                        mie(5) <= s_csr_mod_value(5);
                        mie(3) <= s_csr_mod_value(3);
                        mie(1) <= s_csr_mod_value(1);
                when CSR_ADDR_MTVEC =>
                        mtvec(63 downto 2) <= s_csr_mod_value(63 downto 2);
                        mtvec(0) <= s_csr_mod_value(0);
                when CSR_ADDR_MCOUNTEREN =>
                        mcounteren <= s_csr_mod_value;
                when CSR_ADDR_MSCRATCH =>
                        mscratch <= s_csr_mod_value;
                when CSR_ADDR_MEPC =>
                        mepc <= s_csr_mod_value;
                when CSR_ADDR_MCAUSE =>
                        mcause <= s_csr_mod_value;
                when CSR_ADDR_MTVAL =>
                        mtval <= s_csr_mod_value;
                when CSR_ADDR_MIP =>
                    mip(5) <= s_csr_mod_value(5);
                    mip(1) <= s_csr_mod_value(1);
                when others =>
                    -- Do nothing, if were going to trap would have already happened
            end case;
            
        
        when CSR_WRITE_BACK =>
                reg(reg_D) <= s_csr_old_value;
                curr_state <= execute_ret_state;
        
        
        when FINISH_UP =>
                minstret   <= minstret + 1;
                reg(0)     <= ALL_ZERO;
                if( pc = s_PC_next ) then
                    pc <= pc + 4;
                else
                     pc <= s_PC_next;
                end if;
                
                if( prv = "10" ) then
                    prv <= USER_MODE;
                end if;
                
                curr_state <= CHECK_INTERRUPT;
        
        
        when DEBUG_DUMP =>
                s_debug_write_dwrod_ret <= DEBUG_DUMP_REG;
                curr_state              <= DEBUG_WRITE_DWORD;
                s_debug_dword_out       <= x"005A0A5ADEADBEEF"; -- debugger magic sequence
                s_debug_index <= 0;
                s_debug_reg_index <= 0;
        
        when DEBUG_DUMP_REG =>
                if( s_debug_reg_index = 32 ) then
                    s_debug_reg_index <= 0;
                    curr_state        <= DEBUG_DUMP_CSR;
                else
                    s_debug_write_dwrod_ret <= DEBUG_DUMP_REG;
                    curr_state              <= DEBUG_WRITE_DWORD;
                    s_debug_index <= 0;
                    s_debug_dword_out       <= reg(s_debug_reg_index);
                    s_debug_reg_index           <= s_debug_reg_index + 1;
                end if;
        
        when DEBUG_DUMP_CSR =>
                if( s_debug_reg_index = 27 ) then
                    s_debug_reg_index <= 0;
                    s_debug_byte      <= DEBUG_COMMAND_NONE;
                    curr_state        <= DEBUG_GET_COMMAND;
                else
                    s_debug_write_dwrod_ret <= DEBUG_DUMP_CSR;
                    curr_state              <= DEBUG_WRITE_DWORD;
                    s_debug_index <= 0;
                    s_debug_dword_out       <= csr(s_debug_reg_index);
                    s_debug_reg_index           <= s_debug_reg_index + 1;
                end if;
        
        when DEBUG_GET_COMMAND =>
                s_debug_index     <= 0;
                s_debug_reg_index <= 0;
                curr_state  <= DEBUG_READ_UART;
                if( s_debug_byte = DEBUG_COMMAND_STEP) then
                    curr_state  <= DEBUG_DO_COMMAND_STEP;
                elsif( s_debug_byte = DEBUG_COMMAND_CONT ) then
                    curr_state  <= DEBUG_DO_COMMAND_CONTINUE;
                elsif( s_debug_byte = DEBUG_COMMAND_PHYS ) then
                    s_debug_uart_ret  <= DEBUG_GET_ADDRESS;
                    s_debug_get_addr_ret  <= DEBUG_DO_COMMAND_PHYS;
                elsif( s_debug_byte = DEBUG_COMMAND_VIRT ) then
                    s_debug_uart_ret  <= DEBUG_GET_ADDRESS;
                    s_debug_get_addr_ret  <= DEBUG_DO_COMMAND_VIRT;
                else
                    s_debug_uart_ret <= DEBUG_GET_COMMAND;
                end if;
        
        when DEBUG_GET_ADDRESS =>
                -- addresses sent in big endian
                s_debug_bytes(s_debug_index) <= s_debug_byte;
                s_debug_index <= s_debug_index + 1;
                
                if( s_debug_index = 7 ) then
                    s_debug_index <= 0;
                    s_debug_address <= s_debug_bytes(0) & s_debug_bytes(1) & s_debug_bytes(2) & s_debug_bytes(3)
                                     & s_debug_bytes(4) & s_debug_bytes(5) & s_debug_bytes(6) & s_debug_byte;
                    curr_state  <= s_debug_get_addr_ret;
                else
                    s_debug_uart_ret  <= DEBUG_GET_ADDRESS;
                    curr_state  <= DEBUG_READ_UART;
                end if;
                
        
        when DEBUG_WRITE_DWORD =>
                if( s_debug_index = 0) then
                    s_debug_byte <= s_debug_dword_out(63 downto 56);
                    s_debug_bytes(1) <= s_debug_dword_out(55 downto 48);
                    s_debug_bytes(2) <= s_debug_dword_out(47 downto 40);
                    s_debug_bytes(3) <= s_debug_dword_out(39 downto 32);
                    s_debug_bytes(4) <= s_debug_dword_out(31 downto 24);
                    s_debug_bytes(5) <= s_debug_dword_out(23 downto 16);
                    s_debug_bytes(6) <= s_debug_dword_out(15 downto 8);
                    s_debug_bytes(7) <= s_debug_dword_out(7  downto 0);
                else
                    s_debug_byte <= s_debug_bytes(s_debug_index);
                end if;
                s_debug_index <= s_debug_index + 1;
                
                curr_state        <= DEBUG_WRITE_UART;
                s_debug_uart_ret  <= DEBUG_WRITE_DWORD;
                
                if( s_debug_index = 7 ) then
                    s_debug_uart_ret <= s_debug_write_dwrod_ret;
                    s_debug_index <= 0;
                end if;
        
        when DEBUG_DO_COMMAND_STEP =>
                s_debug_break  <= '1';
                s_debug_access <= '0';
                curr_state     <= EXECUTE;
        
        when DEBUG_DO_COMMAND_CONTINUE =>
                s_debug_break  <= '0';
                s_debug_access <= '0';
                curr_state     <= EXECUTE;
        
        when DEBUG_DO_COMMAND_PHYS =>
                s_debug_phys_address <= s_debug_address;
                curr_state           <= DEBUG_DUMP;
        
        when DEBUG_DO_COMMAND_VIRT =>
                s_debug_virt_address <= s_debug_address;
                curr_state           <= DEBUG_DUMP;
        
        when DEBUG_READ_UART =>
                mem_ret_data <= ALL_ZERO;
                curr_state   <= DEBUG_READ_UART_RDY;
        
        when DEBUG_READ_UART_RDY =>
                if( mem_ret_data(0) = '1' ) then
                    curr_state   <= DEBUG_READ_UART_DATA;
                else
                    curr_state          <= MEM_A;
                    s_MMU_type          <= MEM_LOAD;
                    s_MMU_input_addr    <= UART_RX_READY;
                    s_MMU_num_bytes     <= MEM_BYTES_1;
                    mem_ret_state       <= DEBUG_READ_UART_RDY;
                end if;
        
        when DEBUG_READ_UART_DATA =>
                curr_state          <= MEM_A;
                s_MMU_type          <= MEM_LOAD;
                s_MMU_input_addr    <= UART_RX_DATA;
                s_MMU_num_bytes     <= MEM_BYTES_1;
                mem_ret_state       <= DEBUG_READ_UART_DONE;
        
        when DEBUG_READ_UART_DONE =>
                s_debug_byte <= mem_ret_data(7 downto 0);
                s_MMU_input_addr    <= UART_RX_RESET;
                MMU_data_in         <= ALL_ZERO(63 downto 1) & '1';
                s_MMU_type          <= MEM_STORE;
                s_MMU_num_bytes     <= MEM_BYTES_1;
                mem_ret_state       <= s_debug_uart_ret;
                curr_state          <= MEM_A;
        
        when DEBUG_WRITE_UART =>
                mem_ret_data <= ALL_ZERO;
                curr_state   <= DEBUG_WRITE_UART_RDY;
        
        when DEBUG_WRITE_UART_RDY =>
                if( mem_ret_data(0) = '1' ) then
                    curr_state   <= DEBUG_WRITE_UART_DATA;
                else
                    curr_state          <= MEM_A;
                    s_MMU_type          <= MEM_LOAD;
                    s_MMU_input_addr    <= UART_TX_READY;
                    s_MMU_num_bytes     <= MEM_BYTES_1;
                    mem_ret_state       <= DEBUG_WRITE_UART_RDY;
                end if;
        
        when DEBUG_WRITE_UART_DATA =>
                s_MMU_input_addr    <= UART_TX_DATA;
                MMU_data_in         <= ALL_ZERO(63 downto 8) & s_debug_byte;
                s_MMU_type          <= MEM_STORE;
                s_MMU_num_bytes     <= MEM_BYTES_1;
                mem_ret_state       <= DEBUG_WRITE_UART_DONE;
                curr_state          <= MEM_A;
        
        when DEBUG_WRITE_UART_DONE =>
                s_MMU_input_addr    <= UART_TX_SEND;
                MMU_data_in         <= ALL_ZERO(63 downto 1) & '1';
                s_MMU_type          <= MEM_STORE;
                s_MMU_num_bytes     <= MEM_BYTES_1;
                mem_ret_state       <= s_debug_uart_ret;
                curr_state          <= MEM_A;
        
        when others =>
            -- trap for unknown state
            cause <= CAUSE_EXCEPTION_HIGH & CAUSE_ILLEGAL_INSTRUCTION;
            tval  <= x"DEADBEEFDEADBEEF";
            curr_state <= TAKE_TRAP;
    end case;
    
    if('1' = rst) then
        curr_state   <= INIT;
        init_counter <= 0;
    end if;
end if; end process;

-- Map outbound signals
status <= MMU_done;
MMU_addr_in <= s_MMU_input_addr;       -- 64-bits address for load/store
MMU_satp <= satp;                      -- Signals address translation privilege
MMU_type <= s_MMU_type;                -- High to toggle store
MMU_num_bytes <= s_MMU_num_bytes;      -- alignment in bytes

SUM <= mstatus(MSTATUS_SUM);
MXR <= mstatus(MSTATUS_MXR);
mip(MIP_MTIP) <= MTIP;
mip(MIP_MSIP) <= MSIP;


csr(CSR_ISA) <= isa;
csr(CSR_PRV) <= ALL_ZERO(63 downto 2) & prv;
csr(CSR_MSTATUS) <= mstatus;
csr(CSR_MEPC) <= mepc;
csr(CSR_MTVAL) <= mtval;
csr(CSR_MSCRATCH) <= mscratch;
csr(CSR_MTVEC) <= mtvec;
csr(CSR_MCAUSE) <= mcause;
csr(CSR_MINSTRET) <= minstret;
csr(CSR_MIE) <= mie;
csr(CSR_MIP) <= mip;
csr(CSR_MEDELEG) <= medeleg;
csr(CSR_MIDELEG) <= mideleg;
csr(CSR_MCOUNTEREN) <= mcounteren;

csr(CSR_SCOUNTEREN) <= scounteren;
csr(CSR_SEPC) <= sepc;
csr(CSR_STVAL) <= stval;
csr(CSR_SSCRATCH) <= sscratch;
csr(CSR_STVEC) <= stvec;
csr(CSR_SATP) <= satp;
csr(CSR_SCAUSE) <= scause;

csr(CSR_LOAD_RES) <= load_reservation;
csr(CSR_DBG_PHYS) <= s_debug_phys_address;
csr(CSR_DBG_VIRT) <= s_debug_virt_address;
csr(CSR_MMU_PHYS) <= MMU_debug_phys;
csr(CSR_MMU_VIRT) <= MMU_debug_virt;
csr(CSR_INSTR)    <= zero_word & s_save_instr;

-- Normal registers --
reg_zero        <= reg(0);
reg_ra          <= reg(1);
reg_sp          <= reg(2);
reg_gp          <= reg(3);
reg_tp          <= reg(4);
reg_t0          <= reg(5);
reg_t1          <= reg(6);
reg_t2          <= reg(7);
reg_s0_fp       <= reg(8);
reg_s1          <= reg(9);
reg_a0          <= reg(10);
reg_a1          <= reg(11);
reg_a2          <= reg(12);
reg_a3          <= reg(13);
reg_a4          <= reg(14);
reg_a5          <= reg(15);
reg_a6          <= reg(16);
reg_a7          <= reg(17);
reg_s2          <= reg(18);
reg_s3          <= reg(19);
reg_s4          <= reg(20);
reg_s5          <= reg(21);
reg_s6          <= reg(22);
reg_s7          <= reg(23);
reg_s8          <= reg(24);
reg_s9          <= reg(25);
reg_s10         <= reg(26);
reg_s11         <= reg(27);
reg_t3          <= reg(28);
reg_t4          <= reg(29);
reg_t5          <= reg(30);
reg_t6          <= reg(31);

end Behavioral;
