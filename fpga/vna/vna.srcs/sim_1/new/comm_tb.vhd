----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.12.2016 19:38:11
-- Design Name: 
-- Module Name: comm_tb - Behavioral
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

entity comm_tb is
--  Port ( );
end comm_tb;

architecture Behavioral of comm_tb is

signal clk, rst : std_logic := '0';
-- Clock period definitions
constant clk_period : time := 25 ns;

signal ft2232_data, data_out, data_in : std_logic_vector(7 downto 0) := (others => '0');
signal data_in_valid : std_logic := '0';
signal data_out_valid : std_logic;
signal data_in_ack, data_out_ack : std_logic := '0';
signal rxf, txe, rd, wr, si_wu : std_logic := '0';

signal read_done : std_logic := '0';

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
   
      -- Clock process definitions
   read_process : process
   begin
        rxf <= '1';
        wait for 10*clk_period;
        rxf <= '0';
        wait until rd = '0';
        wait for 50 ns;
        ft2232_data <= "10101010";
        wait until rd = '1';
        ft2232_data <= "ZZZZZZZZ";
        wait for 25 ns;
        rxf <= '1';
        wait for 10*clk_period;
        assert data_out = "10101010" severity failure;
        data_out_ack <= '1';
        wait for clk_period;
        data_out_ack <= '0';
        wait for clk_period;
        assert data_out_valid = '0' severity failure;
        read_done <= '1';
        report "Read done";
        wait;
   end process;
   
         -- Clock process definitions
write_process : process
begin
     wait until read_done = '1';
     data_in <= "11110000";
     data_in_valid <= '1';
     wait until wr = '0';
     wait for 25 ns;
     txe <= '1';
     assert ft2232_data = "11110000" severity failure;
     wait until data_in_ack = '1';
     data_in_valid <= '0';
     assert ft2232_data = "ZZZZZZZZ" severity failure;
     report "Write done";
     wait for 5*clk_period;
     txe <= '0';
     wait;
end process;

end Behavioral;
