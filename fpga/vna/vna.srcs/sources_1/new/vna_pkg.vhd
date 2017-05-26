library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package vna_pkg is 

type rx_sw_type is (SW_NONE, SW_RX1, SW_A, SW_RX2, SW_B);

subtype byte is std_logic_vector(7 downto 0);

constant ADC_WIDTH : natural := 14;
constant IF_WIDTH : natural := 24;
constant LO_WIDTH : integer := 14;
constant IQ_ACC_WIDTH : natural := 56;
constant CIC_OUT_WIDTH : natural := 32;

constant IQ_BYTES : natural := IQ_ACC_WIDTH/8;

constant COMM_START : std_logic_vector(7 downto 0) := "10101010";

-- Number of clock cycles to skip after reset
-- Determined by the switch settling time
constant SKIP_SAMPLES : integer := 30;

constant AGC_TARGET : integer := 200;

constant LOCK_CYCLES : integer := 12000;

end vna_pkg;

package body vna_pkg is
end vna_pkg;
