----------------------------------------------------------------------------------
-- Engineer: Longofono
--
-- Create Date: 02/10/2018 06:05:22 PM
-- Module Name: simple_core - Behavioral
-- Description: Simplest version of the ALU pipeline for HW testing
--
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library config;
use work.config.all;

entity simple_core is
  Port(
    status: out std_logic; -- LED blinkenlites
    clk: in std_logic;  -- Tied to switch SW15
    rst: in std_logic   -- Tied to switch SW0
  );
end simple_core;

architecture Behavioral of simple_core is

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

component MMU_stub is
    Port(
        clk: in std_logic;
        rst: in std_logic;
        addr_in: in doubleword;
        data_in: in doubleword;
        store: in std_logic;
        load: in std_logic;
        busy: out std_logic;
        ready_instr: in std_logic;
        addr_instr: in doubleword;
        alignment: in std_logic_vector(3 downto 0);
        data_out: out doubleword;
        instr_out: out doubleword;
        error: out std_logic_vector(5 downto 0)
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
signal s_MMU_store: std_logic;                      -- Signal MMU to store
signal s_MMU_load: std_logic;                       -- Signal MMU to load
signal s_MMU_busy: std_logic;                       -- MMU is loading, storing, or fetching
signal s_ALU_source_select: std_logic;              -- Switch in immediate values

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
signal s_MMU_input_addr: doubleword;
signal s_MMU_input_data: doubleword;
signal s_MMU_alignment: std_logic_vector(3 downto 0);       -- One-hot selection in bytes
signal s_MMU_output_data: doubleword;
signal s_MMU_output_instr: doubleword;
signal s_MMU_error: std_logic_vector(5 downto 0);

-- Others
signal s_sext_12: doubleword;                               -- Sign extended immediate value
signal s_sext_20: doubleword;                               -- Sign extended immediate value
signal privilege_mode: std_logic_vector(1 downto 0) := MACHINE_MODE;

-- High-level states of operation (distinct from  modes)
type state is (setup, teardown, normal, waiting, exception);
signal curr_state, next_state: state;

-- Control status registers followed by scratch
type CSR_t is array (0 to 64) of doubleword;
signal CSR: CSR_t;

-- Exception flags
-- From privilege specification: MSB 1 => asynchronous, MSB 0 => synchronous
-- Remaining bits are binary-encoded exception code
signal exceptions: std_logic_vector(4 downto 0) := (others => '0');

-- If in waiting state, reason determines actions on exit
signal waiting_reason: std_logic_vector(2 downto 0);

-- Handle complicated CSR read behaviors
-- @param CSR_bits - The 12 bit CSR address per the specification
-- @param value - The value to be read back
-- @param mode - What mode we encountered this instruction in
-- Notes: need to pass handle to CSR in because procedures are not allowed to modify signals without an explicit handle
-- TODO add in interrupt setting
-- TODO handle cycle and time readings externally
procedure CSR_read(CSR_bits: in std_logic_vector(11 downto 0); value: out doubleword; CSR: inout CSR_t; mode: in std_logic_vector(1 downto 0); exceptions: inout std_logic_vector(4 downto 0)) is
begin

    -- TODO handle mode fails and offending instruction logging
    case CSR_bits is
        when CSR_ADDR_FFLAGS            =>
            if(CSR(CSR_MSTATUS)(14 downto 13) = "00") then
                -- Error, no FP unit
                exceptions := "00010";
            else
                value := CSR(CSR_MSTATUS) and x"000000000000001f";
            end if;
        when CSR_ADDR_FRM               =>
            if(CSR(CSR_MSTATUS)(14 downto 13) = "00") then
                -- Error, no FP unit
                exceptions := "00010";
            else
                value := CSR(CSR_MSTATUS) and x"00000000000000e0";
            end if;
        when CSR_ADDR_FCSR              =>
            if(CSR(CSR_MSTATUS)(14 downto 13) = "00") then
                -- Error, no FP unit
                exceptions := "00010";
            else
                value := CSR(CSR_MSTATUS) and x"0000000000006000";
            end if;
        when CSR_ADDR_CYCLE             =>
            if( (CSR(CSR_SCOUNTEREN)( 0 ) = '0') and mode = USER_MODE ) then
                -- Error if user mode not allowed to read
                exceptions := "00010";
            elsif( (CSR(CSR_MCOUNTEREN)( 0 ) = '0') and mode = SUPERVISOR_MODE ) then
                -- Error if supervisor mode not allowed to read
                exceptions := "00010";
            else
                value := CSR(CSR_MINSTRET);
            end if;
        when CSR_ADDR_TIME              =>
            if( (CSR(CSR_SCOUNTEREN)( 0 ) = '0') and mode = USER_MODE ) then
                -- Error if user mode not allowed to read
                exceptions := "00010";
            elsif( (CSR(CSR_MCOUNTEREN)( 0 ) = '0') and mode = SUPERVISOR_MODE ) then
                -- Error if supervisor mode not allowed to read
                exceptions := "00010";
            else
                -- TODO tie this to external time signal
            end if;
        when CSR_ADDR_INSTRET           =>
            if( (CSR(CSR_SCOUNTEREN)( 0 ) = '0') and mode = USER_MODE ) then
                -- Error if user mode not allowed to read
                exceptions := "00010";
            elsif( (CSR(CSR_MCOUNTEREN)( 0 ) = '0') and mode = SUPERVISOR_MODE ) then
                -- Error if supervisor mode not allowed to read
                exceptions := "00010";
            else
                value := CSR(CSR_MINSTRET);
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
            if( (CSR(CSR_SCOUNTEREN)( to_integer(unsigned(CSR_BITS(4 downto 0))) ) = '0') and mode = USER_MODE ) then
               -- Error if user mode not allowed to read
                exceptions := "00010";
            elsif( (CSR(CSR_MCOUNTEREN)( to_integer(unsigned(CSR_BITS(4 downto 0))) ) = '0') and mode = SUPERVISOR_MODE ) then
               -- Error if supervisor mode not allowed to read
                exceptions := "00010";
            else
                value := CSR(CSR_MINSTRET);
            end if;
        when CSR_ADDR_SSTATUS           =>
            if(mode = USER_MODE) then
                exceptions := "00010";
            else
                if( CSR(CSR_MSTATUS)( 16 downto 15 ) = "11" or CSR(CSR_MSTATUS)( 14 downto 13 ) = "11") then
                    value := CSR(CSR_MSTATUS) and x"000000000005e122";
                else
                    value := CSR(CSR_MSTATUS) and x"800000000005e122";
                end if;
            end if;
        when CSR_ADDR_SIE               =>
            if(mode = USER_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_MIE) and CSR(CSR_MIDELEG);
            end if;
        when CSR_ADDR_STVEC             =>
            if(mode = USER_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_STVEC);
            end if;
        when CSR_ADDR_SCOUNTEREN        =>
            if(mode = USER_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_SCOUNTEREN);
            end if;
        when CSR_ADDR_SSCRATCH          =>
            if(mode = USER_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_SSCRATCH);
            end if;
        when CSR_ADDR_SEPC              =>
            if(mode = USER_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_SEPC);
            end if;
        when CSR_ADDR_SCAUSE            =>
            if(mode = USER_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_SCAUSE);
            end if;
        when CSR_ADDR_STVAL             =>
            if(mode = USER_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_STVAL);
            end if;
        when CSR_ADDR_SIP               =>
            if(mode = USER_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_MIP) and CSR(CSR_MIDELEG);
            end if;
        when CSR_ADDR_SATP              =>
            if(CSR(CSR_MSTATUS)( 20 ) = '1' and not (mode = MACHINE_MODE)) then
                -- Error if not in machine mode
                exceptions := "00010";
            else
                value := CSR(CSR_SATP);
            end if;
        when CSR_ADDR_MVENDORID         =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := zero_word & zero_word;
            end if;
        when CSR_ADDR_MARCHID           =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := zero_word & zero_word;
            end if;
        when CSR_ADDR_MIMPID            =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := zero_word & zero_word;
            end if;
        when CSR_ADDR_MHARTID           =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := zero_word & zero_word;
            end if;
        when CSR_ADDR_MSTATUS           =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_MSTATUS);
            end if;
        when CSR_ADDR_MISA              =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_MISA);
            end if;
        when CSR_ADDR_MEDELEG           =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_MEDELEG);
            end if;
        when CSR_ADDR_MIDELEG           =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_MIDELEG);
            end if;
        when CSR_ADDR_MIE               =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_MIE);
            end if;
        when CSR_ADDR_MTVEC             =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_MTVEC);
            end if;
        when CSR_ADDR_MCOUNTEREN        =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_MCOUNTEREN);
            end if;
        when CSR_ADDR_MSCRATCH          =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_MSCRATCH);
            end if;
        when CSR_ADDR_MEPC              =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_MEPC);
            end if;
        when CSR_ADDR_MCAUSE            =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_MCAUSE);
            end if;
        when CSR_ADDR_MTVAL             =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_MTVAL);
            end if;
        when CSR_ADDR_MIP               =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := CSR(CSR_MIP);
            end if;
        when CSR_ADDR_MHPMCOUNTER3  | CSR_ADDR_MHPMCOUNTER4  | CSR_ADDR_MHPMCOUNTER5  | CSR_ADDR_MHPMCOUNTER6  |
             CSR_ADDR_MHPMCOUNTER7  | CSR_ADDR_MHPMCOUNTER8  | CSR_ADDR_MHPMCOUNTER9  | CSR_ADDR_MHPMCOUNTER10 |
             CSR_ADDR_MHPMCOUNTER11 | CSR_ADDR_MHPMCOUNTER12 | CSR_ADDR_MHPMCOUNTER13 | CSR_ADDR_MHPMCOUNTER14 |
             CSR_ADDR_MHPMCOUNTER15 | CSR_ADDR_MHPMCOUNTER16 | CSR_ADDR_MHPMCOUNTER17 | CSR_ADDR_MHPMCOUNTER18 |
             CSR_ADDR_MHPMCOUNTER19 | CSR_ADDR_MHPMCOUNTER20 | CSR_ADDR_MHPMCOUNTER21 | CSR_ADDR_MHPMCOUNTER22 |
             CSR_ADDR_MHPMCOUNTER23 | CSR_ADDR_MHPMCOUNTER24 | CSR_ADDR_MHPMCOUNTER25 | CSR_ADDR_MHPMCOUNTER26 |
             CSR_ADDR_MHPMCOUNTER27 | CSR_ADDR_MHPMCOUNTER28 | CSR_ADDR_MHPMCOUNTER29 | CSR_ADDR_MHPMCOUNTER30 |
             CSR_ADDR_MHPMCOUNTER31     =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := zero_word & zero_word;
            end if;
        when CSR_ADDR_MHPMEVENT3  | CSR_ADDR_MHPMEVENT4  | CSR_ADDR_MHPMEVENT5  | CSR_ADDR_MHPMEVENT6  |
             CSR_ADDR_MHPMEVENT7  | CSR_ADDR_MHPMEVENT8  | CSR_ADDR_MHPMEVENT9  | CSR_ADDR_MHPMEVENT10 |
             CSR_ADDR_MHPMEVENT11 | CSR_ADDR_MHPMEVENT12 | CSR_ADDR_MHPMEVENT13 | CSR_ADDR_MHPMEVENT14 |
             CSR_ADDR_MHPMEVENT15 | CSR_ADDR_MHPMEVENT16 | CSR_ADDR_MHPMEVENT17 | CSR_ADDR_MHPMEVENT18 |
             CSR_ADDR_MHPMEVENT19 | CSR_ADDR_MHPMEVENT20 | CSR_ADDR_MHPMEVENT21 | CSR_ADDR_MHPMEVENT22 |
             CSR_ADDR_MHPMEVENT23 | CSR_ADDR_MHPMEVENT24 | CSR_ADDR_MHPMEVENT25 | CSR_ADDR_MHPMEVENT26 |
             CSR_ADDR_MHPMEVENT27 | CSR_ADDR_MHPMEVENT28 | CSR_ADDR_MHPMEVENT29 | CSR_ADDR_MHPMEVENT30 |
             CSR_ADDR_MHPMEVENT31       =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                value := zero_word & zero_word;
            end if;
        when others                     =>
            -- All others not implemented, set trap
            exceptions := "00010";
    end case;
