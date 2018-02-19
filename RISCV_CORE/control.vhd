----------------------------------------------------------------------------------
-- Engineer: Longofono
-- 
-- Create Date: 02/04/2018 01:13:09 PM
-- Module Name: control - Behavioral
-- Description: Control unit for RISCV core
-- 
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library config;
use work.config.all;

entity control is
    Port(
        clk:    in std_logic;                           -- System clock
        rst:    in std_logic;                           -- System reset
        instruction_ready:  in std_logic;               -- IM ready
        writeback_ack:  in std_logic;                   -- WB ready for input
        writeback_request:  out std_logic;              -- Signal WB results waiting
        MMU_load_complete:  in std_logic;               -- MMU load data is ready to be written back               
        ALU_halts: out std_logic_vector(4 downto 0);    -- Signal ALU pipeline modules to halt
        PC_select: out std_logic_vector(4 downto 0);    -- Select for PCnext mux
        instr_code: in instr_t;                         -- The current instruction from the decode module
        instr:  in doubleword;                          -- The instruction itself for CSR instruction access
        RegFile_raddr: out std_logic_vector(4 downto 0);-- For CSR instrs, read address of regfile
        RegFile_waddr: out std_logic_vector(4 downto 0);-- For CSR instrs, write back address of regfile
        RegFile_rdata: in doubleword;                   -- For CSR instrs, read data from above address
        RegFile_wdata: out doubleword;                  -- For CSR instrs, write data to above address
        CSR_bits:      in std_logic_vector(11 downto 0);-- For CSR instrs, address of CSR from spec
        rs1: in reg_t;
        rs2: in reg_t;
        rs3: in reg_t;
        rd:  in reg_t
    );
end control;

architecture Behavioral of control is

-- High-level states of operation (distinct from privilege modes)
type state is (setup, teardown, normal, waiting, exception);
signal curr_state, next_state: state;

-- Control status registers followed by scratch
type CSR_t is array (0 to 64) of doubleword;
signal CSR: CSR_t;

-- If in waiting state, reason determines actions on exit
signal waiting_reason: std_logic_vector(2 downto 0);


