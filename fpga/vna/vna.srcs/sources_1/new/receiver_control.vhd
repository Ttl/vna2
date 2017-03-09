----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.12.2016 20:44:41
-- Design Name: 
-- Module Name: receiver_control - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity receiver_control is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           start_early : out STD_LOGIC;
           start : out STD_LOGIC;
           sample_time : in STD_LOGIC_VECTOR (31 downto 0);
           sample_time_valid : in STD_LOGIC;
           receiver_hold : out STD_LOGIC;
           lo_ld : in STD_LOGIC;
           source_ld : in STD_LOGIC;
           rx_sw : out rx_sw_type;
           tx_ready : in STD_LOGIC);
end receiver_control;

architecture Behavioral of receiver_control is

signal sample_time_int, sample_time_int_next : STD_LOGIC_VECTOR (31 downto 0) := (15 => '1', others => '0');

signal start_int : std_logic := '0';

signal rx_sw_int : rx_sw_type := SW_RX1;

signal lo_ld_sync, source_ld_sync : std_logic := '0';

begin

sample_time_update : process(clk, sample_time, sample_time_valid)
begin
if rising_edge(clk) then
    if sample_time_valid = '1' then
        sample_time_int_next <= sample_time;
    end if;
end if;
end process;

start_generator : process(clk, rst, sample_time_int, rx_sw_int, lo_ld_sync, source_ld_sync, tx_ready)
variable counter : unsigned(31 downto 0) := to_unsigned(0, 32);
variable locked_cycles : unsigned(15 downto 0) := to_unsigned(0, 16);
begin
if rst = '1' then
    counter := to_unsigned(0, 32);
elsif rising_edge(clk) then
    start_int <= '0';
    receiver_hold <= '1';
    
    if lo_ld_sync = '0' or source_ld_sync = '0' then
        -- No lock: reset receiver
        locked_cycles := to_unsigned(0, 16);
        counter := to_unsigned(0, 32);
    end if;
    
    if locked_cycles = LOCK_CYCLES then
        receiver_hold <= '0';
        if std_logic_vector(counter) >= sample_time_int and tx_ready = '1' then
            start_int <= '1';
            counter := to_unsigned(0, 32);
            sample_time_int <= sample_time_int_next;
            
            
            -- Next receiver channel
            case rx_sw_int is
                when SW_RX1 =>
                    rx_sw_int <= SW_A;
                when SW_A =>
                    rx_sw_int <= SW_RX2;
                when SW_RX2 =>
                    rx_sw_int <= SW_B;
                when SW_B =>
                    rx_sw_int <= SW_RX1;
                when others =>
                    rx_sw_int <= SW_RX1;
            end case;
            
        else
            counter := counter + 1;
        end if;
    else
        locked_cycles := locked_cycles + to_unsigned(1, 16);
    end if;
    
end if;
end process;

late_start : process(clk, start_int)
begin
if rising_edge(clk) then
    start <= start_int;
end if;
end process;

sync_process : process(clk, lo_ld, source_ld)
variable lo_sync2, source_sync2 : std_logic := '0';
begin

if rising_edge(clk) then
    lo_ld_sync <= lo_sync2;
    source_ld_sync <= source_sync2;
    lo_sync2 := lo_ld;
    source_sync2 := source_ld;
end if;
end process;

start_early <= start_int;
rx_sw <= rx_sw_int;

end Behavioral;
