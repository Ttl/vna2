----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.12.2016 21:22:37
-- Design Name: 
-- Module Name: ft2232_rx - Behavioral
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

entity ft2232_rx is
    Port ( data : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           rxf : out STD_LOGIC;
           txe : out STD_LOGIC;
           rd : out STD_LOGIC;
           wr : in STD_LOGIC;
           si_wu : in STD_LOGIC);
end ft2232_rx;

architecture Behavioral of ft2232_rx is

begin

rxf <= '1';
rd <= '1';

write_process : process
begin
     txe <= '0';
     wait until wr = '0';
     wait for 25 ns;
     txe <= '1';
     data_out <= data;
     wait for 200 ns;
end process;

end Behavioral;