-- Handle complicated CSR read behaviors
-- @param CSR_bits - The 12 bit CSR address per the specification
-- @param value - The value to be read back
-- @param mode - What mode we encountered this instruction in
-- Notes: need to pass handle to CSR in because procedures are not allowed to modify signals without an explicit handle
procedure CSR_read(CSR_bits: in std_logic_vector(11 downto 0); value: out doubleword; CSR: inout CSR_t; mode: in std_logic_vector(1 downto 0)) is
begin

    -- TODO add checks for mode
    -- TODO handle mode fails and offending instruction logging
    case CSR_bits is
        when CSR_ADDR_USTATUS       => 
        when CSR_ADDR_UIE       => 
        when CSR_ADDR_UTVEC       => 
        when CSR_ADDR_USCRATCH       => 
        when CSR_ADDR_UEPC       => 
        when CSR_ADDR_UCAUSE       => 
        when CSR_ADDR_UTVAL       => 
        when CSR_ADDR_UIP       => 
        when CSR_ADDR_FFLAGS       => 
        when CSR_ADDR_FRM       => 
        when CSR_ADDR_FCSR       => 
        when CSR_ADDR_CYCLE       => 
        when CSR_ADDR_TIME       => 
        when CSR_ADDR_INSTRET       => 
        when CSR_ADDR_HPMCOUNTER3      => 
        when CSR_ADDR_HPMCOUNTER4      => 
        when CSR_ADDR_HPMCOUNTER5      => 
        when CSR_ADDR_HPMCOUNTER6      => 
        when CSR_ADDR_HPMCOUNTER7      => 
        when CSR_ADDR_HPMCOUNTER8      => 
        when CSR_ADDR_HPMCOUNTER9      => 
        when CSR_ADDR_HPMCOUNTER10      => 
        when CSR_ADDR_HPMCOUNTER11      => 
        when CSR_ADDR_HPMCOUNTER12      => 
        when CSR_ADDR_HPMCOUNTER13      => 
        when CSR_ADDR_HPMCOUNTER14      => 
        when CSR_ADDR_HPMCOUNTER15      => 
        when CSR_ADDR_HPMCOUNTER16      => 
        when CSR_ADDR_HPMCOUNTER17      => 
        when CSR_ADDR_HPMCOUNTER18      => 
        when CSR_ADDR_HPMCOUNTER19      => 
        when CSR_ADDR_HPMCOUNTER20      => 
        when CSR_ADDR_HPMCOUNTER21      => 
        when CSR_ADDR_HPMCOUNTER22      => 
        when CSR_ADDR_HPMCOUNTER23      => 
        when CSR_ADDR_HPMCOUNTER24      => 
        when CSR_ADDR_HPMCOUNTER25      => 
        when CSR_ADDR_HPMCOUNTER26      => 
        when CSR_ADDR_HPMCOUNTER27      => 
        when CSR_ADDR_HPMCOUNTER28      => 
        when CSR_ADDR_HPMCOUNTER29      => 
        when CSR_ADDR_HPMCOUNTER30      => 
        when CSR_ADDR_HPMCOUNTER31       => 
        when CSR_ADDR_SSTATUS       => 
        when CSR_ADDR_SEDELEG       => 
        when CSR_ADDR_SIDELEG       => 
        when CSR_ADDR_SIE       => 
        when CSR_ADDR_STVEC       => 
        when CSR_ADDR_SCOUNTEREN       => 
        when CSR_ADDR_SSCRATCH       => 
        when CSR_ADDR_SEPC       => 
        when CSR_ADDR_SCAUSE       => 
        when CSR_ADDR_STVAL       => 
        when CSR_ADDR_SIP       => 
        when CSR_ADDR_SATP       => 
        when CSR_ADDR_MVENDORID       => 
        when CSR_ADDR_MARCHID       => 
        when CSR_ADDR_MIMPID       => 
        when CSR_ADDR_MHARTID       => 
        when CSR_ADDR_MSTATUS       => 
        when CSR_ADDR_MISA       => 
        when CSR_ADDR_MEDELEG       => 
        when CSR_ADDR_MIDELEG       => 
        when CSR_ADDR_MIE       => 
        when CSR_ADDR_MTVEC       => 
        when CSR_ADDR_MCOUNTEREN       => 
        when CSR_ADDR_MSCRATCH       => 
        when CSR_ADDR_MEPC       => 
        when CSR_ADDR_MCAUSE       => 
        when CSR_ADDR_MTVAL       => 
        when CSR_ADDR_MIP       => 
        when CSR_ADDR_MCYCLE       => 
        when CSR_ADDR_MINSTRET       => 
        when CSR_ADDR_MHPMCOUNTER3       => 
        when CSR_ADDR_MHPMCOUNTER4       => 
        when CSR_ADDR_MHPMCOUNTER5       => 
        when CSR_ADDR_MHPMCOUNTER6       => 
        when CSR_ADDR_MHPMCOUNTER7       => 
        when CSR_ADDR_MHPMCOUNTER8       => 
        when CSR_ADDR_MHPMCOUNTER9       => 
        when CSR_ADDR_MHPMCOUNTER10       => 
        when CSR_ADDR_MHPMCOUNTER11       => 
        when CSR_ADDR_MHPMCOUNTER12       => 
        when CSR_ADDR_MHPMCOUNTER13       => 
        when CSR_ADDR_MHPMCOUNTER14       => 
        when CSR_ADDR_MHPMCOUNTER15       => 
        when CSR_ADDR_MHPMCOUNTER16       => 
        when CSR_ADDR_MHPMCOUNTER17       => 
        when CSR_ADDR_MHPMCOUNTER18       => 
        when CSR_ADDR_MHPMCOUNTER19       => 
        when CSR_ADDR_MHPMCOUNTER20       => 
        when CSR_ADDR_MHPMCOUNTER21       => 
        when CSR_ADDR_MHPMCOUNTER22       => 
        when CSR_ADDR_MHPMCOUNTER23       => 
        when CSR_ADDR_MHPMCOUNTER24       => 
        when CSR_ADDR_MHPMCOUNTER25       => 
        when CSR_ADDR_MHPMCOUNTER26       => 
        when CSR_ADDR_MHPMCOUNTER27       => 
        when CSR_ADDR_MHPMCOUNTER28       => 
        when CSR_ADDR_MHPMCOUNTER29       => 
        when CSR_ADDR_MHPMCOUNTER30       => 
        when CSR_ADDR_MHPMCOUNTER31       => 
        when CSR_ADDR_MHPMEVENT3       => 
        when CSR_ADDR_MHPMEVENT4       => 
        when CSR_ADDR_MHPMEVENT5       => 
        when CSR_ADDR_MHPMEVENT6       => 
        when CSR_ADDR_MHPMEVENT7       => 
        when CSR_ADDR_MHPMEVENT8       => 
        when CSR_ADDR_MHPMEVENT9       => 
        when CSR_ADDR_MHPMEVENT10       => 
        when CSR_ADDR_MHPMEVENT11       => 
        when CSR_ADDR_MHPMEVENT12       => 
        when CSR_ADDR_MHPMEVENT13       => 
        when CSR_ADDR_MHPMEVENT14       => 
        when CSR_ADDR_MHPMEVENT15       => 
        when CSR_ADDR_MHPMEVENT16       => 
        when CSR_ADDR_MHPMEVENT17       => 
        when CSR_ADDR_MHPMEVENT18       => 
        when CSR_ADDR_MHPMEVENT19       => 
        when CSR_ADDR_MHPMEVENT20       => 
        when CSR_ADDR_MHPMEVENT21       => 
        when CSR_ADDR_MHPMEVENT22       => 
        when CSR_ADDR_MHPMEVENT23       => 
        when CSR_ADDR_MHPMEVENT24       => 
        when CSR_ADDR_MHPMEVENT25       => 
        when CSR_ADDR_MHPMEVENT26       => 
        when CSR_ADDR_MHPMEVENT27       => 
        when CSR_ADDR_MHPMEVENT28       => 
        when CSR_ADDR_MHPMEVENT29       => 
        when CSR_ADDR_MHPMEVENT30       => 
        when CSR_ADDR_MHPMEVENT31       => 
          when others                 =>
            -- All others not implemented, set trap
            -- TODO set bad instruction exception
        
    end case;
