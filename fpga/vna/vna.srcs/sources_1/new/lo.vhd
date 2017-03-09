----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2016 12:23:09
-- Design Name: 
-- Module Name: lo - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity lo is
    Generic (
        BIT_WIDTH : integer := 14;
        TABLE_SIZE : integer := 5;
        TABLE_WIDTH : integer := 3;
        COS : boolean := false
        );
    Port ( rst : in std_logic;
           clk : in STD_LOGIC;
           lo_out : out STD_LOGIC_VECTOR (BIT_WIDTH-1 downto 0));
end lo;

architecture Behavioral of lo is

type table_type is array (0 to TABLE_SIZE) of std_logic_vector(BIT_WIDTH-1 downto 0);

signal table : table_type := (
0 =>  std_logic_vector(to_signed(0, BIT_WIDTH)),
1 =>  std_logic_vector(to_signed(2531, BIT_WIDTH)),
2 =>  std_logic_vector(to_signed(4814, BIT_WIDTH)),
3 =>  std_logic_vector(to_signed(6626, BIT_WIDTH)),
4 =>  std_logic_vector(to_signed(7790, BIT_WIDTH)),
5 =>  std_logic_vector(to_signed(8191, BIT_WIDTH)),
others => (others => '0')
);

function init_i(cos : in boolean) return unsigned is
begin
    if cos then
        return to_unsigned(TABLE_SIZE, TABLE_WIDTH);
    end if;
    return to_unsigned(0, TABLE_WIDTH);
end function;

function init_dir(cos : in boolean) return std_logic is
begin
    if cos then
        return '1';
    end if;
    return '0';
end function;

signal index : unsigned(TABLE_WIDTH-1 downto 0) := init_i(COS);
signal sign: std_logic := '0';

begin

process(clk, rst)


variable direction : std_logic := init_dir(COS);
begin

if rst = '1' then
    if COS then
        index <= to_unsigned(TABLE_SIZE, TABLE_WIDTH);
        sign <= '0';
        direction := '1';
    else
        index <= to_unsigned(0, TABLE_WIDTH);
        sign <= '0';
        direction := '0';
    end if;
elsif rising_edge(clk) then
    if index = TABLE_SIZE then
        direction := '1';
    end if;
    if index = 0 then
        direction := '0';
        sign <= not sign;
    end if;

    if direction = '0' then
        index <= index+1;
    else
        index <= index-1;
    end if;
end if;

end process;

lo_out <= table(to_integer(index)) when sign = '0' else std_logic_vector(-signed(table(to_integer(index))));
    
end Behavioral;
