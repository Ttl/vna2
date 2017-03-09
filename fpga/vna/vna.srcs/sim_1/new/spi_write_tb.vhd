----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.12.2016 18:23:00
-- Design Name: 
-- Module Name: spi_write_tb - Behavioral
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

entity spi_write_tb is
--  Port ( );
end spi_write_tb;

architecture Behavioral of spi_write_tb is

constant DATA_LENGTH : integer := 16;

signal clk, rst : std_logic := '0';

signal data : std_logic_vector(DATA_LENGTH-1 downto 0) := "1010110111011110";
signal spi_clk, spi_data, spi_cs : std_logic;
signal data_ack : std_logic;
signal data_in_valid : std_logic := '0';

-- Clock period definitions
constant clk_period : time := 10 ns;

begin

spi_write : entity work.spi_write
    Generic map (SPI_CLK_DIVIDER => 2,
             DATA_LENGTH => DATA_LENGTH)
    Port map ( clk => clk,
           rst => rst,
           spi_clk => spi_clk,
           spi_data => spi_data,
           spi_cs => spi_cs,
           data_in => data,
           data_in_valid => data_in_valid,
           data_in_ack => data_ack);

   rst_process : process
   begin
		rst <= '1';
		wait for clk_period;
		rst <= '0';
		wait;
   end process;
   
   -- Clock process definitions
   clk_process : process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;

   write_process : process
   begin
        wait for 10*clk_period;
        data_in_valid <= '1';
        wait until data_ack = '1';
        data_in_valid <= '0';
   end process;
   
   assert_process : process(spi_clk)
   variable i : integer := DATA_LENGTH-1;
   begin
        if rising_edge(spi_clk) then
            assert spi_data = data(i) severity failure;
            i := i - 1;
            if i = 0 then
                i := DATA_LENGTH-1;
            end if;
        end if;
   end process;

end Behavioral;
