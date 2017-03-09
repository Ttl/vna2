----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2016 12:35:22
-- Design Name: 
-- Module Name: lo_sim - Behavioral
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

entity lo_sim is
--  Port ( );
end lo_sim;

architecture Behavioral of lo_sim is

constant BIT_WIDTH : integer := 14;

signal clk, rst : std_logic := '0';

signal lo_out : std_logic_vector(BIT_WIDTH-1 downto 0);

-- Clock period definitions
constant clk_period : time := 10 ns;

begin

lo : entity work.lo
    Generic map(
        BIT_WIDTH => BIT_WIDTH,
        TABLE_SIZE => 5,
        TABLE_WIDTH => 3,
        COS => false
        )
    Port map( 
           rst => rst,
           clk => clk,
           lo_out => lo_out
);

   rst_process :process
   begin
		rst <= '1';
		wait for clk_period;
		rst <= '0';
		wait;
   end process;
   
   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;

end Behavioral;
