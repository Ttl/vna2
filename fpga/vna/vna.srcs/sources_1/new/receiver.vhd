----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2016 20:03:05
-- Design Name: 
-- Module Name: receiver - Behavioral
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

entity receiver is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           adc : in STD_LOGIC_VECTOR (13 downto 0);
           i_acc : out STD_LOGIC_VECTOR(IQ_ACC_WIDTH-1 downto 0);
           q_acc : out STD_LOGIC_VECTOR(IQ_ACC_WIDTH-1 downto 0);
           cycles : out STD_LOGIC_VECTOR(IQ_ACC_WIDTH-1 downto 0);
           start : in STD_LOGIC;
           if_output : out STD_LOGIC_VECTOR(IF_WIDTH-1 downto 0);
           receiver_hold : in STD_LOGIC);
end receiver;

architecture Behavioral of receiver is

signal acc_rst : std_logic;
signal if_i, if_q : std_logic_vector(IF_WIDTH-1 downto 0);

signal acc_control_rst : std_logic;

begin

downconverter_0 : entity work.downconvert
    Port map( clk => clk,
           rst => rst,
           adc => adc,
           if_i_out => if_i,
           if_q_out => if_q);

accumulator_i : entity work.accumulator
    Generic map (
    IN_WIDTH => IF_WIDTH,
    OUT_WIDTH => IQ_ACC_WIDTH
    )
    Port map ( clk => clk,
           rst => acc_rst,
           valid => '1',
           data => if_i,
           average => i_acc
           );
           
accumulator_q : entity work.accumulator
    Generic map (
    IN_WIDTH => IF_WIDTH,
    OUT_WIDTH => IQ_ACC_WIDTH
    )
    Port map ( clk => clk,
          rst => acc_rst,
          valid => '1',
          data => if_q,
          average => q_acc
          );
          
accumulator_cycles : entity work.accumulator
              Generic map (
              IN_WIDTH => 2,
              OUT_WIDTH => IQ_ACC_WIDTH
              )
              Port map ( clk => clk,
                    rst => acc_rst,
                    valid => '1',
                    data => "01",
                    average => cycles
                    );
                    
acc_control : entity work.acc_control
    Port map ( clk => clk,
               rst => acc_control_rst,
               receiver_hold => receiver_hold,
               acc_reset => acc_rst
            );
          
acc_control_rst <= start or rst;
if_output <= if_i;

end Behavioral;
