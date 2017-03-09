----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.12.2016 20:11:24
-- Design Name: 
-- Module Name: iq_packer_tb - Behavioral
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

entity iq_packer_tb is
--  Port ( );
end iq_packer_tb;

architecture Behavioral of iq_packer_tb is

signal clk, rst : std_logic := '0';
-- Clock period definitions
constant clk_period : time := 25 ns;

signal ft2232_data, data_out, iq_data : std_logic_vector(7 downto 0) := (others => '0');
signal data_out_valid : std_logic;
signal data_in_ack, data_out_ack : std_logic := '0';
signal rxf, txe, rd, wr, si_wu : std_logic := '1';

signal start : std_logic := '0';
signal done : std_logic;
signal iq_data_valid, iq_data_ack : std_logic;
signal i_acc, q_acc, cycles : STD_LOGIC_VECTOR (IQ_ACC_WIDTH-1 downto 0) := (1 => '1', 2 => '1', 4 => '1', others => '0');

begin

iq_packer : entity work.iq_packer
    Port map ( clk => clk,
           rst => rst,
           start => start,
           done => done,
           i_acc => i_acc,
           q_acc => q_acc,
           cycles => cycles,
           data_out => iq_data,
           data_valid => iq_data_valid,
           data_ack => iq_data_ack);

comm : entity work.comm
    Port map ( clk => clk,
           rst => rst,
           ft2232_data => ft2232_data,
           data_in_valid => iq_data_valid,
           data_out => data_out,
           data_out_valid => data_out_valid,
           data_in => iq_data,
           data_in_ack => iq_data_ack,
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
                     
start_process : process
begin
    start <= '0';
    wait for 10*clk_period;
    start <= '1';
    wait for clk_period;
    start <= '0';
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
     txe <= '0';
     wait until wr = '0';
     wait for 25 ns;
     txe <= '1';
     wait for 5*clk_period;
end process;
           
end Behavioral;
