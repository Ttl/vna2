----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2016 13:58:22
-- Design Name: 
-- Module Name: downconvert - Behavioral
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

entity downconvert is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           adc : in STD_LOGIC_VECTOR (ADC_WIDTH-1 downto 0);
           if_i_out : out STD_LOGIC_VECTOR (IF_WIDTH-1 downto 0);
           if_q_out : out STD_LOGIC_VECTOR (IF_WIDTH-1 downto 0));
end downconvert;

architecture Behavioral of downconvert is

signal lo_i_out, lo_q_out : std_logic_vector(LO_WIDTH-1 downto 0) := (others => '0');

begin

lo_i : entity work.lo
    Generic map(
        BIT_WIDTH => LO_WIDTH,
        TABLE_SIZE => 5,
        TABLE_WIDTH => 3,
        COS => true
        )
    Port map( 
           rst => rst,
           clk => clk,
           lo_out => lo_i_out
);

lo_q : entity work.lo
    Generic map(
        BIT_WIDTH => LO_WIDTH,
        TABLE_SIZE => 5,
        TABLE_WIDTH => 3,
        COS => false
        )
    Port map( 
           rst => rst,
           clk => clk,
           lo_out => lo_q_out
);

mixer_i : entity work.mixer
    Generic map(
        RF_WIDTH => ADC_WIDTH,
        LO_WIDTH => LO_WIDTH,
        IF_WIDTH => IF_WIDTH
        )
    Port map( clk => clk,
           rf => adc,
           lo => lo_i_out,
           if_out => if_i_out
);

mixer_q : entity work.mixer
    Generic map(
        RF_WIDTH => ADC_WIDTH,
        LO_WIDTH => LO_WIDTH,
        IF_WIDTH => IF_WIDTH
        )
    Port map( clk => clk,
           rf => adc,
           lo => lo_q_out,
           if_out => if_q_out
);

end Behavioral;
