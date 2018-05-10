library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity stub_ram is
    Port ( 
           address : in STD_LOGIC_VECTOR (13 downto 0);
           clock : in STD_LOGIC;
           we : in STD_LOGIC;
           dataIn : in STD_LOGIC_VECTOR (7 downto 0);
           dataOut : out STD_LOGIC_VECTOR (7 downto 0));
end stub_ram;

architecture Behavioral of stub_ram is
    type RAM is array ( ( 16 * 1024 ) - 1 downto 0 ) of std_logic_vector( 7 downto 0 );
    
    signal sys_RAM : RAM := (   
                                others => ( others => '0')
                            );
    
    signal read_address : std_logic_vector( 13 downto 0 );
begin

    process ( clock )
    begin
        if ( rising_edge( clock ) ) then
            if( we = '1' ) then
                sys_RAM( to_integer( unsigned( address ))) <= dataIn;
            end if;
            
            read_address <= address;
        end if;
    end process;

    dataOut <= sys_RAM( to_integer( unsigned( read_address )));
end Behavioral;
