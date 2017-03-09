----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.12.2016 20:52:12
-- Design Name: 
-- Module Name: io_bank_tb - Behavioral
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

entity io_bank_tb is
--  Port ( );
end io_bank_tb;

architecture Behavioral of io_bank_tb is

signal clk, rst : std_logic := '0';
-- Clock period definitions
constant clk_period : time := 25 ns;

signal ft2232_data, data_out, data_in : std_logic_vector(7 downto 0) := (others => '0');
signal data_in_valid : std_logic := '0';
signal data_out_valid : std_logic;
signal data_in_ack, data_out_ack : std_logic := '0';
signal rxf, txe, rd, wr, si_wu : std_logic := '0';

signal io_data_out : std_logic_vector(7 downto 0);
signal io_data_out_valid, io_data_out_ack : std_logic := '0';
signal tx_filter, port_sw, rx_sw : std_logic_vector(1 downto 0);
signal port_sw_term, rx_term : std_logic;

signal lo_spi_data : STD_LOGIC_VECTOR(31 downto 0);
signal lo_spi_write : std_logic;
signal source_spi_data : STD_LOGIC_VECTOR(31 downto 0);
signal source_spi_write : std_logic;

constant TEST_DATA_LENGTH : integer := 11;
type test_data_type is array(TEST_DATA_LENGTH-1 downto 0) of std_logic_vector(7 downto 0);
signal test_data : test_data_type := (
0 => COMM_START,
1 => "00000001", -- Set switches
2 => "00000001",
3 => "11111111",
4 => COMM_START,
5 => "00000100", -- Set LO
6 => "00000011",
7 => "11111111",
8 => "10101010",
9 => "01010101",
10 => "00000000"
);

begin

comm : entity work.comm
    Port map ( clk => clk,
           rst => rst,
           ft2232_data => ft2232_data,
           data_in_valid => data_in_valid,
           data_out => data_out,
           data_out_valid => data_out_valid,
           data_in => data_in,
           data_in_ack => data_in_ack,
           data_out_ack => data_out_ack,
           rxf => rxf,
           txe => txe,
           rd => rd,
           wr => wr,
           si_wu => si_wu);
           
io_bank : entity work.io_bank
    Port map ( clk => clk,
           rst => rst,
           data_in => data_out,
           data_valid => data_out_valid,
           data_in_ack => data_out_ack,
           data_out => io_data_out,
           data_out_valid => io_data_out_valid,
           data_out_ack => io_data_out_ack,
           tx_filter => tx_filter,
           port_sw => port_sw,
           rx_sw => rx_sw,
           lo_spi_data => lo_spi_data,
           lo_spi_write => lo_spi_write,
           source_spi_data => source_spi_data,
           source_spi_write => source_spi_write,
           led => open);

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
   

    read_process : process
    variable i : integer := 0;
    begin
         if i = TEST_DATA_LENGTH then
            report "End of data";
            wait;
         end if;
         rxf <= '1';
         wait for 10*clk_period;
         rxf <= '0';
         wait until rd = '0';
         wait for 50 ns;
         ft2232_data <= test_data(i);
         wait until rd = '1';
         ft2232_data <= "ZZZZZZZZ";
         wait for 25 ns;
         rxf <= '1';
         wait for 10*clk_period;
         assert data_out = test_data(i) severity failure;
         i := i + 1;
    end process;

end Behavioral;
