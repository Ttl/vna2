----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.02.2017 11:46:15
-- Design Name: 
-- Module Name: spi3 - Behavioral
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

entity spi3 is
    Generic (SPI_CLK_DIVIDER : integer := 1);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           lo_data_in : in STD_LOGIC_VECTOR (31 downto 0);
           source_data_in : in STD_LOGIC_VECTOR (31 downto 0);
           att_data_in : in STD_LOGIC_VECTOR (7 downto 0);
           lo_write : in STD_LOGIC;
           source_write : in STD_LOGIC;
           att_write : in STD_LOGIC;
           busy : out STD_LOGIC;
           spi_clk : out STD_LOGIC;
           spi_data_lo : out STD_LOGIC;
           spi_data_source : out STD_LOGIC;
           spi_data_att : out STD_LOGIC;
           spi_le_lo : out STD_LOGIC;
           spi_le_source : out STD_LOGIC;
           spi_le_att : out STD_LOGIC;
           source_ack : out STD_LOGIC;
           lo_ack : out STD_LOGIC;
           att_ack : out STD_LOGIC);
end spi3;

architecture Behavioral of spi3 is

signal lo_reg, source_reg : std_logic_vector(31 downto 0) := (others => '0');
signal att_reg : std_logic_vector(7 downto 0) := (others => '0');
signal spi_clk_int : std_logic := '0';
signal spi_clk_en : std_logic := '0';
signal spi_le_lo_int, spi_le_source_int, spi_le_att_int : std_logic := '1';

signal lo_write_buffer, source_write_buffer, att_write_buffer : std_logic := '0';

constant LE_LENGTHEN : integer := 10;
constant NEXT_DELAY : integer := 50;

-- LE lengthen
signal pipe_source, pipe_lo, pipe_att : std_logic_vector(LE_LENGTHEN-1 downto 0) := (others => '0');


begin



spi_clk_process : process(clk, rst, lo_data_in, source_data_in, att_data_in, lo_write, source_write, att_write)
variable count : unsigned(7 downto 0) := to_unsigned(0, 8);
variable lo_bits, source_bits, att_bits : unsigned(5 downto 0) := to_unsigned(0, 6);
variable lo_bits_prev, source_bits_prev, att_bits_prev : unsigned(5 downto 0) := to_unsigned(0, 6);

variable source_data_in_buffer, lo_data_in_buffer : std_logic_vector(31 downto 0);
variable att_data_in_buffer : std_logic_vector(7 downto 0);

variable lo_done, source_done, att_done : std_logic := '1';

variable source_delay, lo_delay, att_delay : unsigned(7 downto 0) := to_unsigned(0, 8);

begin
if rst = '1' then
    count := to_unsigned(0, 8);
