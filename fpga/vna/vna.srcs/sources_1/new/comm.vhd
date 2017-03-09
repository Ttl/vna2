----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.11.2016 20:21:11
-- Design Name: 
-- Module Name: comm - Behavioral
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

entity comm is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           ft2232_data : inout STD_LOGIC_VECTOR (7 downto 0);
           data_in_valid : in STD_LOGIC;
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           data_out_valid : out STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR(7 downto 0);
           data_in_ack : out STD_LOGIC;
           data_out_ack : in STD_LOGIC;
           rxf : in STD_LOGIC;
           txe : in STD_LOGIC;
           rd : out STD_LOGIC;
           wr : out STD_LOGIC;
           si_wu : out STD_LOGIC);
end comm;

architecture Behavioral of comm is

constant WRITE_WR_LENGTH : integer := 3; -- Clock cycles
constant READ_RD_LENGTH : integer := 3; -- Clock cycles

signal write_start : std_logic := '0';
signal write_done : std_logic := '1';
signal reading : std_logic := '0';

signal ft2232_data_write : STD_LOGIC_VECTOR(7 downto 0) := (others => '1');

signal data_out_int : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal data_out_valid_int : std_logic := '0';

signal rxf_sync, txe_sync : std_logic := '1';

begin

sync_process : process(clk, rxf, txe)
variable rxf_sync2, txe_sync2 : std_logic := '1';
begin

if rising_edge(clk) then
    txe_sync <= txe_sync2;
    rxf_sync <= rxf_sync2;
    txe_sync2 := txe;
    rxf_sync2 := rxf;
end if;
end process;

write_process : process(clk, rst, data_out_ack, txe_sync)

type ftfifo_state_type is (S_START, S_WR, S_HOLD, S_DONE);
variable write_state : ftfifo_state_type := S_START;
variable pulse_count : unsigned(4 downto 0) := to_unsigned(0, 5);
begin

if rst = '1' then
    ft2232_data_write <= (others => '1');
    write_state := S_START;
    pulse_count := to_unsigned(0, 5);
    write_done <= '1';
    wr <= '1';
    data_in_ack <= '0';
elsif rising_edge(clk) then
    wr <= '1';
    data_in_ack <= '0';
    ft2232_data_write <= (others => '1');
    
    case write_state is 
    
        when S_START =>
            write_done <= '1';
            if write_start = '1' then
                write_done <= '0';
                write_state := S_WR;
                wr <= '1';
                ft2232_data_write <= data_in;
                pulse_count := to_unsigned(WRITE_WR_LENGTH, 5);
            end if;
    
        when S_WR =>
            -- Holds WR signal high
            ft2232_data_write <= data_in;
            if pulse_count = to_unsigned(0, 5) then
                write_state := S_HOLD;
                wr <= '0'; -- Strobe WR to signal a write
            else
                pulse_count := pulse_count - 1;
            end if;
            
        when S_HOLD =>
            -- Wait for TXE to rise
            wr <= '0';
            ft2232_data_write <= data_in;
            if txe_sync = '1' then
                data_in_ack <= '1';
                write_state := S_DONE;
            end if;
            
        when S_DONE =>
            write_done <= '1';
            write_state := S_START;
        
        when others =>
            write_state := S_START;
    
    end case;

end if;

end process;

read_process : process(clk, ft2232_data, rst, data_out_ack, rxf_sync, txe_sync)

type ftfifo_state_type is (S_START, S_RD, S_READ, S_SEND, S_WAIT);
variable read_state : ftfifo_state_type := S_START;
variable pulse_count : unsigned(4 downto 0) := to_unsigned(0, 5);
begin

if rst = '1' then
    read_state := S_START;
    pulse_count := to_unsigned(0, 5);
    reading <= '0';
    data_out_valid <= '0';
    rd <= '1';
elsif rising_edge(clk) then
    data_out_valid <= '0';
    rd <= '1';
    -- Data out buffer
    data_out <= data_out_int;
    data_out_valid <= data_out_valid_int;
    reading <= '1';

    case read_state is 
    
        when S_START =>
            reading <= '0';
            if rxf_sync = '0' and write_done = '1' then
                read_state := S_RD;
                rd <= '0';  -- Strobe RD signal to read
                reading <= '1';
                pulse_count := to_unsigned(READ_RD_LENGTH, 5);
            end if;
    
        when S_RD =>
            -- Holds RD signal low
            rd <= '0';
            if pulse_count = to_unsigned(0, 5) then
                read_state := S_READ;
            else
                pulse_count := pulse_count - 1;
            end if;
            
        when S_READ =>
            -- Read the data
            rd <= '1';
            data_out_int <= ft2232_data;
            data_out_valid_int <= '1';
            read_state := S_SEND;
        
        when S_SEND =>
            rd <= '1';
            data_out_valid_int <= '1';
            if data_out_ack = '1' then
                data_out_valid_int <= '0';
                data_out_valid <= '0';
                read_state := S_WAIT;
                pulse_count := to_unsigned(READ_RD_LENGTH, 5);
            end if;
            
        when others =>
            read_state := S_START;
    
    end case;

end if;

end process;

write_read : process(clk, rst, txe_sync, data_in_valid)
begin

if rst = '1' then
    write_start <= '0';
elsif rising_edge(clk) then
    if write_done = '0' then
        write_start <= '0';
    end if;
    if reading = '0' and data_in_valid = '1' and txe_sync = '0' then
        write_start <= '1';
    end if;
end if;

end process;

si_wu <= '1';

ft2232_data <= (others => 'Z') when write_done = '1' else ft2232_data_write;

end Behavioral;
