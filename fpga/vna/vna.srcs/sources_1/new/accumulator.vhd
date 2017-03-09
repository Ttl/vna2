----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2016 19:47:49
-- Design Name: 
-- Module Name: average - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity accumulator is
    Generic (
    IN_WIDTH : integer := 14;
    OUT_WIDTH : integer := 32
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           valid : in STD_LOGIC;
           data : in STD_LOGIC_VECTOR (IN_WIDTH-1 downto 0);
           average : out STD_LOGIC_VECTOR (OUT_WIDTH-1 downto 0));
end accumulator;

architecture Behavioral of accumulator is

signal accum : signed(OUT_WIDTH-1 downto 0) := to_signed(0, OUT_WIDTH);

begin

process(clk, rst, valid, data)
begin

if rst = '1' then
    accum <= to_signed(0, OUT_WIDTH);
elsif rising_edge(clk) then
    average <= std_logic_vector(accum);
    if valid = '1' then
        accum <= accum + signed(data);
    end if;
end if;

end process;

end Behavioral;
