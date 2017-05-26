----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.02.2017 21:13:49
-- Design Name: 
-- Module Name: tx_mux - Behavioral
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

entity tx_mux is
    Port ( mux : in STD_LOGIC_VECTOR(1 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           data_valid : out STD_LOGIC;
           data_ack : in STD_LOGIC;
           samples_data :in STD_LOGIC_VECTOR (7 downto 0);
           samples_data_valid : in STD_LOGIC;
           samples_data_ack : out STD_LOGIC;
           iq_data :in STD_LOGIC_VECTOR (7 downto 0);
           iq_data_valid : in STD_LOGIC;
           iq_data_ack : out STD_LOGIC;
           io_data : in STD_LOGIC_VECTOR(7 downto 0);
           io_data_valid : in STD_LOGIC;
           io_data_ack : out STD_LOGIC;
           last_byte_iq : in STD_LOGIC;
           last_byte : out STD_LOGIC);
end tx_mux;

architecture Behavioral of tx_mux is

begin

data_out <= iq_data when mux = "00" else 
            samples_data when mux = "01"  else
            io_data;
                    
data_valid <= iq_data_valid when mux = "00" else
              samples_data_valid when mux = "01" else
              io_data_valid;
              
last_byte <= last_byte_iq when mux = "00" else '0';
              
iq_data_ack <= data_ack when mux = "00" else '0';
samples_data_ack <= data_ack when mux = "01" else '0';
io_data_ack <= data_ack when mux = "10" else '0';

end Behavioral;
