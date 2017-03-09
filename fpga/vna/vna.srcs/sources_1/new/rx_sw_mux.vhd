----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.02.2017 19:01:41
-- Design Name: 
-- Module Name: rx_sw_mux - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rx_sw_mux is
    Port ( rx_sw_receiver : in rx_sw_type;
           rx_sw_io : in STD_LOGIC_VECTOR(5 downto 0);
           rx_sw : out STD_LOGIC_VECTOR(5 downto 0);
           ctrl : in STD_LOGIC);
end rx_sw_mux;

architecture Behavioral of rx_sw_mux is

signal rx_sw_receiver_vector : std_logic_vector(5 downto 0);
begin

rx_sw_receiver_vector <= "100010" when rx_sw_receiver = SW_RX1 else
                         "100001" when rx_sw_receiver = SW_A else
                         "011000" when rx_sw_receiver = SW_B else
                         "010100" when rx_sw_receiver = SW_RX2 else
                         "000000";

rx_sw <= rx_sw_io when ctrl = '1' else rx_sw_receiver_vector;

end Behavioral;
