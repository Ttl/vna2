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
           si_wu : out STD_LOGIC;
           last_byte : in STD_LOGIC);
end comm;

architecture Behavioral of comm is

constant WRITE_WR_LENGTH : integer := 4; -- Clock cycles
constant READ_RD_LENGTH : integer := 4; -- Clock cycles
constant SI_WU_DELAY : integer := 2; -- Clock cycles
constant SI_WU_LENGTH : integer := 4; -- Clock cycles

signal reading : std_logic := '0';

signal ft2232_data_write : STD_LOGIC_VECTOR(7 downto 0) := (others => '1');

signal data_out_int : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

signal rxf_sync, txe_sync : std_logic := '1';

signal last_byte_int : std_logic := '0';
signal si_wu_out : std_logic := '1';

signal si_wu_pipe : std_logic_vector(SI_WU_DELAY - 1 downto 0) := (others => '1');
signal si_wu_lengthen : std_logic_vector(SI_WU_LENGTH - 1 downto 0) := (others => '1');

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

process(clk, rst, data_out_ack, txe_sync, rxf_sync)
type ft_state_type is (S_START, S_TX_WR, S_TX_HOLD, S_RX_RD, S_RX_READ, S_RX_SEND, S_RX_WAIT);
variable state : ft_state_type := S_START;
variable pulse_count : unsigned(4 downto 0) := to_unsigned(0, 5);
begin

if rst = '1' then
    ft2232_data_write <= (others => '1');
    state := S_START;
    pulse_count := to_unsigned(0, 5);
    wr <= '1';
    data_in_ack <= '0';
elsif rising_edge(clk) then
    -- Default values
    wr <= '1';
    rd <= '1';
    si_wu_out <= '1';
    
    data_in_ack <= '0';
    
    ft2232_data_write <= (others => '1');

    if (state = S_TX_WR or state = S_TX_HOLD) then
        reading <= '0';
    else
        reading <= '1';
    end if;
    
    case state is
    
        when S_START =>
            -- Priorize reading
            if rxf_sync = '0' then
                state := S_RX_RD;
                rd <= '0';
                pulse_count := to_unsigned(READ_RD_LENGTH, 5);
            elsif data_in_valid = '1' and txe_sync = '0' then
                state := S_TX_WR;
                wr <= '1';
                ft2232_data_write <= data_in;
                last_byte_int <= last_byte;
                pulse_count := to_unsigned(WRITE_WR_LENGTH, 5);
            end if;
    
        when S_TX_WR =>
            -- Holds WR signal high
            ft2232_data_write <= data_in;
            if pulse_count = to_unsigned(0, 5) then
                state := S_TX_HOLD;
                wr <= '0'; -- Strobe WR to signal a write
                pulse_count := to_unsigned(WRITE_WR_LENGTH, 5);
            else
                pulse_count := pulse_count - 1;
            end if;
            
        when S_TX_HOLD =>
            -- Wait for TXE to rise
            wr <= '0';
            ft2232_data_write <= data_in;
            if txe_sync = '1' then
                data_in_ack <= '1';
                state := S_START;
                si_wu_out <= not last_byte_int;
            end if;
            
        when S_RX_RD =>
            -- Holds RD signal low
            rd <= '0';
            if pulse_count = to_unsigned(0, 5) then
                state := S_RX_READ;
            else
                pulse_count := pulse_count - 1;
            end if;
            
        when S_RX_READ =>
            -- Read the data
            rd <= '1';
            data_out_int <= ft2232_data;
            data_out_valid <= '1';
            state := S_RX_SEND;
        
        when S_RX_SEND =>
            rd <= '1';
            data_out_valid <= '1';
            if data_out_ack = '1' then
                data_out_valid <= '0';
                state := S_RX_WAIT;
                pulse_count := to_unsigned(READ_RD_LENGTH, 5);
            end if;
            
        when S_RX_WAIT =>
            if rxf_sync = '1'  or pulse_count = to_unsigned(0, 5) then
                state := S_START;
            else
                pulse_count := pulse_count - 1;
            end if;
        
        when others =>
           state := S_START;
        
    end case;
end if;

end process;

si_wu_process : process(clk, si_wu_out)

variable si_wu_and : std_logic := '1';
begin

if rising_edge(clk) then

si_wu_pipe(0) <= si_wu_out;
si_wu_lengthen(0) <= si_wu_pipe(SI_WU_DELAY - 1);
for i in 1 to SI_WU_DELAY-1 loop
    si_wu_pipe(i) <= si_wu_pipe(i-1);
end loop;

si_wu_and := si_wu_lengthen(0);
for i in 1 to SI_WU_LENGTH-1 loop
    si_wu_lengthen(i) <= si_wu_lengthen(i-1);
    si_wu_and := si_wu_and and si_wu_lengthen(i);
end loop;

end if;

si_wu <= si_wu_and;

end process;

data_out <= data_out_int;

ft2232_data <= (others => 'Z') when reading = '1' else ft2232_data_write;

end Behavioral;
