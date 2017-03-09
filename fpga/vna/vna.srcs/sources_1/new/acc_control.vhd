----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.12.2016 18:31:48
-- Design Name: 
-- Module Name: acc_control - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity acc_control is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           acc_reset : out STD_LOGIC;
           receiver_hold : in STD_LOGIC);
end acc_control;

architecture Behavioral of acc_control is

begin


process(clk, rst)
variable i : unsigned(11 downto 0) := to_unsigned(0, 12);
begin

if rst = '1' then
    i := to_unsigned(0, 12);
    acc_reset <= '1';
elsif rising_edge(clk) then
    acc_reset <= '1';
    if i = SKIP_SAMPLES then
        acc_reset <= receiver_hold;
    else
        if receiver_hold = '0' then
            i := i + 1;
        end if;
    end if;
end if;

end process;

end Behavioral;