end; -- CSR_read procedure



-- Handle complicated CSR write behaviors
-- @param CSR_bits - The 12 bit CSR address per the specification
-- @param value - The write value
-- @param mode - What mode we encountered this instruction in
-- Notes: need to pass handle to CSR in because procedures are not allowed to modify signals without an explicit handle
-- TODO handle cycle and time readings externally
procedure CSR_write(CSR_bits: in std_logic_vector(11 downto 0); value: in doubleword; CSR: inout CSR_t; mode: in std_logic_vector(1 downto 0); exceptions: inout std_logic_vector(4 downto 0)) is
begin
    case CSR_bits is
        when CSR_ADDR_FFLAGS        =>
            if(CSR(CSR_MSTATUS)(14 downto 13) = "00") then
                -- Error, no FP unit
                exceptions := "00010";
            else
                CSR(CSR_MSTATUS)(14 downto 13) := "11"; -- Set FP dirty bits
                CSR(CSR_MSTATUS)( 63 ) := '1'; -- Set flag indicating dirty bits
                CSR(CSR_FCSR)(4 downto 0) := value(4 downto 0); -- Set FP flags passed in
            end if;
        when CSR_ADDR_FRM           =>
            if(CSR(CSR_MSTATUS)(14 downto 13) = "00") then
                -- Error, no FP unit
                exceptions := "00010";
            else
                CSR(CSR_MSTATUS)(14 downto 13) := "11"; -- Set FP dirty bits
                CSR(CSR_MSTATUS)( 63 ) := '1'; -- Set flag indicating dirty bits
                CSR(CSR_FCSR)(7 downto 5) := value(2 downto 0); -- Set FP rounging mode passed in
            end if;
        when CSR_ADDR_FCSR          =>
            if(CSR(CSR_MSTATUS)(14 downto 13) = "00") then
                -- Error, no FP unit
                exceptions := "00010";
            else
                CSR(CSR_MSTATUS)(14 downto 13) := "11"; -- Set FP dirty bits
                CSR(CSR_MSTATUS)( 63 ) := '1'; -- Set flag indicating dirty bits
                CSR(CSR_FCSR)(7 downto 0) := value(7 downto 0); -- Set FP rounging mode and flags passed in
            end if;
        when CSR_ADDR_SSTATUS       =>
            if (mode = USER_MODE) then
                exceptions := "00010";
            else
                CSR(CSR_MSTATUS)( 18 ) := value(18); -- Update Smode portion of MSTATUS
                CSR(CSR_MSTATUS)( 16 downto 15 ) := value(16 downto 15);
                CSR(CSR_MSTATUS)( 14 downto 13 ) := value(14 downto 13);
                CSR(CSR_MSTATUS)( 8 ) := value(8);
                CSR(CSR_MSTATUS)( 5 ) := value(5);
                CSR(CSR_MSTATUS)( 1 ) := value(1);
            end if;
        when CSR_ADDR_SIE           => -- Update Smode interrupts to and of MIE and delegations
            if (mode = USER_MODE) then
                exceptions := "00010";
            else
                CSR(CSR_MIE)( 12 ) := value(12) and CSR(CSR_MIDELEG)( 12 );
                CSR(CSR_MIE)( 9 ) := value(9) and CSR(CSR_MIDELEG)( 9 );
                CSR(CSR_MIE)( 7 ) := value(7) and CSR(CSR_MIDELEG)( 7 );
                CSR(CSR_MIE)( 5 ) := value(5) and CSR(CSR_MIDELEG)( 5 );
                CSR(CSR_MIE)( 3 ) := value(3) and CSR(CSR_MIDELEG)( 3 );
                CSR(CSR_MIE)( 1 ) := value(1) and CSR(CSR_MIDELEG)( 1 );
            end if;
        when CSR_ADDR_STVEC         =>  -- update STVec to the shifted address in 63:2
            if (mode = USER_MODE) then
                exceptions := "00010";
            else
                CSR(CSR_STVEC)(63 downto 2) := value(63 downto 2);
            end if;
        when CSR_ADDR_SCOUNTEREN    =>
            if (mode = USER_MODE) then
                exceptions := "00010";
            else
                CSR( CSR_SCOUNTEREN ) := value; -- Pass through new enbale value
            end if;
        when CSR_ADDR_SSCRATCH      =>
            if (mode = USER_MODE) then
                exceptions := "00010";
            else
                CSR( CSR_SSCRATCH ) := value; -- Pass through new scratch value
            end if;
        when CSR_ADDR_SEPC          =>
            if (mode = USER_MODE) then
                exceptions := "00010";
            else
                CSR( CSR_SEPC ) := value; -- Pass through new scratch value
            end if;
        when CSR_ADDR_SCAUSE        =>
            if (mode = USER_MODE) then
                exceptions := "00010";
            else
                CSR( CSR_SCAUSE ) := value; -- Pass through new scratch value
            end if;
        when CSR_ADDR_STVAL         =>
            if (mode = USER_MODE) then
                exceptions := "00010";
            else
                CSR( CSR_STVAL ) := value; -- Pass through new scratch value
            end if;
        when CSR_ADDR_SIP           =>
            if (mode = USER_MODE) then
                exceptions := "00010";
            else
                CSR(CSR_MIP)( 1 ) := value(1) and CSR(CSR_MIDELEG)( 1 ); -- Pass through new scratch value
            end if;
        when CSR_ADDR_SATP          =>
            if (mode = USER_MODE) then
                exceptions := "00010";
            else
                if(CSR(CSR_MSTATUS)(20) = '1') then
                    exceptions := "00010";
                elsif( (value(63 downto 60) = "0000") or
                       (value(63 downto 60) = "1000") or
                       (value(63 downto 60) = "1001") ) then
                    -- This won't actually do anything, since we aren't implementing address translations for Smode
                    CSR(CSR_SATP)(63 downto 60) := value(63 downto 60);
                    CSR(CSR_SATP)(43 downto 0) := value(43 downto 0);
                end if;
            end if;
        when CSR_ADDR_MSTATUS       =>
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                -- update status
                if(value(14 downto 13) = "00") then -- if not dirty
                    CSR(CSR_MSTATUS)(22 downto 17) := value(22 downto 17);
                    CSR(CSR_MSTATUS)(14 downto 11) := value(14 downto 11);
                    CSR(CSR_MSTATUS)( 8 ) := value(8);
                    CSR(CSR_MSTATUS)( 7 ) := value(7);
                    CSR(CSR_MSTATUS)( 5 ) := value(5);
                    CSR(CSR_MSTATUS)( 3 ) := value(3);
                    CSR(CSR_MSTATUS)( 1 ) := value(1);
                    CSR(CSR_MSTATUS)( 63 ) := '0';
                else
                    CSR(CSR_MSTATUS)(22 downto 17) := value(22 downto 17);
                    CSR(CSR_MSTATUS)(14 downto 11) := value(14 downto 11);
                    CSR(CSR_MSTATUS)( 8 ) := value(8);
                    CSR(CSR_MSTATUS)( 7 ) := value(7);
                    CSR(CSR_MSTATUS)( 5 ) := value(5);
                    CSR(CSR_MSTATUS)( 3 ) := value(3);
                    CSR(CSR_MSTATUS)( 1 ) := value(1);
                    CSR(CSR_MSTATUS)( 63 ) := '1';
                end if;
            end if;
        when CSR_ADDR_MISA          => -- Do nothing
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            end if;
        when CSR_ADDR_MEDELEG       => -- Update delegation of synchronous exceptions
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                CSR( CSR_MEDELEG ) := value;
            end if;
        when CSR_ADDR_MIDELEG       => -- Update delegation of aynschronous exceptions
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                CSR(CSR_MIDELEG)( 12 ) := value(12);
                CSR(CSR_MIDELEG)( 9 ) := value(9);
                CSR(CSR_MIDELEG)( 5 ) := value(5);
                CSR(CSR_MIDELEG)( 1 ) := value(1);
            end if;
        when CSR_ADDR_MIE           => -- Update enabled exceptions
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                CSR(CSR_MIE)( 12 ) := value(12);
                CSR(CSR_MIE)( 9 ) := value(9);
                CSR(CSR_MIE)( 7 ) := value(7);
                CSR(CSR_MIE)( 5 ) := value(5);
                CSR(CSR_MIE)( 3 ) := value(3);
                CSR(CSR_MIE)( 1 ) := value(1);
            end if;
        when CSR_ADDR_MTVEC         => -- Update shifted base address for machine mode trap handler
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                -- Note: bit 1 is reserved because reasons
                CSR(CSR_MTVEC)(63 downto 2) := value(63 downto 2);
                CSR(CSR_MTVEC)( 0 ) := value(0);
            end if;
        when CSR_ADDR_MCOUNTEREN    => -- Pass through new counter enable bit
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                CSR( CSR_MCOUNTEREN ) := value;
            end if;
        when CSR_ADDR_MSCRATCH      =>  -- Pass through new scratch value
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                CSR( CSR_MSCRATCH ) := value;
            end if;
        when CSR_ADDR_MEPC          =>  -- Pass through new exception PC
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                CSR( CSR_MEPC ) := value;
            end if;
        when CSR_ADDR_MCAUSE        =>  -- Pass through new exception cause
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                CSR( CSR_MCAUSE ) := value;
            end if;
        when CSR_ADDR_MTVAL         =>  -- Pass through address of the bad address for relevant interrupts (store/load misaligned, page fault)
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                CSR( CSR_MTVAL ) := value;
            end if;
        when CSR_ADDR_MIP           => -- Allow Smode timer and software interrupts to be signalled
            if not (mode = MACHINE_MODE) then
                exceptions := "00010";
            else
                CSR(CSR_MIP)( 5 ) := value(5);
                CSR(CSR_MIP)( 1 ) := value(1);
            end if;
        when CSR_ADDR_MHPMCOUNTER3  => -- Ignore writes
        when CSR_ADDR_MHPMCOUNTER4  =>
        when CSR_ADDR_MHPMCOUNTER5  =>
        when CSR_ADDR_MHPMCOUNTER6  =>
        when CSR_ADDR_MHPMCOUNTER7  =>
        when CSR_ADDR_MHPMCOUNTER8  =>
        when CSR_ADDR_MHPMCOUNTER9  =>
        when CSR_ADDR_MHPMCOUNTER10 =>
        when CSR_ADDR_MHPMCOUNTER11 =>
        when CSR_ADDR_MHPMCOUNTER12 =>
        when CSR_ADDR_MHPMCOUNTER13 =>
        when CSR_ADDR_MHPMCOUNTER14 =>
        when CSR_ADDR_MHPMCOUNTER15 =>
        when CSR_ADDR_MHPMCOUNTER16 =>
        when CSR_ADDR_MHPMCOUNTER17 =>
        when CSR_ADDR_MHPMCOUNTER18 =>
        when CSR_ADDR_MHPMCOUNTER19 =>
        when CSR_ADDR_MHPMCOUNTER20 =>
        when CSR_ADDR_MHPMCOUNTER21 =>
        when CSR_ADDR_MHPMCOUNTER22 =>
        when CSR_ADDR_MHPMCOUNTER23 =>
        when CSR_ADDR_MHPMCOUNTER24 =>
        when CSR_ADDR_MHPMCOUNTER25 =>
        when CSR_ADDR_MHPMCOUNTER26 =>
        when CSR_ADDR_MHPMCOUNTER27 =>
        when CSR_ADDR_MHPMCOUNTER28 =>
        when CSR_ADDR_MHPMCOUNTER29 =>
        when CSR_ADDR_MHPMCOUNTER30 =>
        when CSR_ADDR_MHPMCOUNTER31 =>
        when CSR_ADDR_MHPMEVENT3    =>
        when CSR_ADDR_MHPMEVENT4    =>
        when CSR_ADDR_MHPMEVENT5    =>
        when CSR_ADDR_MHPMEVENT6    =>
        when CSR_ADDR_MHPMEVENT7    =>
        when CSR_ADDR_MHPMEVENT8    =>
        when CSR_ADDR_MHPMEVENT9    =>
        when CSR_ADDR_MHPMEVENT10   =>
        when CSR_ADDR_MHPMEVENT11   =>
        when CSR_ADDR_MHPMEVENT12   =>
        when CSR_ADDR_MHPMEVENT13   =>
        when CSR_ADDR_MHPMEVENT14   =>
        when CSR_ADDR_MHPMEVENT15   =>
        when CSR_ADDR_MHPMEVENT16   =>
        when CSR_ADDR_MHPMEVENT17   =>
        when CSR_ADDR_MHPMEVENT18   =>
        when CSR_ADDR_MHPMEVENT19   =>
        when CSR_ADDR_MHPMEVENT20   =>
        when CSR_ADDR_MHPMEVENT21   =>
        when CSR_ADDR_MHPMEVENT22   =>
        when CSR_ADDR_MHPMEVENT23   =>
        when CSR_ADDR_MHPMEVENT24   =>
        when CSR_ADDR_MHPMEVENT25   =>
        when CSR_ADDR_MHPMEVENT26   =>
        when CSR_ADDR_MHPMEVENT27   =>
        when CSR_ADDR_MHPMEVENT28   =>
        when CSR_ADDR_MHPMEVENT29   =>
        when CSR_ADDR_MHPMEVENT30   =>
        when CSR_ADDR_MHPMEVENT31   =>
        when others                 =>
            -- All others not implemented, set trap
            exceptions := "00010";

    end case;
