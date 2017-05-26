----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.11.2016 20:46:04
-- Design Name: 
-- Module Name: io_bank - Behavioral
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

entity io_bank is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_valid : in STD_LOGIC;
           data_in_ack : out STD_LOGIC;
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           data_out_valid : out STD_LOGIC;
           data_out_ack : in STD_LOGIC;
           rx_sample_time : out STD_LOGIC_VECTOR(31 downto 0);
           rx_sample_time_valid : out STD_LOGIC;
           tx_filter : out STD_LOGIC_VECTOR(3 downto 0);
           port_sw : out STD_LOGIC_VECTOR (1 downto 0);
           rx_sw : out STD_LOGIC_VECTOR (5 downto 0);
           rx_sw_mux_ctrl : out STD_LOGIC;
           lo_spi_data : out STD_LOGIC_VECTOR(31 downto 0);
           lo_spi_write : out std_logic;
           source_spi_data : out STD_LOGIC_VECTOR(31 downto 0);
           source_spi_write : out STD_LOGIC;
           atten_spi_data : out STD_LOGIC_VECTOR(7 downto 0);
           atten_spi_write : out STD_LOGIC;
           amp_pwdn : out STD_LOGIC;
           mixer_enable : out STD_LOGIC;
           lo_ce : out STD_LOGIC;
           source_ce : out STD_LOGIC;
           led : out STD_LOGIC;
           adc_shdn : out STD_LOGIC;
           adc_oe : out STD_LOGIC;
           source_rf_enable : out STD_LOGIC;
           lo_rf_enable : out STD_LOGIC;
           tx_mux_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
           dither_rst : out STD_LOGIC;
           sample_mux_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
           lo_spi_ack : in STD_LOGIC;
           source_spi_ack : in STD_LOGIC;
           att_spi_ack : in STD_LOGIC;
           iq_tag_out : out STD_LOGIC_VECTOR(7 downto 0);
           iq_tag_valid : out STD_LOGIC);
end io_bank;

architecture Behavioral of io_bank is

constant MAX_PACKET_LENGTH : integer := 8;

type memory_type is array (0 to MAX_PACKET_LENGTH-1) of std_logic_vector(7 downto 0);
signal memory : memory_type := (others => (others => '0'));
signal port_sw_int: std_logic_vector(1 downto 0) := "00";
signal tx_filter_int : std_logic_vector(3 downto 0) := "0000";
signal rx_sw_int : std_logic_vector(5 downto 0) := "000000";
signal amp_pwdn_int, mixer_enable_int, led_int : std_logic := '0';
signal adc_oe_int, adc_shdn_int : std_logic := '1';
signal source_rf_enable_int, lo_rf_enable_int : std_logic := '0';
signal lo_ce_int, source_ce_int : std_logic := '0';
signal rx_sample_time_int :  std_logic_vector(31 downto 0) := (others => '0');
signal rx_sample_time_valid_int : std_logic := '0';
signal tx_mux_ctrl_int : std_logic_vector(1 downto 0) := "00";
signal dither_rst_int : std_logic := '0';
signal sample_mux_ctrl_int : std_logic_vector(1 downto 0) := "00";
signal rx_sw_mux_ctrl_int : std_logic := '0';
signal iq_tag_out_int :  std_logic_vector(7 downto 0) := (others => '0');

signal valid_prev : std_logic := '0';

signal write_word : std_logic_vector(7 downto 0);
signal new_write, writing : std_logic := '0';



begin

process(clk, rst, data_in, data_valid, data_out_ack)

type comm_state_type is (S_START, S_LENGTH, S_ID, S_DATA, S_PROCESS_DATA);
variable state : comm_state_type := S_START;
variable data_length : unsigned(7 downto 0) := to_unsigned(0, 8);
variable data_counter : unsigned(7 downto 0) := to_unsigned(0, 8);
variable ready : std_logic := '1';
variable data_id : unsigned(7 downto 0) := to_unsigned(0, 8);

begin

if rst = '1' then
    state := S_START;
    data_length := to_unsigned(0, 8);
    ready := '1';
    data_id := to_unsigned(0, 8);
    valid_prev <= '0';
    amp_pwdn_int <= '0';
    mixer_enable_int <= '0';
    led_int <= '0';
    tx_filter_int <= (others => '0');
    adc_oe_int <= '1';
    adc_shdn_int <= '1';
    source_rf_enable_int <= '0';
    lo_rf_enable_int <= '0';
