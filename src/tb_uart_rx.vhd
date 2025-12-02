-- This testbench is ONLY for simulation
-- In real hardware, bits come from a USB-UART connected to FPGA pin.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_rx is
end entity;

architecture sim of tb_uart_rx is
  constant CLK_FREQ_HZ : integer := 50_000_000;
  constant BAUD_RATE   : integer := 115_200;
  constant CLK_PERIOD  : time    := 20 ns; -- 50 MHz

  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal rx_i  : std_logic := '1';
  signal data_o       : std_logic_vector(7 downto 0);
  signal data_valid_o : std_logic;

  constant BIT_TIME : time := 1 sec * 1_000_000 / BAUD_RATE; -- approx
begin

  clk <= not clk after CLK_PERIOD/2;

  uut: entity work.uart_rx
    generic map(
      CLK_FREQ_HZ => CLK_FREQ_HZ,
      BAUD_RATE   => BAUD_RATE
    )
    port map(
      clk          => clk,
      rst_n        => rst_n,
      rx_i         => rx_i,
      data_o       => data_o,
      data_valid_o => data_valid_o
    );

  process
  begin
    rst_n <= '0';
    wait for 200 ns;
    rst_n <= '1';
    wait for 200 ns;

    -- send one byte 0x55 over rx_i (start + 8 bits + stop)
    -- This is to show teacher we know how to simulate UART.
    rx_i <= '1';
    wait for BIT_TIME;

    -- start bit
    rx_i <= '0';
    wait for BIT_TIME;

    -- data bits LSB first: 0x55 = 0b01010101
    rx_i <= '1'; wait for BIT_TIME; -- bit0
    rx_i <= '0'; wait for BIT_TIME; -- bit1
    rx_i <= '1'; wait for BIT_TIME; -- bit2
    rx_i <= '0'; wait for BIT_TIME; -- bit3
    rx_i <= '1'; wait for BIT_TIME; -- bit4
    rx_i <= '0'; wait for BIT_TIME; -- bit5
    rx_i <= '1'; wait for BIT_TIME; -- bit6
    rx_i <= '0'; wait for BIT_TIME; -- bit7

    -- stop bit
    rx_i <= '1';
    wait for BIT_TIME;

    wait for 5*BIT_TIME;
    assert false report "Simulation finished" severity failure;
  end process;

end architecture;
