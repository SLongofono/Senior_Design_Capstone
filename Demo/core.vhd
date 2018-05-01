----------------------------------------------------------------------------------
-- Engineer: Longofono Modified by Avalos
--
-- Create Date: 02/10/2018 06:05:22 PM
-- Module Name: simpler_core - Behavioral
-- Description: Even Simpler version of the ALU pipeline for HW testing
--
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library config;
use work.config.all;

library unisim;
use unisim.VCOMPONENTS.ALL;

entity simpler_core is
  Port(
    status: out std_logic; -- LED blinkenlites
    CLK: in std_logic;  -- Tied to switch V10
    RST: in std_logic;   -- Tied to switch J15
    LED: out std_logic_vector(15 downto 0);
    PC_Switch: in std_logic;
    ALU_Switch: in std_logic;
    ROM_Switch: in std_logic_vector(1 downto 0);
    UART_Switch: in std_logic;
    -- UART Serial I/O
    UART_RXD: in std_logic;
    UART_TXD: out std_logic;

    

    -- DDR2 signals
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
    
    --ROM signals
    dq: inout STD_LOGIC_VECTOR(3 downto 0);
    cs_n: out STD_LOGIC
    );
end simpler_core;

architecture Behavioral of simpler_core is

-- Component instantiation
component ALU is
    port(
        clk:        in std_logic;                       -- System clock
        rst:        in std_logic;                       -- Reset
        halt:       in std_logic;                       -- Do nothing
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

component fence is
    Port(
        clk:            in std_logic;   -- System clock
        rst:            in std_logic;   -- System reset
        halt:           in std_logic;   -- Do nothing when high
        ready_input:    in std_logic;   -- Control has data to be written back
        ready_output:   in std_logic;   -- MMU is ready to accept data
        output_OK:      out std_logic;  -- Write data and address are valid
        input_OK:       out std_logic;  -- Read data and address recorded
        input_data:     in doubleword;  -- Data from previous stage
        input_address:  in doubleword;  -- MMU Destination for input data
        output_data:    out doubleword; -- Data to be written to MMU
        output_address: out doubleword  -- MMU destination for output data
);
end component;

component decode is
    Port(
        instr       : in std_logic_vector(63 downto 0);
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
        csr         : out std_logic_vector(31 downto 20)
    );
end component;

component regfile is
    Port(
        clk:            in std_logic;
        rst:            in std_logic;
        read_addr_1:    in std_logic_vector(4 downto 0);    -- Register source read_data_1
        read_addr_2:    in std_logic_vector(4 downto 0);    -- Register source read_data_2
        write_addr:     in std_logic_vector(4 downto 0);    -- Write dest write_data
        write_data:     in doubleword;                      -- Data to be written
        halt:           in std_logic;                       -- Control, do nothing on high
        write_en:       in std_logic;                       -- write_data is valid
        read_data_1:    out doubleword;                     -- Data from read_addr_1
        read_data_2:    out doubleword;                     -- Data from read_addr_2
        write_error:    out std_logic;                      -- Writing to constant, HW exception
        debug_out:      out regfile_arr                     -- Copy of regfile contents for debugger
    );
end component;


component mux is
    Port(
        sel:        in std_logic;   -- Select from zero, one ports
        zero_port:  in doubleword;  -- Data in, zero select port
        one_port:   in doubleword;  -- Data in, one select port
        out_port:   out doubleword  -- Output data
    );
end component;

component sext is
    Port(
        imm12: in std_logic_vector(11 downto 0);
        imm20: in std_logic_vector(19 downto 0);
        output_imm12: out std_logic_vector(63 downto 0);
        output_imm20: out std_logic_vector(63 downto 0)
    );
end component;

component MMU is
    Port(
        clk: in std_logic; -- 100 Mhz Clock
        rst: in std_logic;
        addr_in: in doubleword;
        data_in: in doubleword;
        satp: in doubleword;
    --    mode: in std_logic_vector(1 downto 0); -- Machine mode, user mode, hypervisor mode or machine mode
        store: in std_logic;
        load: in std_logic;
        busy: out std_logic;
        mode: in std_logic_vector(1 downto 0);  -- Current mode (Machine, Supervisor, Etc)
        ready_instr: in std_logic;
        addr_instr: in doubleword;
        alignment: in std_logic_vector(3 downto 0);
        data_out: out doubleword;
        instr_out: out word;
        error: out std_logic_vector(5 downto 0);
        LED: out std_logic_vector(15 downto 0);

     --   debug_MEM: out doubleword; -- Dummy register that will be written to
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
        -- UART
        UART_RXD: in std_logic;
        UART_TXD: out std_logic;
        
        -- Debug Signals
        
        -- ROM
        sck: out STD_LOGIC;
        dq: inout std_logic_vector(3 downto 0);
        cs_n: out STD_LOGIC);
end component;

component Debug_Controller is
    Port (clk,rst: in STD_LOGIC;
          halt:  out STD_LOGIC;
          REGGIE: in regfile_arr;
          PC_IN: in doubleword;
          uart_rxd  :  in  STD_LOGIC;
          uart_txd  : out  STD_LOGIC);
end component;


-- Signals and constants

-- Feedback signals
signal s_rst: std_logic;                            -- internal reset
signal s_halts: std_logic_vector(2 downto 0);       -- IM, REG, ALU halt signals
signal s_ALU_op: ctrl_t;                            -- ALU operation control
signal s_request_IM_in: std_logic;                  -- Signal pending write to IM
signal s_request_IM_inack: std_logic;               -- Acknowledge above write handled
signal s_request_IM_out: std_logic;                 -- Signal ready for instruction
signal s_request_IM_outack: std_logic;              -- Acknowledge instruction data is fresh
signal s_wb_select: std_logic;                      -- Select from ALU result or MMU data to Regfile write
signal s_PC_next: doubleword;                       -- Next PC address
signal s_PC_curr: doubleword;                       -- Preserves current PC for jumps
signal s_MMU_store: std_logic;                      -- Signal MMU to store
signal s_MMU_load: std_logic;                       -- Signal MMU to load
signal s_MMU_busy: std_logic;                       -- MMU is loading, storing, or fetching
signal s_ATU_busy: std_logic;                       -- Atomic unit is doing its thing
signal s_ATU_stage:std_logic;                       -- After resuming, need to know what stage of atomic instruction we are in
signal s_ALU_source_select: std_logic_vector(1 downto 0);              -- Switch in immediate values

-- Decoded instruction parts
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

-- ALU connectors
signal s_ALU_input2: doubleword;
signal s_ALU_result: doubleword;
signal s_ALU_Error: std_logic_vector(2 downto 0);

-- Instruction memory connectors
signal s_IM_input_addr: doubleword;
signal s_IM_input_data: doubleword;
signal s_IM_output_addr: doubleword;
signal s_IM_output_data: doubleword;

-- Register file connectors
signal s_REG_raddr1: reg_t;
signal s_REG_raddr2: reg_t;
signal s_REG_rdata1: doubleword;
signal s_REG_rdata2: doubleword;
signal s_REG_wdata: doubleword;
signal s_REG_waddr: reg_t;
signal s_REG_write: std_logic;
signal s_REG_error: std_logic;
signal s_REG_debug: regfile_arr;

-- MMU connectors
signal s_MMU_input_addr: doubleword := (others => '0');
signal s_MMU_input_data: doubleword;
signal s_MMU_alignment: std_logic_vector(3 downto 0);       -- One-hot selection in bytes
signal s_MMU_output_data: doubleword;
signal s_MMU_output_instr: doubleword;
signal s_MMU_error: std_logic_vector(5 downto 0);
signal s_MMU_instr_out: word;
signal s_MMU_fetch: std_logic;
signal s_MMU_LED: std_logic_vector(15 downto 0);
signal s_MMU_satp:  doubleword := (others => '0');
signal s_MMU_mode:  std_logic_vector(1 downto 0); -- Machine mode, user mode, hypervisor mode or machine mode
signal s_MMU_UART_RXD, s_MMU_UART_TXD: std_logic;
signal d_clk: std_logic := '0';

-- Jump and branch connectors
signal s_wb_to_jal: doubleword;                             -- Connects output of mem/alu wb mux to input of jump mux
signal s_jump_select: std_logic;                            -- Select from output of mem/alu mux or jump address data
signal s_jump_wdata: doubleword;                            -- Data representing the jump return address or AUIPC result
--signal s_jump_target: doubleword;                           -- Address of the jump targer
--signal s_jump_sext: doubleword;                             -- Intermediate helper variable for clarity's sake

-- Others
signal s_sext_12: doubleword;                               -- Sign extended immediate value
signal s_sext_20: doubleword;                               -- Sign extended immediate value
signal privilege_mode: std_logic_vector(1 downto 0) := MACHINE_MODE;


signal counter_sc: integer := 0;

signal debugger_step: std_logic;

-- Debug
signal fkuck_vivado_so_much: std_logic_vector(5 downto 0);
signal s_internal_address_out: doubleword;

-- Load/Store connectors

-- Changing these signals to variables to avoid losing time
--signal s_load_base: doubleword;                             -- Base address from regfile
--signal s_load_offset: doubleword;                           -- Offset from sext(imm12 value)
--signal s_store_base: doubleword;                            -- Base address from regfile
--signal s_store_offset: doubleword;                          -- Offset from sext(imm12 value)
signal s_load_type : std_logic_vector(7 downto 0);          -- Record type so we can properly extend later
signal s_load_dest : reg_t;                                 -- Record rd so we can access it later
signal s_load_wb_data: doubleword;                          -- Extended data to be written back to regfile

-- High-level states of operation (distinct from  modes)
type state is (fetching, fetching_wait, regs, alus,load_store, mem, wb, done);
signal curr_state, next_state: state := fetching;

signal stupid_fucking_vivado: std_logic_vector(5 downto 0);

signal s_DEBUG_UART_TXD, s_DEBUG_UART_RXD: std_logic;

-- Control status registers followed by scratch
type CSR_t is array (0 to 64) of doubleword;
signal CSR: CSR_t;

signal shifterCounter: integer := 0; 

-- Exception flags
-- From privilege specification: MSB 1 => asynchronous, MSB 0 => synchronous
-- Remaining bits are binary-encoded exception code
signal exceptions: std_logic_vector(4 downto 0) := (others => '0');

-- in order to act appropriately on CSr exceptions, drive and track them separately
signal csr_exceptions: std_logic := '0';

signal exception_offending_instr : instr_t := (others => '0');

signal s_decode_instruction: doubleword;




-- If in waiting state, reason determines actions on exit
signal waiting_reason: std_logic_vector(2 downto 0);
signal gated_clock: std_logic;

begin

-- Component instantiations and mapping
myDecode: decode
    port map(
        instr => s_decode_instruction,
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
        csr    => s_csr_bits
    );


myALU: ALU
    port map(
        clk => clk,
        rst => s_rst,
        halt => s_halts(0),
        ctrl => s_instr_code,
        rs1 => s_REG_rdata1,
        rs2 => s_ALU_input2,
        shamt => s_shamt,
        rout => s_ALU_result,
        error => s_ALU_error(2),
        overflow => s_ALU_error(1),
        zero => s_ALU_error(0)
    );

--WBMux: mux
--    port map(
--        sel => s_WB_select,
--        zero_port => s_ALU_result,
--        one_port => s_load_wb_data,
--        out_port => s_wb_to_jal
--);

--JumpReturn: mux
--    port map(
--        sel => s_jump_select,
--        zero_port => s_wb_to_jal,
--        one_port => s_jump_wdata,
--        out_port => s_REG_wdata
--);

--ALUMux: mux
--    port map(
--        sel => s_ALU_source_select,
--        zero_port => s_REG_rdata2,
--        one_port => s_sext_12,
--        out_port => s_ALU_input2
--    );

-- Muxes
s_REG_wdata <= s_ALU_result when s_WB_select = '0' and s_jump_select = '0' else s_load_wb_data when s_WB_select = '1' and s_jump_select = '0' else s_jump_wdata when s_WB_select = '0' and s_jump_select = '1';
--s_wb_to_jal  <= s_ALU_result when s_WB_select = '0' else s_load_wb_data; 
--s_REG_wdata  <= s_wb_to_jal when s_jump_select = '0' else s_jump_wdata;
s_ALU_input2 <= s_REG_rdata2 when s_ALU_source_select = "00" else s_sext_12 when s_ALU_source_select = "01" else s_sext_20;

myMMU: MMU port map
(
        clk => CLK, 
        rst => s_rst,
        addr_in => s_MMU_input_addr,
        data_in => s_MMU_input_data,
        satp => s_MMU_satp,
        mode => s_MMU_mode,
        store => s_MMU_store,
        load => s_MMU_load,
        busy => s_MMU_busy,
        ready_instr => s_MMU_fetch,
        addr_instr => s_PC_curr,
        alignment => s_MMU_alignment,
        data_out => s_MMU_output_data,
        instr_out => s_MMU_instr_out,
        error => s_MMU_error,
        UART_RXD => UART_RXD,
        UART_TXD => s_MMU_UART_txd,
        LED => s_MMU_LED,
        ddr2_addr => ddr2_addr,
        ddr2_ba => ddr2_ba,
        ddr2_ras_n => ddr2_ras_n,
        ddr2_cas_n => ddr2_cas_n,
        ddr2_we_n => ddr2_we_n,
        ddr2_ck_p => ddr2_ck_p,
        ddr2_ck_n => ddr2_ck_n,
        ddr2_cke => ddr2_cke,
        ddr2_cs_n => ddr2_cs_n,
        ddr2_dm => ddr2_dm,
        ddr2_odt => ddr2_odt,
        ddr2_dq => ddr2_dq,
        ddr2_dqs_p => ddr2_dqs_p,
        ddr2_dqs_n => ddr2_dqs_n,
        -- Debug Signals

        sck => gated_clock, 
        cs_n => cs_n,
        dq => dq
        );


myDebug: Debug_Controller 
    port map(
    clk => clk,
    rst => rst,
    reggie => s_REG_debug,
    PC_IN => s_PC_curr,
    halt => d_clk,
    uart_rxd => s_DEBUG_UART_RXD,
    uart_txd => s_DEBUG_UART_TXD
    );

myREG: regfile
    port map(
        clk => clk,
        rst => s_rst,
        read_addr_1 => s_REG_raddr1,
        read_addr_2 => s_REG_raddr2,
        write_addr => s_REG_waddr,
        write_data => s_REG_wdata,
        halt => s_halts(1),
        write_en => s_REG_write,
        read_data_1 => s_REG_rdata1,
        read_data_2 => s_REG_rdata2,
        write_error => s_REG_error,
        debug_out => s_REG_debug
    );

mySext: sext
    port map(
        imm12 => s_imm12,
        imm20 => s_imm20,
        output_imm12 => s_sext_12,
        output_imm20 => s_sext_20
);

advance_state: process(clk,rst, next_state) begin
    if(rst = '1') then
        curr_state <= fetching;
        if(PC_Switch = '0') then
            s_PC_curr <= (others => '0');
        else
            s_PC_curr <= x"0000000090000000";
        end if;
    elsif(rising_edge(clk)) then
        curr_state <= next_state;
        if(curr_state = done) then
              s_PC_curr <= s_PC_next;
        end if;
    end if;
end process;


process(clk, rst, curr_state, next_state) 
    variable s_store_offset, s_load_offset, s_load_base, s_store_base, s_jump_target, s_jump_sext: doubleword;
    begin
    if(rst = '1') then
        next_state <= fetching;
        s_rst <= '1';
        s_REG_write <= '0';
        s_MMU_fetch <= '0';
        s_MMU_store <= '0';
        s_MMU_load <= '0';
        s_halts <= "000";
        s_wb_select <= '0';
        counter_sc <= 0;
        s_ALU_source_select <= "00";
    elsif(rising_edge(clk)) then
    case curr_state is
        when fetching =>
            stupid_fucking_vivado <= "000000";
            s_PC_next <= std_logic_vector(unsigned(s_PC_curr) + 4);
            s_MMU_fetch <= '1';
            s_MMU_store <= '0';
            s_MMU_load <= '0';
            s_REG_write <= '0';
            s_halts <= "000";
            s_rst <= '0';
            s_jump_select <= '0';
            s_wb_select <= '0';
            next_state <= fetching_wait;
    --        if(d_clk = '1') then
    --            next_state <= fetching_wait;
    --        else
    --            next_state <= fetching;
    --        end if;
        when fetching_wait =>
            next_state <= fetching_wait;
            stupid_fucking_vivado <= "000001";
            s_MMU_fetch <= '0';
            if(s_MMU_busy = '0') then
                next_state <= regs;
                s_decode_instruction <= zero_word & s_MMU_instr_out;
            end if;
        when regs =>
            stupid_fucking_vivado <= "000010";
            next_state <= alus;
        when alus =>
            stupid_fucking_vivado <= "000011";
            next_state <= mem;
            case s_opcode is
                when ALU_T =>   -- Case regular, R-type ALU operations
                    -- REG signals
                    s_REG_raddr1 <= s_rs1;
                    s_REG_raddr2 <= s_rs2;
                    s_REG_waddr <= s_rd;
                   -- s_REG_write <= '0';
                    s_REG_write <= '1';
                    -- Use rdata2 instead of sign extended immediate                   
                    s_ALU_source_select <= "00";
    
                    -- Use ALU result instead of MMU data
                    s_wb_select <= '0';

                when LUI_T =>
                    s_REG_raddr1 <= s_rs1;
                    s_REG_waddr <= s_rd;
                    --s_REG_write <= '1';
                    s_ALU_source_select <= "11";
                    s_wb_select <= '0';
                    s_REG_write <= '1';
           --         next_state <= wb;
                when ALUIW_T =>
                    -- REG signals
                    s_REG_raddr1 <= s_rs1;
                    s_REG_waddr <= s_rd;
                    next_state <= wb;
           --     s_REG_write <= '1';
                -- Use sign extended immediate instead of rdata2                   
                    s_ALU_source_select <= "01";
                -- Use ALU result instead of MMU data
                    s_wb_select <= '0';
                    
                when ALUI_T =>  -- Case regular, I-type ALU operations
                    -- REG signals
                    s_REG_raddr1 <= s_rs1;
                    s_REG_waddr <= s_rd;
                    next_state <= wb;
               --     s_REG_write <= '1';
                    -- Use sign extended immediate instead of rdata2                   
                    s_ALU_source_select <= "01";
                    -- Use ALU result instead of MMU data
                    s_wb_select <= '0';
                when LOAD_T =>
                    -- Little endian byte ordering
                    
                    -- Need to signal MMU: full word, half word, quarter word
                    -- effective address is sext(regFile[rs1]) + sext(imm12)
                    case s_instr_code is
                        when instr_LB =>
                            s_MMU_alignment <= "0001";
                            s_load_type <= instr_LB;
                        when instr_LBU =>
                            s_MMU_alignment <= "0001";
                            s_load_type <= instr_LBU;
                        when instr_LH =>
                            s_MMU_alignment <= "0010";
                            s_load_type <= instr_LH;
                        when instr_LHU =>
                            s_MMU_alignment <= "0010";
                            s_load_type <= instr_LHU;
                        when instr_LW =>
                            s_MMU_alignment <= "0100";
                            s_load_type <= instr_LW;
                        when instr_LWU =>
                            s_MMU_alignment <= "0100";
                            s_load_type <= instr_LWU;
                        when others =>
                            s_MMU_alignment <= "1000";
                            s_load_type <= instr_LD;
                    end case;
                    s_load_base := s_REG_debug(to_integer(unsigned(s_rs1)));
                    if('0' = s_imm12(11)) then               
                        s_load_offset := zero_word & "00000000000000000000" & s_imm12; 
                        --s_load_offset <= zero_word & "00000000000000000000" & s_imm12;
                    else
                        s_load_offset := ones_word & "11111111111111111111" & s_imm12;
                        --s_load_offset <= ones_word & "11111111111111111111" & s_imm12;
                    end if;
                    s_load_dest <= s_rd;
                    s_MMU_input_addr <= std_logic_vector(signed(s_load_base) + signed(s_load_offset));
                    --s_MMU_load <= '1';
                    waiting_reason <= "001";
                    next_state <= load_store;
                when STORE_T =>
                    -- Little endian byte ordering
                    s_store_base := s_REG_debug(to_integer(unsigned(s_rs1)));
                    if('0' = s_imm12(11)) then               
                        s_store_offset := zero_word & "00000000000000000000" & s_imm12;
                    else
                        s_store_offset := ones_word & "11111111111111111111" & s_imm12;
                    end if;
                    --s_MMU_input_addr <= std_logic_vector(signed(s_load_base) + signed(s_load_offset));
                    s_MMU_input_addr <= std_logic_vector(signed(s_store_base) + signed(s_store_offset));

                    case s_instr_code is
                        when instr_SB =>
                            s_MMU_input_data <= byte_mask_1 and s_REG_debug(to_integer(unsigned(s_rs2)));
                        when instr_SH =>
                            s_MMU_input_data <= byte_mask_2 and s_REG_debug(to_integer(unsigned(s_rs2)));
                        when instr_SW =>
                            s_MMU_input_data <= byte_mask_4 and s_REG_debug(to_integer(unsigned(s_rs2)));
                        when others =>  -- store doubleword
                            s_MMU_input_data <= s_REG_debug(to_integer(unsigned(s_rs2)));
                    end case;
                    --s_MMU_store <= '1';
                    next_state <= load_store;
                when BRANCH_T =>
                    case s_instr_code is
                        when instr_BEQ =>
                            if(signed(s_REG_debug(to_integer(unsigned(s_rs1)))) = signed(s_REG_debug(to_integer(unsigned(s_rs2))))) then
                                if('0' = s_imm12(11)) then
                                    s_PC_next <= std_logic_vector(signed(s_PC_curr) + signed(std_logic_vector'(zero_word & "0000000000000000000" & s_imm12 & '0')));
                                else
                                    s_PC_next <= std_logic_vector(signed(s_PC_curr) + signed(std_logic_vector'(ones_word & "1111111111111111111" & s_imm12 & '0')));
                                end if;
                            end if;
                        when instr_BNE =>
                            if(signed(s_REG_debug(to_integer(unsigned(s_rs1)))) /= signed(s_REG_debug(to_integer(unsigned(s_rs2))))) then
                                if('0' = s_imm12(11)) then
                                    s_PC_next <= std_logic_vector(signed(s_PC_curr) + signed(std_logic_vector'(zero_word & "0000000000000000000" & s_imm12 & '0')));
                                else
                                    s_PC_next <= std_logic_vector(signed(s_PC_curr) + signed(std_logic_vector'(ones_word & "1111111111111111111" & s_imm12 & '0')));
                                end if;
                            end if;
                        when instr_BLT =>
                            if(signed(s_REG_debug(to_integer(unsigned(s_rs1)))) < signed(s_REG_debug(to_integer(unsigned(s_rs2))))) then
                                if('0' = s_imm12(11)) then
                                    s_PC_next <= std_logic_vector(signed(s_PC_curr) + signed(std_logic_vector'(zero_word & "0000000000000000000" & s_imm12 & '0')));
                                else
                                    s_PC_next <= std_logic_vector(signed(s_PC_curr) + signed(std_logic_vector'(ones_word & "1111111111111111111" & s_imm12 & '0')));
                                end if;
                            end if;
                        when instr_BGE =>
                            if(signed(s_REG_debug(to_integer(unsigned(s_rs1)))) >= signed(s_REG_debug(to_integer(unsigned(s_rs2))))) then
                                if('0' = s_imm12(11)) then
                                    s_PC_next <= std_logic_vector(signed(s_PC_curr) + signed(std_logic_vector'(zero_word & "0000000000000000000" & s_imm12 & '0')));
                                else
                                    s_PC_next <= std_logic_vector(signed(s_PC_curr) + signed(std_logic_vector'(ones_word & "1111111111111111111" & s_imm12 & '0')));
                                end if;
                            end if;
                        when instr_BLTU =>
                            if(unsigned(s_REG_debug(to_integer(unsigned(s_rs1)))) < unsigned(s_REG_debug(to_integer(unsigned(s_rs2))))) then
                                if('0' = s_imm12(11)) then
                                    s_PC_next <= std_logic_vector(signed(s_PC_curr) + signed(std_logic_vector'(zero_word & "0000000000000000000" & s_imm12 & '0')));
                                else
                                    s_PC_next <= std_logic_vector(signed(s_PC_curr) + signed(std_logic_vector'(ones_word & "1111111111111111111" & s_imm12 & '0')));
                                end if;
                            end if;
                        when others => --instr_BGEU
                            if(unsigned(s_REG_debug(to_integer(unsigned(s_rs1)))) >= unsigned(s_REG_debug(to_integer(unsigned(s_rs2))))) then
                                if('0' = s_imm12(11)) then
                                    s_PC_next <= std_logic_vector(signed(s_PC_curr) + signed(std_logic_vector'(zero_word & "0000000000000000000" & s_imm12 & '0')));
                                else
                                    s_PC_next <= std_logic_vector(signed(s_PC_curr) + signed(std_logic_vector'(ones_word & "1111111111111111111" & s_imm12 & '0')));
                                end if;
                            end if;
                    end case;

                when JAL_T =>
                    s_jump_select <= '1';       -- switch in jal write data
                    s_REG_waddr <= s_rd;        -- TODO may be problems since rd could be omitted (pp. 152-3)
                    s_jump_wdata <= s_PC_next;
                    
                    if('0' = s_imm20(19)) then                                    
                        s_jump_target := zero_word & "00000000000" & s_imm20 & "0";
                    else
                        s_jump_target := ones_word & "11111111111" & s_imm20 & "0";
                    end if;
                    s_PC_next <= std_logic_vector(signed(s_PC_curr) + signed(s_jump_target));
                                
                when JALR_T =>
                    s_jump_select <= '1';       -- switch in jal write data
                    s_REG_waddr <= s_rd;        -- TODO may be problems since rd could be omitted (pp. 152-3)
                    s_jump_wdata <= s_PC_next;                            
                    if('0' = s_imm12(11)) then
                        -- note type hinting again
                        -- note wonky ".. set low bit of result to '0' ..."
                        s_jump_sext := zero_word & "00000000000000000000" & s_imm12;
                        s_jump_target := std_logic_vector(
                                             signed(s_REG_debug(to_integer(unsigned(s_rs1)))) +
                                             signed(s_jump_sext)
                                         );
                        s_jump_target(0) := '0';
                    else
                        -- note type hinting again
                        -- note wonky ".. set low bit of result to '0' ..."
                        s_jump_sext := ones_word & "11111111111111111111" & s_imm12;
                        s_jump_target := std_logic_vector(
                                             signed(s_REG_debug(to_integer(unsigned(s_rs1)))) +
                                             signed(s_jump_sext)
                                         );
                        s_jump_target(0) := '0';
                    end if;
                    
                    s_PC_next <= std_logic_vector(signed(s_PC_curr) + signed(s_jump_target));
                            
                when AUIPC_T =>
                    s_jump_select <= '1';
                    s_REG_waddr <= s_rd;
                    next_state <= wb;
                    if('0' = s_imm20(19)) then
                        s_jump_wdata <= std_logic_vector(
                                           signed(s_PC_curr) + 
                                           signed(std_logic_vector'( zero_word & s_imm20 & "000000000000" ))
                                       );
                    else
                        s_jump_wdata <= std_logic_vector(
                                           signed(s_PC_curr) + 
                                           signed(std_logic_vector'( ones_word & s_imm20 & "000000000000" ))
                                   );                                end if;
                when others =>
                end case;
        when load_store =>
            next_state <= mem;
            if(s_OPCODE = LOAD_T) then
                s_MMU_load <= '1';
            elsif(s_OPCODE = STORE_T) then
                s_MMU_store <= '1';
            end if;
        when mem =>
            next_state <= mem;
            stupid_fucking_vivado <= "000100";
            s_REG_write <= '0';
            s_MMU_store <= '0';
            s_MMU_load <= '0'; --Reset these suckers
            if(s_mmu_busy = '0') then
                if(s_opcode = LOAD_T) then
                    s_wb_select <= '1';
                    next_state <= wb;
                    s_REG_waddr <= s_load_dest;
                    -- These are the special cases for the writebacks
                    case s_load_type is
                        when instr_LB =>
                            if('0' = s_MMU_output_data(7)) then
                                s_load_wb_data <= zero_word & "000000000000000000000000" & s_MMU_output_data(7 downto 0);
                            else
                                s_load_wb_data <= ones_word & "111111111111111111111111" & s_MMU_output_data(7 downto 0);
                            end if;
                        when instr_LBU =>
                            s_load_wb_data <= zero_word & "000000000000000000000000" & s_MMU_output_data(7 downto 0);
                        when instr_LH =>
                            if('0' = s_MMU_output_data(7)) then
                                s_load_wb_data <= zero_word & "0000000000000000" & s_MMU_output_data(15 downto 0);
                            else
                                s_load_wb_data <= ones_word & "1111111111111111" & s_MMU_output_data(15 downto 0);
                            end if;
                        when instr_LHU =>
                            s_load_wb_data <= zero_word & "0000000000000000" & s_MMU_output_data(15 downto 0);
                        when instr_LW =>
                            if('0' = s_MMU_output_data(31)) then
                                s_load_wb_data <= zero_word & s_MMU_output_data(31 downto 0);
                            else
                                s_load_wb_data <= ones_word & s_MMU_output_data(31 downto 0);
                            end if;
                        when instr_LWU =>
                            s_load_wb_data <= zero_word & s_MMU_output_data(31 downto 0);
                        when others =>
                            s_load_wb_data <= s_MMU_output_data;
                        end case;                        
                else
                    next_state <= done;
                end if;
            end if;
        when wb =>
            next_state <= wb;
            next_state <= done;
            s_REG_write <= '1';
            stupid_fucking_vivado <= "000101";
--            shifterCounter <= shifterCounter + 1;
--            if(shifterCounter > 2) then
--                s_REG_write <= '1';
--                next_state <= done;
--                shifterCounter <= 0;
--            end if;
        when done =>
            counter_sc <= 0;
            s_jump_select <= '0';
            s_REG_write <= '0';
            if(debugger_step = '0') then
                    next_state <= fetching;
                else
                    next_state <= done;
                end if;
            --pragma synthesis off
                next_state <= fetching;
            --pragma synthesis on
            stupid_fucking_vivado <= "000110";
        when others =>
            stupid_fucking_vivado <= "000111";
            next_state <= fetching;
    end case;
    end if;
end process;
s_MMU_satp <= (others => '0');
status <= s_MMU_busy;
--s_IM_input_data <= s_MMU_instr_out;
--LED(15 downto 9) <= s_opcode;
--LED(8 downto 0) <= s_MMU_LED(8 downto 0);

UART_TXD <= s_MMU_UART_TXD when UART_Switch = '1' else s_DEBUG_UART_TXD;
debugger_step <= '0' when UART_Switch ='1' else d_clk;

LED <= s_MMU_LED;
 
--process(clk) begin
--    if(rising_edge(clk)) then
--        if(ALU_Switch = '1') then
--            case ROM_Switch is
--                when "00" => LED <= s_MMU_instr_out(15 downto 0);
--                when "01" => LED <= s_MMU_LED;
--                when "10" => LED <= s_ALU_result(15 downto 0);
--                when "11" => LED <= s_ALU_result(31 downto 16);
--                when others => --what
--           end case;
--        else
--            LED <= s_MMU_LED;
--        end if;
--    end if;
--end process;

end Behavioral;
