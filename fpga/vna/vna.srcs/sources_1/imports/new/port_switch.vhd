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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity port_switch is
    Port ( direction : in STD_LOGIC;
           term : in STD_LOGIC;
           swa_ctrl : out STD_LOGIC_VECTOR (1 downto 0);
           swb_ctrl : out STD_LOGIC_VECTOR (1 downto 0);
           swc_ctrl : out STD_LOGIC_VECTOR (1 downto 0));
end port_switch;

architecture Behavioral of port_switch is

begin

process(direction, term)
begin

if term = '1' then
    swa_ctrl <= "00";
    swb_ctrl <= "00";
    swc_ctrl <= "00";
else
    if direction = '1' then
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
