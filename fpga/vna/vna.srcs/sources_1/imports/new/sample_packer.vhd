----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.02.2017 19:54:50
-- Design Name: 
-- Module Name: sample_packer - Behavioral
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

entity sample_packer is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           start : in STD_LOGIC;
           adc_in : in STD_LOGIC_VECTOR(13 downto 0);
           if_output : in STD_LOGIC_VECTOR(IF_WIDTH-1 downto 0);
           i_acc : in STD_LOGIC_VECTOR(IQ_ACC_WIDTH-1 downto 0);
           data_out : out STD_LOGIC_VECTOR(7 downto 0);
           data_valid : out STD_LOGIC;
           data_ack : in STD_LOGIC;
           sample_mux_ctrl : in STD_LOGIC_VECTOR(1 downto 0));
end sample_packer;

architecture Behavioral of sample_packer is

constant packet_size : integer := 10003;
type memory_type is array (0 to packet_size-1) of std_logic_vector(15 downto 0);
signal packet_memory : memory_type := (0 => COMM_START&std_logic_vector(to_unsigned(packet_size-1, 8)), 1 => "0000001000000000", others => (others => '0'));
signal queue_full : std_logic := '0';
signal start_delay : std_logic := '0';

begin

process(clk, rst, adc_in, if_output, i_acc, data_ack, sample_mux_ctrl)
variable pointer : unsigned(15 downto 0) := to_unsigned(2, 16);
variable word : std_logic := '0';
variable sample_buffer : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
variable wait_start : std_logic := '0';
begin

if rising_edge(clk) then
    if wait_start = '1' then
        if start = '1' then
            wait_start := '0';
        end if;
    elsif queue_full = '0' then
        data_valid <= '0';
        packet_memory(to_integer(pointer)) <= sample_buffer;
        if pointer = packet_size-1 then
            queue_full <= '1';
            pointer := to_unsigned(0, 16);
        else
            pointer := pointer + to_unsigned(1, 16);
        end if;
    else
        if word = '0' then
            data_out <= packet_memory(to_integer(pointer))(15 downto 8);
        else
            data_out <= packet_memory(to_integer(pointer))(7 downto 0);
        end if;
        
        data_valid <= '1';
        
        if data_ack = '1' then
            if pointer = packet_size-1 then
                queue_full <= '0';
                wait_start := '1';
                data_valid <= '0';
                pointer := to_unsigned(2, 16);
            else
                if word = '0' then
                    word := '1';
                else
                    pointer := pointer + to_unsigned(1, 16);
                    word := '0';
                end if;
            end if;
        end if;
    end if;
    
    if sample_mux_ctrl = "00" then
        sample_buffer := adc_in(13)&adc_in(13)&adc_in;
    elsif sample_mux_ctrl = "01" then
        sample_buffer := if_output(23 downto 8);
    elsif sample_mux_ctrl = "10" then
        sample_buffer := i_acc(25 downto 10);
    else
        sample_buffer := (others => '0');
    end if;
end if;
end process;


end Behavioral;
