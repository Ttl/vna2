----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.12.2016 18:29:18
-- Design Name: 
-- Module Name: source_agc - Behavioral
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

entity source_agc is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           locked : in STD_LOGIC;
           target : in STD_LOGIC_VECTOR (15 downto 0);
           xadc_vp : in STD_LOGIC;
           xadc_vn : in STD_LOGIC;
           adc_result : out STD_LOGIC_VECTOR (15 downto 0);
           att_data : out STD_LOGIC_VECTOR(9 downto 0);
           att_write : out STD_LOGIC;
           set_target : in STD_LOGIC);
end source_agc;

architecture Behavioral of source_agc is

COMPONENT xadc_wiz_0
  PORT (
    di_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    daddr_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    den_in : IN STD_LOGIC;
    dwe_in : IN STD_LOGIC;
    drdy_out : OUT STD_LOGIC;
    do_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dclk_in : IN STD_LOGIC;
    reset_in : IN STD_LOGIC;
    vp_in : IN STD_LOGIC;
    vn_in : IN STD_LOGIC;
    user_temp_alarm_out : OUT STD_LOGIC;
    vccint_alarm_out : OUT STD_LOGIC;
    vccaux_alarm_out : OUT STD_LOGIC;
    ot_out : OUT STD_LOGIC;
    channel_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    eoc_out : OUT STD_LOGIC;
    alarm_out : OUT STD_LOGIC;
    eos_out : OUT STD_LOGIC;
    busy_out : OUT STD_LOGIC
  );
END COMPONENT;

signal di_in, do_out : std_logic_vector(15 downto 0);
signal daddr_in : std_logic_vector(6 downto 0);
signal den_in, dwe_in : std_logic := '0';
signal drdy_out : std_logic;
signal user_temp_alarm_out, vccint_alarm_out, vccaux_alarm_out, ot_out : std_logic;
signal channel_out : std_logic_vector(4 downto 0);
signal eoc_out, alarm_out, eos_out, busy_out : std_logic;


signal target_int : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(AGC_TARGET, 16));

begin

xadc : xadc_wiz_0
  PORT MAP (
    di_in => di_in,
    daddr_in => daddr_in,
    den_in => den_in,
    dwe_in => dwe_in,
    drdy_out => drdy_out,
    do_out => do_out,
    dclk_in => clk,
    reset_in => rst,
    vp_in => xadc_vp,
    vn_in => xadc_vn,
    user_temp_alarm_out => user_temp_alarm_out,
    vccint_alarm_out => vccint_alarm_out,
    vccaux_alarm_out => vccaux_alarm_out,
    ot_out => ot_out,
    channel_out => channel_out,
    eoc_out => eoc_out,
    alarm_out => alarm_out,
    eos_out => eos_out,
    busy_out => busy_out
  );
  
process(clk, rst, target, set_target)
begin
if rst = '1' then
    target_int <= std_logic_vector(to_unsigned(AGC_TARGET, 16));
elsif rising_edge(clk) then
    if set_target = '1' then
        target_int <= target;
    end if;
end if;
end process;

process(clk, rst)
begin
if rst = '1' then
    --
elsif rising_edge(clk) then
    -- TODO: Intelligent calculation
    if drdy_out = '1' then
        
    end if;
end if;
end process;

adc_result <= do_out;
end Behavioral;
