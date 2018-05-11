----------------------------------------------------------------------------------
-- Engineer: Longofono
-- 
-- Create Date: 02/04/2018 04:12:40 PM
-- Module Name: exception - Behavioral
-- Description: Helper module determines if in an exception state 
-- 
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library config;
use work.config.all;

entity exception is
    Port(
        mip:                in doubleword; -- Machine interrupts pending CSR
        mie:                in doubleword; -- Machine interrupts enabled CSR
        mstatus:            in doubleword; -- Machine mode status CSR
        sip:                in doubleword; -- Supervisor interrupts pending CSR
        sie:                in doubleword; -- Supervisor interrupts enabled CSR
        sstatus:            in doubleword; -- Supervisor mod status CSR
        mdeleg:             in doubleword; -- Mask for supervisor delegated Exceptions
        m_enable_interrupts:in std_logic;  -- Global machine interrupt enabled
        s_enable_interrupts:in std_logic;  -- Global supervisor interrupt enabled
        interrupt_m:        out std_logic; -- Take interrupt machine mode
        interrupt_s:        out std_logic  -- Take interrupt supervisor mode
    );
end exception;

architecture Behavioral of exception is
signal s_interrupt_m: std_logic; -- Machine mode output
signal s_interrupt_s: std_logic; -- Supervisor mode output
begin

process(mip,mie,sip,sie)
    variable ival_m: doubleword;  -- Machine mode value
    variable ival_s: doubleword;  -- Supervisor mode value
begin
    if('1' = m_enable_interrupts) then
        ival_m := mip and mie and (not mdeleg);
        if(unsigned(ival_m) > 0) then
            s_interrupt_m <= '1';
        else
            s_interrupt_m <= '0';
        end if;
    end if;
    if('1' = s_enable_interrupts) then
        ival_s := sip and sie and mdeleg;
        if(unsigned(ival_m) > 0) then
            s_interrupt_m <= '1';
        else
            s_interrupt_m <= '0';
        end if;
    end if;
end process;

interrupt_m <= s_interrupt_m;
interrupt_s <= s_interrupt_s;

end Behavioral;
