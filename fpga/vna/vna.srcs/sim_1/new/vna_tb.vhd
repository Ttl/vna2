----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2016 13:44:10
-- Design Name: 
-- Module Name: vna_tb - Behavioral
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

entity vna_tb is
--  Port ( );
end vna_tb;

architecture Behavioral of vna_tb is

component lo is
    Generic (
        BIT_WIDTH : integer;
        TABLE_SIZE : integer;
        TABLE_WIDTH : integer;
        COS : boolean
        );
    Port ( rst : in std_logic;
           clk : in STD_LOGIC;
           lo_out : out STD_LOGIC_VECTOR (BIT_WIDTH-1 downto 0));
end component;


constant LO_BIT_WIDTH : integer := 14;
constant ADC_BIT_WIDTH : integer := 14;

signal clk, rst : std_logic := '0';

signal rf : std_logic_vector(ADC_BIT_WIDTH-1 downto 0);
signal if_i_out, if_q_out : std_logic_vector(15 downto 0) := (others => '0');

-- Clock period definitions
constant clk_period : time := 10 ns;

begin

downconvert : entity work.downconvert
--    Generic map (
--        ADC_WIDTH => ADC_WIDTH,
--        IF_WIDTH => IF_WIDTH)
    Port map ( clk => clk,
           rst => rst,
           adc => rf,
           if_i_out => if_i_out,
           if_q_out => if_q_out);

adc_source : lo
    Generic map(
        BIT_WIDTH => ADC_BIT_WIDTH,
        TABLE_SIZE => 5,
        TABLE_WIDTH => 3,
        COS => true
        )
    Port map( 
           rst => rst,
           clk => clk,
           lo_out => rf
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
