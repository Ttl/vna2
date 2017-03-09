----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2016 18:43:45
-- Design Name: 
-- Module Name: rx_switch - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rx_switch is
--  Port ( );
end rx_switch;

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2016 15:33:21
-- Design Name: 
-- Module Name: port_switch - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.vna_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rx_switch is
    Port ( rx_port : in rx_port_type;
           term : in STD_LOGIC;
           swa_ctrl : out STD_LOGIC_VECTOR (1 downto 0);
           swb_ctrl : out STD_LOGIC_VECTOR (1 downto 0);
           swc_ctrl : out STD_LOGIC_VECTOR (1 downto 0));
end rx_switch;

architecture Behavioral of rx_switch is

begin

process(rx_port, term)
begin

if term = '1' then
    swa_ctrl <= "00";
    swb_ctrl <= "00";
    swc_ctrl <= "00";
else
    if rx_port = P_A then
        swa_ctrl <= "10";
        swb_ctrl <= "10";
        swc_ctrl <= "01";
    else
        swa_ctrl <= "01";
        swb_ctrl <= "01";
        swc_ctrl <= "10";
    end if;
end if;

end process;

end Behavioral;