----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.12.2016 21:00:18
-- Design Name: 
-- Module Name: vna_top_tb - Behavioral
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

entity vna_top_tb is
--  Port ( );
end vna_top_tb;

architecture Behavioral of vna_top_tb is

signal clk, rst : std_logic := '0';
signal adc : std_logic_vector(ADC_WIDTH-1 downto 0) := (others => '0');
signal i_acc, q_acc, cycles : std_logic_vector(IQ_ACC_WIDTH-1 downto 0) := (others => '0');

-- Clock period definitions
constant clk_period : time := 25 ns;

signal ft2232_data: std_logic_vector(7 downto 0) := (others => 'Z');
signal rxf, txe, rd, wr, si_wu : std_logic := '1';
signal led : std_logic;
signal adc_oe, adc_shdn : std_logic;
signal adc_of : std_logic := '0';

signal tx_filter : std_logic_vector(3 downto 0);
signal port_sw : std_logic_vector(1 downto 0);
signal rx_sw : std_logic_vector(5 downto 0);
signal lo_muxout, source_muxout: std_logic;

signal spi_clk, lo_spi_data, lo_le, lo_ce, lo_rf_enable : std_logic;
signal source_spi_data, source_le, source_ce, source_rf_enable : std_logic;
signal atten_spi_data, atten_le : std_logic;
signal lo_ld, source_ld : std_logic := '0';
signal mixer_enable, amp_pwdn, dither : std_logic;

signal read_data : std_logic_vector(7 downto 0);
signal new_data : std_logic := '0';
signal i_data, q_data, cycles_data : signed(8*IQ_BYTES-1 downto 0);
signal sw_data : std_logic_vector(7 downto 0);

signal read_done : std_logic := '0';

signal source_q, lo_q : std_logic_vector(31 downto 0) := (others => 'U');
signal atten_q : std_logic_vector(7 downto 0) := (others => 'U');

constant TEST_DATA_LENGTH : integer := 39;
type test_data_type is array(TEST_DATA_LENGTH-1 downto 0) of std_logic_vector(7 downto 0);
signal test_data : test_data_type := (
--0 => COMM_START,
--1 => "00000100", -- Write Source
--2 => "00000100",
--3 => "11111111",
--4 => "00000000",
--5 => "10101010",
--6 => "00110011",
--7 => COMM_START,
--8 => "00000100", -- Write Source
--9 => "00000100",
--10 => "11111111",
--11 => "00000000",
--12 => "10101010",
--13 => "00110011",
--14 => COMM_START,
--15 => "00000100", -- Write Source
--16 => "00000100",
--17 => "11111111",
--18 => "00000000",
--19 => "10101010",
--20 => "00110011",
--21 => COMM_START,
--22 => "00000100", -- Write LO
--23 => "00000011",
--24 => "11111111",
--25 => "00000000",
--26 => "10101010",
--27 => "00110011",
--28 => COMM_START,
--29 => "00000100", -- Write LO
--30 => "00000011",
--31 => "11111111",
--32 => "00000000",
--33 => "10101010",
--34 => "00110011",
--35 => COMM_START, -- Echo
--36 => "00000001",
--37 => "00001010",
--38 => "11111111",
--39 => COMM_START,
--40 => "00000001",
--41 => "00001000",
--42 => "00000000",

--others => (others => 'U')

0 => COMM_START,
1 => "00000010", -- Set switches
2 => "00000001",
3 => "11111111",
4 => "00111111",
5 => COMM_START,
6 => "00000001", -- Set IO
7 => "00000010",
8 => "11111111",
9 => COMM_START,
10 => "00000100", -- Write Source
11 => "00000100",
12 => "11111111",
13 => "00000000",
14 => "10101010",
15 => "00110011",
16 => COMM_START,
17 => "00000001", -- Write Atten
18 => "00000110",
19 => "10101010",
20 => COMM_START,
21 => "00000001", -- Write Atten again
22 => "00000110",
23 => "10101010",
24 => COMM_START,
25 => "00000001", -- Write PLL IO
26 => "00000111",
27 => "00001111",
28 => COMM_START,
29 => "00000100", -- Write sample time
30 => "00000101",
31 => "00000000",
32 => "00000000",
33 => "00010000",
34 => "00000000",
35 => COMM_START,
36 => "00000001", -- Write tag
37 => "00001011",
38 => "00001010",
others => (others => 'U')
);

begin

adc_source : entity work.lo
    Generic map(
        BIT_WIDTH => ADC_WIDTH,
        TABLE_SIZE => 5,
        TABLE_WIDTH => 3,
        COS => false
        )
    Port map( 
           rst => rst,
           clk => clk,
           lo_out => adc
);

