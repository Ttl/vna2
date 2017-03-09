----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.02.2017 21:18:56
-- Design Name: 
-- Module Name: file_adc - Behavioral
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
use std.textio.all;  --include package textio.vhd
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity file_adc is
    Generic (in_file : string := "samples.txt");
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           adc_out : out STD_LOGIC_VECTOR (13 downto 0));
end file_adc;

architecture Behavioral of file_adc is

constant DEPTH : integer := 5000;

subtype word_t  is std_logic_vector(13 downto 0);
type    ram_t   is array(0 to DEPTH-1) of word_t;

-- Read a *.hex file
impure function ocram_ReadMemFile(FileName : STRING) return ram_t is
  file   infile    : text is in FileName;
  variable  inline    : line; --line number declaration
  variable  dataread1    : integer;
  variable Result       : ram_t    := (others => (others => '0'));

begin
  for i in 0 to DEPTH - 1 loop
    exit when endfile(infile);

    readline(infile, inline);
    read(inline, dataread1);
    Result(i)    := std_logic_vector(to_signed(dataread1, 14));
  end loop;

  return Result;
end function;

signal ram : ram_t    := ocram_ReadMemFile(in_file);
signal pointer : integer := 0;

begin

process(clk, rst)

begin
if rst = '1' then
    pointer <= 0;
elsif rising_edge(clk) then
    if pointer < DEPTH - 1 then
        pointer <= pointer + 1;
    else
        pointer <= 0;
    end if;
end if;
end process;

adc_out <= ram(pointer);

end Behavioral;
