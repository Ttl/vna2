----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.02.2017 15:57:28
-- Design Name: 
-- Module Name: lfsr - Behavioral
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

entity lfsr is
    generic ( SEED : STD_LOGIC_VECTOR(30 downto 0):= (others => '0');
             OUT_WIDTH : integer := 11);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           q : out STD_LOGIC_VECTOR (OUT_WIDTH-1 downto 0));
end lfsr;

architecture Behavioral of lfsr is

signal rand : std_logic_vector(30 downto 0) := SEED;
signal feedback : std_logic;

begin

feedback <= not((rand(0) xor rand(3)));

process(clk,rst)
begin
if rst = '1' then
    rand <= SEED;
elsif rising_edge(clk) then
    rand <= feedback&rand(30 downto 1);
end if;
end process;

q <= rand(OUT_WIDTH-1 downto 0);

end Behavioral;