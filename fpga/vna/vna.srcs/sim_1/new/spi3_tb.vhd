----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.02.2017 12:24:22
-- Design Name: 
-- Module Name: spi3_tb - Behavioral
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

entity spi3_tb is
--  Port ( );
end spi3_tb;

architecture Behavioral of spi3_tb is

signal clk, rst : std_logic := '0';
-- Clock period definitions
constant clk_period : time := 25 ns;

signal lo_data_in, source_data_in : std_logic_vector(31 downto 0);
signal att_data_in : std_logic_vector(7 downto 0);
signal lo_write, source_write, att_write : std_logic := '0';
signal busy : std_logic;
signal spi_clk, spi_data_lo, spi_data_source, spi_data_att : std_logic;
signal spi_le_lo, spi_le_source, spi_le_att : std_logic;

begin

spi3 : entity work.spi3
    Generic map ( SPI_CLK_DIVIDER => 1)
    Port map ( clk => clk,
               rst => rst,
    lo_data_in => lo_data_in,
    source_data_in => source_data_in,
    att_data_in => att_data_in,
    lo_write => lo_write,
    source_write => source_write,
    att_write => att_write,
    busy => busy,
    spi_clk => spi_clk,
    spi_data_lo => spi_data_lo,
    spi_data_source => spi_data_source,
    spi_data_att => spi_data_att,
    spi_le_lo => spi_le_lo,
    spi_le_source => spi_le_source,
    spi_le_att => spi_le_att);

-- Clock process definitions
clk_process : process
begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
end process;

test_process : process
begin
    wait for 100 ns;
    wait until rising_edge(clk);
    lo_data_in <= "10101010101010101010101010101010";
    lo_write <= '1';
    wait for 2*clk_period;
    lo_write <= '0';
    wait for 5*clk_period;
    att_data_in <= "01010101";
    att_write <= '1';
    wait for 2*clk_period;
    att_write <= '0';
    wait for 5*clk_period;
    source_data_in <= "01010101010101010101010101010101";
    source_write <= '1';
    wait for 2*clk_period;
    source_write <= '0';
    wait;
end process;

end Behavioral;
