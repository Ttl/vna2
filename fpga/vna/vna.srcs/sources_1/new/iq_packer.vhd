----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.12.2016 19:46:05
-- Design Name: 
-- Module Name: iq_packer - Behavioral
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

entity iq_packer is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           start : in STD_LOGIC;
           done : out STD_LOGIC;
           i_acc : in STD_LOGIC_VECTOR (IQ_ACC_WIDTH-1 downto 0);
           q_acc : in STD_LOGIC_VECTOR (IQ_ACC_WIDTH-1 downto 0);
           cycles : in STD_LOGIC_VECTOR (IQ_ACC_WIDTH-1 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           data_valid : out STD_LOGIC;
           data_ack : in STD_LOGIC;
           rx_sw : in rx_sw_type;
           iq_tag_in : in STD_LOGIC_VECTOR(7 downto 0);
           iq_tag_valid : in STD_LOGIC;
           last_byte : out STD_LOGIC);
end iq_packer;

architecture Behavioral of iq_packer is

-- Start, Length, id = 3
-- I, Q, cycles 7 bytes = 21
-- RX_SW, tag 2

constant packet_size : integer := 3+3*IQ_BYTES+2;
type memory_type is array (0 to packet_size-1) of std_logic_vector(7 downto 0);
signal packet_memory : memory_type := (0 => COMM_START, 1 => std_logic_vector(to_unsigned(packet_size-1, 8)), 2 => "00000001", others => (others => '0'));
signal queue_full : std_logic := '0';
signal start_delay : std_logic := '0';

signal iq_tag : std_logic_vector(7 downto 0) := (others => '0');

begin

queue_fill_process : process(clk, start, i_acc, q_acc, cycles, queue_full, start_delay)
variable rx_sw_delay : rx_sw_type;
variable rx_sw_write : std_logic_vector(2 downto 0);
variable sent : unsigned(7 downto 0) := to_unsigned(0, 8);
begin
if rising_edge(clk) then

    last_byte <= '0';
    if iq_tag_valid = '1' then
        packet_memory(3+3*IQ_BYTES+1) <= iq_tag_in;
    end if;
    
    data_out <= packet_memory(to_integer(sent));
    data_valid <= '0';
    
    start_delay <= start;
    -- Don't write new values if still sending the old ones
    if start = '1' and queue_full = '0' then
        for i in 0 to IQ_BYTES-1 loop
            packet_memory(3+i) <= i_acc(8*(i+1)-1 downto 8*i);
            packet_memory(3+IQ_BYTES+i) <= q_acc(8*(i+1)-1 downto 8*i);
            packet_memory(3+2*IQ_BYTES+i) <= cycles(8*(i+1)-1 downto 8*i);
        end loop;
        case rx_sw_delay is
            when SW_RX1 =>
                rx_sw_write := "001";
            when SW_A =>
                rx_sw_write := "010";
            when SW_RX2 =>
                rx_sw_write := "011";
            when SW_B =>
                rx_sw_write := "100";
            when others =>
                rx_sw_write := (others => '0');
        end case;
        packet_memory(3+3*IQ_BYTES) <= "00000"&rx_sw_write;
    end if;
    rx_sw_delay := rx_sw;
    
    if start_delay = '1' or queue_full = '1' then
        queue_full <= '1';
        data_valid <= '1';
        
        if sent = to_unsigned(packet_size-1, 8) then
            last_byte <= '1';
        end if;
        if sent = to_unsigned(packet_size-1, 8) and data_ack = '1' then
            queue_full <= '0';
            sent := to_unsigned(0, 8);
        elsif data_ack = '1' then
            sent := sent + 1;
        end if;
    end if;
    
end if;
end process;

done <= not queue_full;

end Behavioral;