end; -- CSR_write procedure


begin

-- Component instantiations and mapping
myDecode: decode
    port map(
        instr => s_IM_output_data,
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

myIM: fence  -- MMU writes back instructions and data to core
    port map(
        clk => clk,
        rst => s_rst,
        halt => s_halts(2),
        ready_input => s_request_IM_in,
        ready_output => s_request_IM_out,
        output_OK => s_request_IM_outack,
        input_OK => s_request_IM_inack,
        input_data => s_IM_input_data,
        input_address => s_IM_input_addr,
        output_data => s_IM_output_data,
        output_address => s_IM_output_addr
);

WBMux: mux
    port map(
        sel => s_WB_select,
        zero_port => s_ALU_result,
        one_port => s_MMU_output_data,
        out_port => s_REG_wdata
);

ALUMux: mux
    port map(
        sel => s_ALU_source_select,
        zero_port => s_REG_rdata2,
        one_port => s_sext_12,
        out_port => s_ALU_input2
    );

MMU: MMU_stub
    port map(
        clk => clk,
        rst => s_rst,
        addr_in => s_MMU_input_addr,
        data_in => s_MMU_input_data,
        store => s_MMU_store,
        load => s_MMU_load,
        busy => s_MMU_busy,
        ready_instr => s_request_IM_inack,
        addr_instr => s_PC_next,
        alignment => s_MMU_alignment,
        data_out => s_MMU_output_data,
        instr_out => s_IM_input_data,
        error => s_MMU_error
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

advance_state: process(clk, rst)
begin

end process;

compute: process(curr_state)
begin
end process;

process(clk, rst)
begin
    -- Default values reset at every cycle
    s_rst <= '0';
    s_halts <= "000";
    s_MMU_load <= '0';
    s_MMU_store <= '0';

    -- Always signal that we are ready for a fetch
    s_request_IM_in <= '1';
    s_request_IM_out <= '1';
    --s_request_IM_out <= '0';

    if('1' = rst) then
        s_rst <= '1';
        s_PC_next <= (others => '0');
        --s_PC_next <= (31 => '1', others => '0'); -- base address should be x80000000

    elsif(rising_edge(clk)) then
        if('1' = s_request_IM_outack) then --  if the current instruction is valid     
            -- Update PC so we get a new instruction,
            -- Note that loads and stores will be taken before fetches
            -- Fetch in doubleword increments relative to current PC
            s_MMU_alignment <= "1000";
            s_PC_next <= std_logic_vector((unsigned(s_PC_next) + 8));
        end if; -- '1' = s_request ...

        if( '0' = s_MMU_busy) then  -- if we are not waiting on MMU
            -- do work
            case s_opcode is
                when ALU_T =>   -- Case regular, R-type ALU operations
                    -- REG signals
                    s_REG_raddr1 <= s_rs1;
                    s_REG_raddr2 <= s_rs2;
                    s_REG_waddr <= s_rd;
                    s_REG_write <= '1';

                    -- Use rdata2 instead of sign extended immediate                   
                    s_ALU_source_select <= '0';

                    -- Use ALU result instead of MMU data
                    s_wb_select <= '0';

                when ALUI_T =>  -- Case regular, I-type ALU operations
                    -- REG signals
                    s_REG_raddr1 <= s_rs1;
                    s_REG_waddr <= s_rd;
                    s_REG_write <= '1';

                    -- Use sign extended immediate instead of rdata2                   
                    s_ALU_source_select <= '1';

                    -- Use ALU result instead of MMU data
                    s_wb_select <= '0';

                when others =>
                    -- Do nothing
            end case;
        else
            s_halts <= "111";
        end if; -- '0' = s_MMU_busy ...
    end if; -- '1' = rst ...

end process;

status <= '1';

end Behavioral;
