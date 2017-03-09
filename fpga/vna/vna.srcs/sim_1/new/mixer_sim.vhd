----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2016 10:10:56
-- Design Name: 
-- Module Name: mixer_sim - Behavioral
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

entity mixer_sim is
--  Port ( );
end mixer_sim;

architecture Behavioral of mixer_sim is

signal clk : std_logic := '0';

signal rf : std_logic_vector(13 downto 0) := (others => '0');
signal lo : std_logic_vector(15 downto 0) := (0 => '1', others => '0');
signal if_out : std_logic_vector(15 downto 0) := (others => '0');

-- Clock period definitions
constant clk_period : time := 10 ns;

begin

mixer : entity work.mixer
    Generic map(
        RF_WIDTH => 14,
        LO_WIDTH => 16,
        IF_WIDTH => 16
        )
    Port map( clk => clk,
           rf => rf,
           lo => lo,
           if_out => if_out
);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;

   -- Clock process definitions
   rf_process :process(clk, rf)
   begin
		if rising_edge(clk) then
		  rf <= std_logic_vector(unsigned(rf)+1);
		end if;
   end process;

end Behavioral;