vna_top : entity work.vna_top
    Port map ( clk => clk,
           adc_in => adc,
           adc_of => adc_of,
           adc_oe => adc_oe,
           adc_shdn => adc_shdn,
           ft2232_data => ft2232_data,
           rxf => rxf,
           txe => txe,
           rd => rd,
           wr => wr,
           si_wu => si_wu,
           tx_filter => tx_filter,
           port_sw => port_sw,
           rx_sw => rx_sw,
           spi_clk => spi_clk,
           lo_spi_data => lo_spi_data,
           lo_le => lo_le,
           lo_ce => lo_ce,
           lo_rf_enable => lo_rf_enable,
           lo_muxout => lo_muxout,
           source_muxout => source_muxout,
           source_spi_data => source_spi_data,
           source_le => source_le,
           source_ce => source_ce,
           source_rf_enable => source_rf_enable,
           atten_spi_data => atten_spi_data,
           atten_le => atten_le,
           lo_ld => lo_ld,
           source_ld => source_ld,
           mixer_enable => mixer_enable,
           amp_pwdn => amp_pwdn,
           dither => dither,
           xadc_vp => '0',
           xadc_vn => '0',
           led => led);
           
--ft2232_rx : entity work.ft2232_rx
--Port map( data => ft2232_data,
--           data_out => read_data,
--           rxf => rxf,
--           txe => txe,
--           rd => rd,
--           wr => wr,
--           si_wu => si_wu);

rst_process :process
begin
    rst <= '1';
    wait for 2*clk_period;
    rst <= '0';
    wait;
end process;

ld_process : process
begin
    wait for 100*clk_period;
    lo_ld <= '1';
    wait for 10*clk_period;
    source_ld <= '1';
    wait;
end process;

-- Clock process definitions
clk_process : process
begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
end process;

read_process : process
variable i : integer := 0;
begin
     wait for 10*clk_period;
     if i = TEST_DATA_LENGTH then
        i := 0;
        read_done <= '1';
        report "End of data";
        wait;
     end if;
     rxf <= '1';
     wait for 81 ns;
     rxf <= '0';
     wait until rd = '0';
     ft2232_data <= (others => 'X');
     wait for 49 ns;
     ft2232_data <= test_data(i);
     wait until rd = '1';
     ft2232_data <= "ZZZZZZZZ";
     wait for 26 ns;
     rxf <= '1';
     i := i + 1;
end process;

write_process : process
variable i : integer := 0;
begin
     --if read_done = '0' then
     --   wait until read_done = '1';
     --end if;
     assert wr = '1' severity error;
     txe <= '0';
     wait for 100 ns;
     wait until wr = '0';
     wait for 50 ns;
     txe <= '1';
     read_data <= ft2232_data;
     new_data <= '1';
     --if read_data = COMM_START then
     --   wait for 10 ms;
     --end if;
     wait for clk_period;
     new_data <= '0';
     wait for 100 ns;
     i := i + 1;
end process;

report_process : process(clk, new_data, read_data)
variable state, count : integer := 0;
variable i, q, cycles : std_logic_vector(IQ_ACC_WIDTH-1 downto 0) := (others => '0');
variable sw : std_logic_vector(7 downto 0) := (others => '0');
begin

if rising_edge(clk) then
    if new_data = '1' then
        case state is
            when 0 =>
                if read_data = COMM_START then
                    state := 1;
                end if;
            when 1 =>
                if read_data = "00011000" then
                    state := 2;
                end if;
            when 2 =>
                if read_data = "00000001" then
                    state := 3;
                    count := 0;
                end if;
            when 6 => -- SW
                sw := read_data;
                state := 0;
                i_data <= signed(i);
                q_data <= signed(q);
                cycles_data <= signed(cycles);
                sw_data <= sw;
            when others =>
                -- 3, i
                -- 4, q
                -- 5, cycles
                -- 6, sw
                if state = 3 then
                    i(8*(count+1)-1 downto 8*count) := read_data;
                elsif state = 4 then
                    q(8*(count+1)-1 downto 8*count) := read_data;
                elsif state = 5 then
                    cycles(8*(count+1)-1 downto 8*count) := read_data;
                end if;
                
                if count = IQ_BYTES-1 then
                    state := state + 1;
                    count := 0;
                else
                    count := count + 1;
                end if;
        end case;
    end if;

end if;
end process;

spi_process : process(clk, spi_clk, source_spi_data, source_le)
variable atten_le_prev, source_le_prev, lo_le_prev : std_logic := '0';
variable source_q_int, lo_q_int : std_logic_vector(31 downto 0);
variable atten_q_int : std_logic_vector(7 downto 0);
begin
if rising_edge(spi_clk) then
    if source_le = '0' then
        source_q_int := source_spi_data&source_q_int(31 downto 1);
    end if;
    
    if lo_le = '0' then
        lo_q_int := lo_spi_data&lo_q_int(31 downto 1);
    end if;

    if atten_le = '0' then
       atten_q_int := atten_spi_data&atten_q_int(7 downto 1);
    end if;
end if;
if rising_edge(clk) then
    if source_le_prev = '0' and source_le = '1' then
        source_q <= source_q_int;
    end if;
    
    if lo_le_prev = '0' and lo_le = '1' then
        lo_q <= lo_q_int;
    end if;
    
    if atten_le_prev = '0' and atten_le = '1' then
       atten_q <= atten_q_int;
    end if;
    
    atten_le_prev := atten_le;
    source_le_prev := source_le;
    lo_le_prev := lo_le;
end if;
end process;

end Behavioral;