elsif rising_edge(clk) then
    lo_spi_write <= '0';
    source_spi_write <= '0';
    atten_spi_write <= '0';
    data_in_ack <= '0';
    rx_sample_time_valid_int <= '0';
    valid_prev <= '0';
    new_write <= '0';
    iq_tag_valid <= '0';
    
    if new_write = '1' then
        data_out <= write_word;
        data_out_valid <= '1';
        writing <= '1';
    elsif writing = '1' then
        data_out_valid <= '1';
        if data_out_ack = '1' then
            writing <= '0';
            data_out_valid <= '0';
        end if;
    else
        data_out_valid <= '0';
    end if;

    -- data_valid is high for 2 clock cycles, so we need to make
    -- sure that data is loaded only at first cycle with valid_prev signal
    if ready = '1' and data_valid = '1' and valid_prev = '0' then
        data_in_ack <= '1';
        valid_prev <= '1';
        
        case state is 
            when S_START =>
                if data_in = COMM_START then
                    state := S_LENGTH;
                end if;
                
            when S_LENGTH =>
                data_length := unsigned(data_in);
                data_counter := to_unsigned(0, 8);
                state := S_ID;
                
            when S_ID =>
                data_id := unsigned(data_in);
                state := S_DATA;
                
            when S_DATA =>
                memory(to_integer(data_counter)) <= data_in;
                
                if data_counter /= MAX_PACKET_LENGTH-1 then
                    data_counter := data_counter + 1;
                end if;
                            
                if data_counter = data_length then
                    state := S_PROCESS_DATA;
                    ready := '0';
                end if;
                
            when others =>
                state := S_START;
                
        end case;
    elsif ready = '0' then
    
        case state is 
        
            when S_PROCESS_DATA =>
                -- Do the stuff
                
                case data_id is
                    
                    when to_unsigned(0, 8) =>
                        -- Invalid
                        ready := '1';
                        state := S_START;
                        
                    when to_unsigned(1, 8) =>
                        if data_length = to_unsigned(2, 8) then
                            tx_filter_int <= memory(0)(3 downto 0);
                            port_sw_int <= memory(0)(5 downto 4);
                            
                            rx_sw_int <= memory(1)(5 downto 0);
                            rx_sw_mux_ctrl_int <= memory(1)(6);
                        end if;
                        ready := '1';
                        state := S_START;
                        
                    when to_unsigned(2, 8) =>
                         if data_length = to_unsigned(1, 8) then
                            amp_pwdn_int <= memory(0)(0);
                            mixer_enable_int <= memory(0)(1);
                            led_int <= memory(0)(2);
                            adc_oe_int <= memory(0)(3);
                            adc_shdn_int <= memory(0)(4);
                        end if;
                        ready := '1';
                        state := S_START;
                        
                    when to_unsigned(3, 8) =>
                        if data_length = to_unsigned(4, 8) then
                            lo_spi_data <= memory(0)&memory(1)&memory(2)&memory(3);
                            lo_spi_write <= '1';
                        else
                            ready := '1';
                            state := S_START;
                        end if;
                        if lo_spi_ack = '1' then
                            ready := '1';
                            state := S_START;
                        end if;
                           
                    when to_unsigned(4, 8) =>
                        if data_length = to_unsigned(4, 8) then
                            source_spi_data <= memory(0)&memory(1)&memory(2)&memory(3);
                            source_spi_write <= '1';
                        else
                            ready := '1';
                            state := S_START;
                        end if;
                        if source_spi_ack = '1' then
                            ready := '1';
                            state := S_START;
                        end if;
                        
                    when to_unsigned(5, 8) =>
                        if data_length = to_unsigned(4, 8) then
                            rx_sample_time_int <= memory(0)&memory(1)&memory(2)&memory(3);
                            rx_sample_time_valid_int <= '1';
                        end if;
                        ready := '1';
                        state := S_START;
                        
                     when to_unsigned(6, 8) =>
                        if data_length = to_unsigned(1, 8) then
                            atten_spi_data <= memory(0);
                            atten_spi_write <= '1';
                        else
                            ready := '1';
                            state := S_START;
                        end if;
                        if att_spi_ack = '1' then
                            ready := '1';
                            state := S_START;
                        end if;
                        
                     when to_unsigned(7, 8) =>
                         if data_length = to_unsigned(1, 8) then
                            lo_ce_int <= memory(0)(0);
                            source_ce_int <= memory(0)(1);
                            source_rf_enable_int <= memory(0)(2);
                            lo_rf_enable_int <= memory(0)(3);
                        end if;
                        ready := '1';
                        state := S_START;
                       
                    when to_unsigned(8, 8) =>
                         if data_length = to_unsigned(1, 8) then
                            tx_mux_ctrl_int <= memory(0)(1 downto 0);
                            sample_mux_ctrl_int <= memory(0)(3 downto 2);
                        end if;
                        ready := '1';
                        state := S_START;
                        
                    when to_unsigned(9, 8) =>
                         if data_length = to_unsigned(1, 8) then
                            dither_rst_int <= memory(0)(0);
                        end if;
                        ready := '1';
                        state := S_START;
                        
                    when to_unsigned(10, 8) =>
                        if writing = '0' then
                            new_write <= '1';
                            write_word <= memory(0);
                        end if;
                        ready := '1';
                        state := S_START;
                        
                    when to_unsigned(11, 8) =>
                        iq_tag_out_int <= memory(0);
                        iq_tag_valid <= '1';
                        ready := '1';
                        state := S_START;
                                                         
                    when others =>
                        ready := '1';
                        state := S_START;
                        
                end case;
                
            when others =>
                -- Shouldn't be here
                state := S_START;
                ready := '1';
                
        end case;

    end if;

end if;
end process;

tx_filter <= tx_filter_int;
port_sw <= port_sw_int;
rx_sw <= rx_sw_int;
amp_pwdn <= amp_pwdn_int;
mixer_enable <= mixer_enable_int;
led <= led_int;
adc_oe <= adc_oe_int;
adc_shdn <= adc_shdn_int;
source_rf_enable <= source_rf_enable_int;
lo_rf_enable <= lo_rf_enable_int;
lo_ce <= lo_ce_int;
source_ce <= source_ce_int;
rx_sample_time <= rx_sample_time_int;
rx_sample_time_valid <= rx_sample_time_valid_int;
tx_mux_ctrl <= tx_mux_ctrl_int;
dither_rst <= dither_rst_int;
sample_mux_ctrl <= sample_mux_ctrl_int;
rx_sw_mux_ctrl <= rx_sw_mux_ctrl_int;
iq_tag_out <= iq_tag_out_int;

end Behavioral;
