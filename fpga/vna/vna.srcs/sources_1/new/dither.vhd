library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dither is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           q : out STD_LOGIC);
end dither;

architecture Behavioral of dither is

constant OUT_WIDTH : integer := 8;

component lfsr is 
generic ( SEED : STD_LOGIC_VECTOR(30 downto 0);
             OUT_WIDTH : integer);
port(
    clk : in  STD_LOGIC;
    q : out  STD_LOGIC_VECTOR (OUT_WIDTH-1 downto 0);
    rst : in  STD_LOGIC);
end component;

signal uniform1 : std_logic_vector(OUT_WIDTH-1 downto 0);

begin

unif1: lfsr 
generic map (SEED => std_logic_vector(to_unsigned(697757461,31)),
                 OUT_WIDTH => OUT_WIDTH)
port map(
    clk => clk,
    q => uniform1,
    rst => rst
);

q <= uniform1(0);

end Behavioral;