end; -- CSR_write procedure



-- Handle complicated CSR write behaviors
-- @param CSR_bits - The 12 bit CSR address per the specification
-- @param value - The write value
-- @param mode - What mode we encountered this instruction in
-- Notes: need to pass handle to CSR in because procedures are not allowed to modify signals without an explicit handle
procedure CSR_write(CSR_bits: in std_logic_vector(11 downto 0); value: in doubleword; CSR: inout CSR_t; mode: in std_logic_vector(1 downto 0)) is
begin

    -- TODO add checks for mode
    -- TODO handle mode fails and offending instruction logging
    case CSR_bits is
        when CSR_ADDR_FFLAGS        =>
            if(CSR(CSR_MSTATUS)(14 downto 13) = "00") then
                -- Error, no FP unit
                -- TODO flip bad instruction exception bit
            else
                CSR(CSR_MSTATUS)(14 downto 13) := "11"; -- Set FP dirty bits
                CSR(CSR_MSTATUS)( 63 ) := '1'; -- Set flag indicating dirty bits
                CSR(CSR_FCSR)(4 downto 0) := value(4 downto 0); -- Set FP flags passed in                 
            end if; 
        when CSR_ADDR_FRM           => 
            if(CSR(CSR_MSTATUS)(14 downto 13) = "00") then
                -- Error, no FP unit
                -- TODO flip bad instruction exception bit
            else
                CSR(CSR_MSTATUS)(14 downto 13) := "11"; -- Set FP dirty bits
                CSR(CSR_MSTATUS)( 63 ) := '1'; -- Set flag indicating dirty bits
                CSR(CSR_FCSR)(7 downto 5) := value(2 downto 0); -- Set FP rounging mode passed in                 
            end if;
        when CSR_ADDR_FCSR          => 
            if(CSR(CSR_MSTATUS)(14 downto 13) = "00") then
            -- Error, no FP unit
            -- TODO flip bad instruction exception bit
            else
                CSR(CSR_MSTATUS)(14 downto 13) := "11"; -- Set FP dirty bits
                CSR(CSR_MSTATUS)( 63 ) := '1'; -- Set flag indicating dirty bits
                CSR(CSR_FCSR)(7 downto 0) := value(7 downto 0); -- Set FP rounging mode and flags passed in                 
            end if;
        when CSR_ADDR_SSTATUS       => 
            CSR(CSR_MSTATUS)( 18 ) := value(18); -- Update Smode portion of MSTATUS
            CSR(CSR_MSTATUS)( 16 downto 15 ) := value(16 downto 15);
            CSR(CSR_MSTATUS)( 14 downto 13 ) := value(14 downto 13);
            CSR(CSR_MSTATUS)( 8 ) := value(8);
            CSR(CSR_MSTATUS)( 5 ) := value(5);
            CSR(CSR_MSTATUS)( 1 ) := value(1);
        when CSR_ADDR_SIE           => -- Update Smode interrupts to and of MIE and delegations 
            CSR(CSR_MIE)( 12 ) := value(12) and CSR(CSR_MIDELEG)( 12 );
            CSR(CSR_MIE)( 9 ) := value(9) and CSR(CSR_MIDELEG)( 9 );
            CSR(CSR_MIE)( 7 ) := value(7) and CSR(CSR_MIDELEG)( 7 );
            CSR(CSR_MIE)( 5 ) := value(5) and CSR(CSR_MIDELEG)( 5 );
            CSR(CSR_MIE)( 3 ) := value(3) and CSR(CSR_MIDELEG)( 3 );
            CSR(CSR_MIE)( 1 ) := value(1) and CSR(CSR_MIDELEG)( 1 );
        when CSR_ADDR_STVEC         =>  -- update STVec to the shifted address in 63:2
            CSR(CSR_STVEC)(63 downto 2) := value(63 downto 2);            
        when CSR_ADDR_SCOUNTEREN    => 
            CSR( CSR_SCOUNTEREN ) := value; -- Pass through new enbale value 
        when CSR_ADDR_SSCRATCH      =>  
            CSR( CSR_SSCRATCH ) := value; -- Pass through new scratch value
        when CSR_ADDR_SEPC          => 
            CSR( CSR_SEPC ) := value; -- Pass through new scratch value
        when CSR_ADDR_SCAUSE        => 
            CSR( CSR_SCAUSE ) := value; -- Pass through new scratch value
        when CSR_ADDR_STVAL         => 
            CSR( CSR_STVAL ) := value; -- Pass through new scratch value
        when CSR_ADDR_SIP           => 
            CSR(CSR_MIP)( 1 ) := value(1) and CSR(CSR_MIDELEG)( 1 ); -- Pass through new scratch value
        when CSR_ADDR_SATP          => 
            if(CSR(CSR_MSTATUS)(20) = '1') then
                -- TODO set bad instruction exception
            elsif( (value(63 downto 60) = "0000") or
                   (value(63 downto 60) = "1000") or
                   (value(63 downto 60) = "1001") ) then
                -- This won't actually do anything, since we aren't implementing address translations for Smode
                CSR(CSR_SATP)(63 downto 60) := value(63 downto 60);
                CSR(CSR_SATP)(43 downto 0) := value(43 downto 0);                
            end if;
        when CSR_ADDR_MSTATUS       => 
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
        when CSR_ADDR_MISA          => -- Do nothing
        when CSR_ADDR_MEDELEG       => -- Update delegation of synchronous exceptions
            CSR( CSR_MEDELEG ) := value;
        when CSR_ADDR_MIDELEG       => -- Update delegation of aynschronous exceptions
            CSR(CSR_MIDELEG)( 12 ) := value(12);
            CSR(CSR_MIDELEG)( 9 ) := value(9);
            CSR(CSR_MIDELEG)( 5 ) := value(5);
            CSR(CSR_MIDELEG)( 1 ) := value(1);
        when CSR_ADDR_MIE           => -- Update enabled exceptions 
            CSR(CSR_MIE)( 12 ) := value(12);
            CSR(CSR_MIE)( 9 ) := value(9);
            CSR(CSR_MIE)( 7 ) := value(7);
            CSR(CSR_MIE)( 5 ) := value(5);
            CSR(CSR_MIE)( 3 ) := value(3);
            CSR(CSR_MIE)( 1 ) := value(1);
        when CSR_ADDR_MTVEC         => -- Update shifted base address for machine mode trap handler
            -- Note: bit 1 is reserved because reasons
            CSR(CSR_MTVEC)(63 downto 2) := value(63 downto 2);
            CSR(CSR_MTVEC)( 0 ) := value(0); 
        when CSR_ADDR_MCOUNTEREN    => -- Pass through new counter enable bit
            CSR( CSR_MCOUNTEREN ) := value;            
        when CSR_ADDR_MSCRATCH      =>  -- Pass through new scratch value
            CSR( CSR_MSCRATCH ) := value;            
        when CSR_ADDR_MEPC          =>  -- Pass through new exception PC
            CSR( CSR_MEPC ) := value;            
        when CSR_ADDR_MCAUSE        =>  -- Pass through new exception cause
            CSR( CSR_MCAUSE ) := value;            
        when CSR_ADDR_MTVAL         =>  -- Pass through address of the bad address for relevant interrupts (store/load misaligned, page fault)
            CSR( CSR_MTVAL ) := value;            
        when CSR_ADDR_MIP           => -- Allow Smode timer and software interrupts to be signalled
            CSR(CSR_MIP)( 5 ) := value(5);
            CSR(CSR_MIP)( 1 ) := value(1);
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
            -- TODO set bad isntruction exception
        
    end case;
