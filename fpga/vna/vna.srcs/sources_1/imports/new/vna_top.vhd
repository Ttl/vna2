----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.12.2016 10:06:15
-- Design Name: 
-- Module Name: vna_top - Behavioral
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

entity vna_top is
    Port ( clk : in STD_LOGIC;
           adc_in : in STD_LOGIC_VECTOR (13 downto 0);
           adc_of : in STD_LOGIC;
           adc_oe : out STD_LOGIC;
           adc_shdn : out STD_LOGIC;
           ft2232_data : inout STD_LOGIC_VECTOR (7 downto 0);
           rxf : in STD_LOGIC;
           txe : in STD_LOGIC;
           rd : out STD_LOGIC;
           wr : out STD_LOGIC;
           si_wu : out STD_LOGIC;
           tx_filter : out STD_LOGIC_VECTOR(3 downto 0);
           port_sw : out STD_LOGIC_VECTOR (1 downto 0);
           rx_sw : out STD_LOGIC_VECTOR (5 downto 0);
           spi_clk : out STD_LOGIC;
           lo_spi_data : out STD_LOGIC;
           lo_le : out STD_LOGIC;
           lo_ce : out STD_LOGIC;
           lo_rf_enable : out STD_LOGIC;
           lo_muxout : in STD_LOGIC;
           source_muxout : in STD_LOGIC;
           source_spi_data : out STD_LOGIC;
           source_le : out STD_LOGIC;
           source_ce : out STD_LOGIC;
           source_rf_enable : out STD_LOGIC;
           atten_spi_data : out STD_LOGIC;
           atten_le : out STD_LOGIC;
           lo_ld : in STD_LOGIC;
           source_ld : in STD_LOGIC;
           mixer_enable : out STD_LOGIC;
           amp_pwdn : out STD_LOGIC;
           dither : out STD_LOGIC;
           xadc_vp : in STD_LOGIC;
           xadc_vn : in STD_LOGIC;
           led : out STD_LOGIC);
end vna_top;

architecture Behavioral of vna_top is

signal rst : std_logic := '0';

-- Receiver
signal i_acc, q_acc, cycles : STD_LOGIC_VECTOR(IQ_ACC_WIDTH-1 downto 0);
-- Early signal comes one clock cycle before
signal rx_start, rx_start_early : std_logic := '0';

-- Receiver control
signal rx_sample_time : std_logic_vector(31 downto 0);
signal rx_sample_time_valid : std_logic;

--FT2232
signal comm_data_out, comm_data_in : std_logic_vector(7 downto 0);
signal comm_data_in_valid : std_logic := '0';
signal comm_data_out_valid : std_logic;
signal comm_data_in_ack, comm_data_out_ack : std_logic := '0';

-- IO
signal lo_data, source_data : std_logic_vector(31 downto 0);
signal atten_data : std_logic_vector(7 downto 0);
signal lo_write, source_write, atten_write : std_logic := '0';

-- IQ packer
signal iq_tx_done : std_logic;

signal tx_mux_ctrl : std_logic_vector(1 downto 0);
signal samples_data_out : std_logic_vector(7 downto 0);
signal samples_data_valid, samples_data_ack : std_logic; 
signal iq_data_out : std_logic_vector(7 downto 0);
signal iq_data_valid, iq_data_ack : std_logic; 

signal dither_rst : std_logic;
signal sample_mux_ctrl : std_logic_vector(1 downto 0);
signal if_output : std_logic_vector(IF_WIDTH-1 downto 0);

signal receiver_hold : std_logic;
signal rx_sw_select : rx_sw_type;
signal rx_sw_mux_ctrl : std_logic;
signal rx_sw_io : std_logic_vector(5 downto 0);

signal lo_spi_ack, source_spi_ack, att_spi_ack : std_logic;

signal io_data_out : std_logic_vector(7 downto 0);
signal io_data_valid, io_data_ack : std_logic; 

signal iq_tag : std_logic_vector(7 downto 0);
signal iq_tag_valid : std_logic;

signal last_byte_iq, last_byte : std_logic;

begin

receiver : entity work.receiver
    Port map ( clk => clk,
           rst => rst,
           adc => adc_in,
           i_acc => i_acc,
           q_acc => q_acc,
           cycles => cycles,
           start => rx_start,
           if_output => if_output,
           receiver_hold => receiver_hold);
           
receiver_control : entity work.receiver_control
    Port map ( clk => clk,
           rst => rst,
           start_early => rx_start_early,
           start => rx_start,
           sample_time => rx_sample_time,
           sample_time_valid => rx_sample_time_valid,
           receiver_hold => receiver_hold,
           lo_ld => lo_ld,
           source_ld => source_ld,
           rx_sw => rx_sw_select,
           tx_ready => iq_tx_done);
           
