----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.01.2017 21:00:45
-- Design Name: 
-- Module Name: pwr_sync_gen - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pwr_sync_gen is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           sync1 : out STD_LOGIC);
end pwr_sync_gen;

architecture Behavioral of pwr_sync_gen is

begin

pwr_sync_process : process(clk)
variable count : unsigned(7 downto 0) := to_unsigned(0, 8);
begin

end process;

end Behavioral;
