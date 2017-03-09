----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2016 20:14:33
-- Design Name: 
-- Module Name: receiver_tb - Behavioral
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
use std.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity receiver_tb is
--  Port ( );
end receiver_tb;

architecture Behavioral of receiver_tb is

signal clk, rst, rst_adc, start : std_logic := '0';
signal adc : std_logic_vector(ADC_WIDTH-1 downto 0) := (others => '0');
signal i_acc, q_acc, cycles : std_logic_vector(IQ_ACC_WIDTH-1 downto 0) := (others => '0');

signal sample_time : std_logic_vector(31 downto 0) := (others => '0');
signal sample_time_valid : std_logic := '0';

-- Clock period definitions
constant clk_period : time := 10 ns;

signal i, q : Real := 0.0;
signal i_int, q_int : integer;

begin

--adc_source : entity work.lo
--    Generic map(
--        BIT_WIDTH => ADC_WIDTH,
--        TABLE_SIZE => 5,
--        TABLE_WIDTH => 3,
--        COS => false
--        )
--    Port map( 
--           rst => rst,
--           clk => clk,
--           lo_out => adc
--);

file_adc : entity work.file_adc
    Generic map (in_file => "/home/henrik/koodi/vna2/software/samples_no_signal.txt")
    Port map ( clk => clk,
           rst => rst,
           adc_out => adc);

rx : entity work.receiver
    Port map ( clk => clk,
           rst => rst,
           adc => adc,
           i_acc => i_acc,
           q_acc => q_acc,
           cycles => cycles,
           start => start,
           if_output => open,
           cic_output => open,
           cic_valid => open);
           

rx_control : entity work.receiver_control
   Port map( clk => clk,
          rst => rst,
          start_early => open,
          start => start,
          sample_time => sample_time,
          sample_time_valid => sample_time_valid);

rst_process :process
begin
--    rst <= '1';
--     rst_adc <= '1';
--     wait for 2*clk_period;
--     rst_adc <= '0';
--     rst <= '0';
    wait for 1000*clk_period;
    report "I:" & real'image(i);
    report "Q:" & real'image(q);
end process;
   
-- Clock process definitions
clk_process :process
begin
    clk <= '1';
    wait for clk_period/2;
    clk <= '0';
    wait for clk_period/2;
end process;

iq_divide : process(clk)
begin
    if rising_edge(clk) then
        i <= Real(to_integer(signed(i_acc)))/(to_integer(unsigned(cycles)))/Real(32768000);
        q <= Real(to_integer(signed(q_acc)))/(to_integer(unsigned(cycles)))/Real(32768000);
    end if;
end process;

iq_int : process(clk)
begin
    if rising_edge(clk) then
        i_int <= integer(i*Real(327680));
        q_int <= integer(q*Real(327680));
    end if;
end process;

--write process
writing : process
    file      outfile  : text is out "receiver_tb_out.txt";  --declare output file
    variable  outline  : line;   --line number declaration  
begin
wait until clk = '0' and clk'event;

--write(linenumber,value(real type),justified(side),field(width),digits(natural));
write(outline, integer'image(to_integer(signed(i_acc)))&", "&integer'image(to_integer(signed(q_acc)))&", "&integer'image(to_integer(unsigned(cycles))));
-- write line to external file.
writeline(outfile, outline);

end process writing;
    
end Behavioral;
