----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2016 10:07:32
-- Design Name: 
-- Module Name: mixer - Behavioral
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

entity mixer is
    Generic (
        RF_WIDTH : integer := 14;
        LO_WIDTH : integer := 16;
        IF_WIDTH : integer := 16
    );
    Port ( clk : in std_logic;
           rf : in STD_LOGIC_VECTOR (RF_WIDTH-1 downto 0);
           lo : in STD_LOGIC_VECTOR (LO_WIDTH-1 downto 0);
           if_out : out STD_LOGIC_VECTOR (IF_WIDTH-1 downto 0));
end mixer;

architecture Behavioral of mixer is

constant level : integer := 2;

type pipeline_type is array (level-1 downto 0) of std_logic_vector(RF_WIDTH+LO_WIDTH-1 downto 0);
signal pipe : pipeline_type := (others => (others => '0'));

signal a : std_logic_vector(RF_WIDTH-1 downto 0) := (others => '0');
signal b : std_logic_vector(LO_WIDTH-1 downto 0) := (others => '0');
signal non_rounded, rounded : std_logic_vector(IF_WIDTH-1 downto 0) := (others => '0');

begin

process(clk, rf, lo)
variable m : std_logic_vector(RF_WIDTH+LO_WIDTH-1 downto 0);
begin
    if rising_edge(clk) then
        a <= rf;
        b <= lo;
        m := std_logic_vector(signed(a)*signed(b));
        pipe(0) <= m;
        for i in 1 to level-1 loop
            pipe(i) <= pipe(i-1);
        end loop;
    end if;
end process;

round_towards_zero : process(clk, pipe)
variable pipe_if : std_logic_vector(IF_WIDTH-1 downto 0);
begin
    if rising_edge(clk) then
        pipe_if := pipe(level-1)(RF_WIDTH+LO_WIDTH-1 downto RF_WIDTH+LO_WIDTH-IF_WIDTH);
        non_rounded <= pipe_if;
        rounded <= std_logic_vector(signed(pipe_if) + 1);
    end if;
end process;

if_out <= rounded when non_rounded(IF_WIDTH-1) = '1' else non_rounded;
 
end Behavioral;