comm : entity work.comm
   Port map ( clk => clk,
          rst => rst,
          ft2232_data => ft2232_data,
          data_in_valid => comm_data_in_valid,
          data_out => comm_data_out,
          data_out_valid => comm_data_out_valid,
          data_in => comm_data_in,
          data_in_ack => comm_data_in_ack,
          data_out_ack => comm_data_out_ack,
          rxf => rxf,
          txe => txe,
          rd => rd,
          wr => wr,
          si_wu => si_wu,
          last_byte => last_byte);
          
led <= lo_ld;
          
iq_packer : entity work.iq_packer
    Port map ( clk => clk,
         rst => rst,
         start => rx_start_early,
         done => iq_tx_done,
         i_acc => i_acc,
         q_acc => q_acc,
         cycles => cycles,
         data_out => iq_data_out,
         data_valid => iq_data_valid,
         data_ack => iq_data_ack,
         rx_sw => rx_sw_select,
         iq_tag_in => iq_tag,
         iq_tag_valid => iq_tag_valid,
         last_byte => last_byte_iq);

sample_packer : entity work.sample_packer
    Port map (clk => clk,
        rst => rst,
        start => rx_start_early,
        adc_in => adc_in,
        if_output => if_output,
        i_acc => i_acc,
        data_out => samples_data_out,
        data_valid => samples_data_valid,
        data_ack => samples_data_ack,
        sample_mux_ctrl => sample_mux_ctrl);
        
tx_mux : entity work.tx_mux
    Port map (mux => tx_mux_ctrl,
        data_out => comm_data_in,
        data_valid => comm_data_in_valid,
        data_ack => comm_data_in_ack,
        samples_data => samples_data_out,
        samples_data_valid => samples_data_valid,
        samples_data_ack => samples_data_ack,
        iq_data => iq_data_out,
        iq_data_valid => iq_data_valid,
        iq_data_ack => iq_data_ack,
        io_data => io_data_out,
        io_data_valid => io_data_valid,
        io_data_ack => io_data_ack,
        last_byte_iq => last_byte_iq,
        last_byte => last_byte);
         
io_bank : entity work.io_bank
   Port map ( clk => clk,
          rst => rst,
          data_in => comm_data_out,
          data_valid => comm_data_out_valid,
          data_in_ack => comm_data_out_ack,
          data_out => io_data_out,
          data_out_valid => io_data_valid,
          data_out_ack => io_data_ack,
          rx_sample_time => rx_sample_time,
          rx_sample_time_valid => rx_sample_time_valid,
          tx_filter => tx_filter,
          port_sw => port_sw,
          rx_sw => rx_sw_io,
          rx_sw_mux_ctrl => rx_sw_mux_ctrl,
          lo_spi_data => lo_data,
          lo_spi_write => lo_write,
          source_spi_data => source_data,
          source_spi_write => source_write,
          atten_spi_data => atten_data,
          atten_spi_write => atten_write,
          amp_pwdn => amp_pwdn,
          mixer_enable => mixer_enable,
          lo_ce => lo_ce,
          source_ce => source_ce,
          led => open,
          adc_shdn => adc_shdn,
          adc_oe => adc_oe,
          source_rf_enable => source_rf_enable,
          lo_rf_enable => lo_rf_enable,
          tx_mux_ctrl => tx_mux_ctrl,
          dither_rst => dither_rst,
          sample_mux_ctrl => sample_mux_ctrl,
          lo_spi_ack => lo_spi_ack,
          source_spi_ack => source_spi_ack,
          att_spi_ack => att_spi_ack,
          iq_tag_out => iq_tag,
          iq_tag_valid => iq_tag_valid);         

rx_sw_mux : entity work.rx_sw_mux
    Port map ( rx_sw_receiver => rx_sw_select,
           rx_sw_io => rx_sw_io,
           rx_sw => rx_sw,
           ctrl => rx_sw_mux_ctrl);

spi3 : entity work.spi3
    Generic map ( SPI_CLK_DIVIDER => 5)
    Port map ( clk => clk,
               rst => rst,
            lo_data_in => lo_data,
            source_data_in => source_data,
            att_data_in => atten_data,
            lo_write => lo_write,
            source_write => source_write,
            att_write => atten_write,
            busy => open,
            spi_clk => spi_clk,
            spi_data_lo => lo_spi_data,
            spi_data_source => source_spi_data,
            spi_data_att => atten_spi_data,
            spi_le_lo => lo_le,
            spi_le_source => source_le,
            spi_le_att => atten_le,
            lo_ack => lo_spi_ack,
            source_ack => source_spi_ack,
            att_ack => att_spi_ack);

dither_generator : entity work.dither
    Port map ( clk => clk,
           rst => dither_rst,
           q => dither);


end Behavioral;