elsif rising_edge(clk) then
    -- Default LE values
    spi_le_lo_int <= '0';
    spi_le_source_int <= '0';
    spi_le_att_int <= '0';
    lo_ack <= '0';
    source_ack <= '0';
    att_ack <= '0';
    
    if source_delay /= to_unsigned(0, 8) then
        source_delay := source_delay - 1;
    end if;
    
    if lo_delay /= to_unsigned(0, 8) then
        lo_delay := lo_delay - 1;
    end if;
    
    if att_delay /= to_unsigned(0, 8) then
        att_delay := att_delay - 1;
    end if;

    -- Buffer write requests
    -- Write must begin on correct SPI clock phase
    if lo_write = '1' and lo_done = '1' and lo_delay = to_unsigned(0, 8) then
        lo_data_in_buffer := lo_data_in;
        lo_write_buffer <= '1';
        lo_ack <= '1';
    end if;
    
    if source_write = '1' and source_done = '1' and source_delay = to_unsigned(0, 8) then
        source_data_in_buffer := source_data_in;
        source_write_buffer <= '1';
        source_ack <= '1';
    end if;
    
    if att_write = '1' and att_done = '1' and att_delay = to_unsigned(0, 8) then
        att_data_in_buffer := att_data_in;
        att_write_buffer <= '1';
        att_ack <= '1';
    end if;
    
    if lo_done = '1' and source_done = '1' and att_done = '1' then
        spi_clk_en <= '0';
    else
        spi_clk_en <= '1';
    end if;

    if count = SPI_CLK_DIVIDER then
        count := to_unsigned(0, 8);
        if spi_clk_en = '1' then
            spi_clk_int <= not spi_clk_int;
        else
            spi_clk_int <= '0';
        end if;
        
        if spi_clk_int = '1' then
            
            -- Shift new bit
            if lo_write_buffer = '0' then
                lo_reg <= lo_reg(30 downto 0)&'0';
            end if;
            
            if source_write_buffer = '0' then
                source_reg <= source_reg(30 downto 0)&'0';
            end if;
            
            if att_write_buffer = '0' then
                att_reg <= att_reg(6 downto 0)&'0';
            end if;
                    
            lo_bits_prev := lo_bits;
            source_bits_prev := source_bits;
            att_bits_prev := att_bits;
            
            if lo_bits /= to_unsigned(0, 6) then
                lo_bits := lo_bits - to_unsigned(1, 6);
            end if;
             
            if source_bits /= to_unsigned(0, 6) then
                source_bits := source_bits - to_unsigned(1, 6);
            end if;
             
            if att_bits /= to_unsigned(0, 6) then
                att_bits := att_bits - to_unsigned(1, 6);
            end if;
            
             if lo_bits_prev = to_unsigned(1, 5) and lo_bits = to_unsigned(0, 5) then
                 spi_le_lo_int <= '1';
                 lo_done := '1';
                 lo_delay := to_unsigned(NEXT_DELAY, 8);
             end if;
 
             if source_bits_prev = to_unsigned(1, 5) and source_bits = to_unsigned(0, 5) then
                  spi_le_source_int <= '1';
                  source_done := '1';
                  source_delay := to_unsigned(NEXT_DELAY, 8);
             end if;
  
             if att_bits_prev = to_unsigned(1, 5) and att_bits = to_unsigned(0, 5) then
                  spi_le_att_int <= '1';
                  att_done := '1';
                  att_delay := to_unsigned(NEXT_DELAY, 8);
             end if;
             
          end if;
          
                  
          -- Start a new write on falling SPI clock edge
          if spi_clk_en = '0' or (spi_clk_en = '1' and spi_clk_int = '1') then
              
              if lo_write_buffer = '1' then
                  lo_write_buffer <= '0';
                  lo_bits := to_unsigned(32, 6);
                  lo_reg <= lo_data_in_buffer;
                  lo_done := '0';
              end if;
              
              if source_write_buffer = '1' then
                  source_write_buffer <= '0';
                  source_bits := to_unsigned(32, 6);
                  source_reg <= source_data_in_buffer;
                  source_done := '0';
              end if;
              
              if att_write_buffer = '1' then
                  att_write_buffer <= '0';
                  att_bits := to_unsigned(8, 6);
                  att_reg <= att_data_in_buffer;
                  att_done := '0';
              end if;
              
          end if;
          
    else
        count := count + to_unsigned(1, 8);
    end if;
    
end if;
end process;

busy <= spi_clk_en;

spi_clk <= spi_clk_int;

spi_data_lo <= lo_reg(31);
spi_data_source <= source_reg(31);
spi_data_att <= att_reg(7);

-- Lengthen the LE pulse
le_process : process(clk, spi_le_lo_int, spi_le_source_int, spi_le_att_int, pipe_lo, pipe_source, pipe_att)

variable le_lo_or, le_source_or, le_att_or : std_logic := '0';
begin
if rising_edge(clk) then

    pipe_source(0) <= spi_le_source_int;
    pipe_lo(0) <= spi_le_lo_int;
    pipe_att(0) <= spi_le_att_int;
    le_lo_or := '0';
    le_source_or := '0';
    le_att_or := '0';
    
    for i in 1 to LE_LENGTHEN-1 loop
        pipe_source(i) <= pipe_source(i-1);
        pipe_lo(i) <= pipe_lo(i-1);
        pipe_att(i) <= pipe_att(i-1);
        
        le_lo_or := le_lo_or or pipe_lo(i);
        le_source_or := le_source_or or pipe_source(i);
        le_att_or := le_att_or or pipe_att(i);
    end loop;
    
    spi_le_lo <= le_lo_or;
    spi_le_source <= le_source_or;
    spi_le_att <= le_att_or;
    
end if;
end process;

end Behavioral;
