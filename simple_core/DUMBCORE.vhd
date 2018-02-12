----------------------------------------------------------------------------------
-- Engineer: Longofono
-- 
-- Create Date: 02/10/2018 06:05:22 PM
-- Module Name: DUMBCORE - Behavioral
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

entity DUMBCORE is
  Port(
    clk: in std_logic;  -- Tied to switch V10
    rst: in std_logic   -- Tied to switch J15
  );
end DUMBCORE;

architecture Behavioral of DUMBCORE is

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
signal s_sext_12: doubleword;                            -- Sign extended immediate value
signal s_sext_20: doubleword;                            -- Sign extended immediate value

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

end Behavioral;
