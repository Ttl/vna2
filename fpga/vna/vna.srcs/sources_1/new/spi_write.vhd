----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.12.2016 18:06:25
-- Design Name: 
-- Module Name: spi_write - Behavioral
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

entity spi_write is
    Generic (SPI_CLK_DIVIDER : integer := 1;
             DATA_LENGTH : integer := 8);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           spi_clk : out STD_LOGIC;
           spi_data : out STD_LOGIC;
           spi_cs : out STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR (DATA_LENGTH-1 downto 0);
           data_in_valid : in STD_LOGIC;
           data_in_ack : out STD_LOGIC);
end spi_write;

architecture Behavioral of spi_write is

constant SPI_CLOCK : unsigned(7 downto 0) := to_unsigned(SPI_CLK_DIVIDER, 8);
signal spi_clk_int : std_logic := '0';

begin

write_process : process(clk, rst, data_in, data_in_valid)
variable bit_counter : unsigned(7 downto 0) := to_unsigned(DATA_LENGTH-1, 8);
variable clk_counter : unsigned(7 downto 0) := to_unsigned(0, 8);
variable done : std_logic := '0';
type spi_state is (S_START, S_CS, S_WRITE);
variable state : spi_state := S_START;
variable data_in_valid_prev : std_logic := '0';
begin

if rst = '1' then
    bit_counter := to_unsigned(DATA_LENGTH-1, 8);
    spi_cs <= '1';
    spi_clk_int <= '0';
    data_in_ack <= '0';
    spi_data <= '0';
    done := '0';
    state := S_START;
    data_in_valid_prev := '0';
elsif rising_edge(clk) then
    data_in_ack <= '0';
    done := '0';
    
    case state is
    
        when S_START =>
            bit_counter := to_unsigned(DATA_LENGTH-1, 8);
            if data_in_valid = '1' then
                spi_cs <= '0';
                state := S_CS;
                spi_data <= data_in(to_integer(unsigned(bit_counter)));
            end if;
    
        when S_WRITE =>
            if data_in_valid = '1' then
                spi_cs <= '0';
                spi_data <= data_in(to_integer(unsigned(bit_counter)));
                if clk_counter = to_unsigned(SPI_CLK_DIVIDER, 8) then
                    if spi_clk_int = '0' then
                        if bit_counter = to_unsigned(0, 8) then
                            data_in_ack <= '1';
                            spi_cs <= '1';
                            done := '1';
                            state := S_START;
                        else
                            bit_counter := bit_counter - 1;
                        end if;
                    end if;
                    if done = '0' then
                        spi_clk_int <= not spi_clk_int;
                    end if;
                else
                    clk_counter := clk_counter + 1;
                end if;
            else
                spi_cs <= '1';
                bit_counter := to_unsigned(DATA_LENGTH-1, 8);
            end if;
            
        when S_CS =>
            -- Hold CS for one clock
            spi_cs <= '0';
            spi_data <= data_in(to_integer(unsigned(bit_counter)));
            state := S_WRITE;
        
        when others =>
            state := S_START;
            
    end case;
end if;

end process;

spi_clk <= spi_clk_int;
end Behavioral;