end; -- CSR_write procedure


begin

-- Advance state
update_state: process(clk,rst)
begin
    if(rising_edge(clk)) then
        if('1' = rst) then
            curr_state <= setup;
        else
            curr_state <= next_state;
        end if;
    end if;

end process;

-- Compute outputs
update_signals: process(curr_state)
    -- CSR temporary 
    variable tempVal: doubleword;
    variable CSRVal: doubleword;
    variable CSR_bits: std_logic_vector(11 downto 0) := instr(31 downto 20);
begin
    -- default outputs
    next_state <= curr_state;
    
    -- adjust next state and outputs
    case curr_state is
        when setup => -- Bootloader code
            -- Reset CSR
            -- CSR <= (others => (zero_word & zero_word));
        when teardown => -- Maybe superflous
        when waiting =>
            case waiting_reason is
                when "000" => -- Waiting on MMU instruction
                    if('1' = instruction_ready) then
                        -- Resume normal mode
                        next_state <= normal;
                    end if;
                when "001" => -- Waiting on MMU to clear WB (store instructions)
                    if('1' = writeback_ack) then
                        next_state <= normal;
                    end if;
                when "010" => -- Waiting on mulhsu (one cycle)
                    -- always go back to normal, stalled one cycle
                    next_state <= normal;
                when "011" => -- Waiting on MMU load data
                    if('1' = MMU_load_complete) then
                        next_state <= normal;
                    end if;
                when others => -- Waiting for interrupt (special state when no work exists)
            end case;
        when exception => -- Interrupt to take
            -- Determine which of supervisor/machine interrupt vector to use
            -- Switch in exception address and perform jump
            -- return to normal mode to execute handler instructions
            next_state <= normal;
        when others => -- Normal operation
            -- Determine the appropriate pipeline for the active instruction
            case instr_code is
                -- Handle privileged instructions here
                when instr_FENCE =>
                    -- NOT IMPLEMENTED - fence memory and I/O
                when instr_FENCEI =>
                    -- NOT IMPLEMENTED - fence instruction stream
                when instr_ECALL =>
                    -- Raise environment call exception
                    -- TODO implement me
                when instr_EBREAK =>
                    -- NOT IMPLEMENTED - raise breakpoint exception
                when instr_CSRRW =>
                    -- CSR read and then write
                    -- Write the value of the CSR to x[rd], then set the CSR to x[rs1]
                    RegFile_raddr <= x"0"; -- rs1 address
                    tempVal := RegFile_rdata;
                    CSRVal := CSR(to_integer(unsigned(CSR_bits)));
                    RegFile_waddr <= x"0";
                    RegFile_wdata <= CSR_read(to_integer(unsigned(CSR_bits)), CSRVal);
                    
                when instr_CSRRS =>
                    -- CSR read and set
                    -- Write the value fo the CSR to x[rd], then overwrite the CSR to the OR of the CSR value and the value of x[rs1]
                    -- TODO implement me
                when instr_CSRRC =>
                    -- CSR read and clear
                    -- Write the value of the CSR to x[rd], get the contents of x[rs1], flip all its bits, and overwrite the CSR with the AND of its contents and the result.
                    -- Less insane explanation: CSR = CSR & ~x[rs1], The bits set in x[rs1] are the bits to clear in the CSR contents.
                    -- TODO implement me
                when instr_CSRRWI =>
                    -- CSR read and then write immediate
                    -- Write the value of the CSR to x[rd], then set the CSR to the zero-extended immediate value.
                    -- TODO implement me
                when instr_CSRRSI =>
                    -- CSR read and set immediate
                    -- Write the value of the CSR to x[rd], then overwrite the CSR to the OR of the CSR value and the (zero-extended) immediate value
                    -- TODO implement me
                when instr_CSRRCI =>
                    -- CSR Read and clear immediate
                    -- Write the value of the CSR to x[rd], zero extend the immediate value, flip all its bits, and overwrite the CSR with the AND of its contents and the result.
                    -- Less insane explanation: The immediate value represents which of the 5 LSBs of the CSR should be set to zero.  So zimm = "00100" means clear bit 2. 
                    -- TODO implement me
                when others =>
            end case;
            next_state <= normal;
    end case;
end process;

end Behavioral;
