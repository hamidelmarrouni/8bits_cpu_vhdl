library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
  generic (
    CLK_FREQ_HZ : integer := 50_000_000;
    BAUD_RATE   : integer := 115_200
  );
  port (
    clk          : in  std_logic;
    rst_n        : in  std_logic;
    rx_i         : in  std_logic;  -- UART RX pin from PC
    data_o       : out std_logic_vector(7 downto 0);
    data_valid_o : out std_logic   -- '1' for 1 clk when data_o is valid
  );
end entity;

architecture rtl of uart_rx is
  type state_t is (IDLE, START, DATA, STOP);
  signal state      : state_t := IDLE;
  signal clk_count  : integer := 0;
  signal bit_index  : integer range 0 to 7 := 0;
  signal rx_reg     : std_logic_vector(7 downto 0) := (others => '0');

  constant CLKS_PER_BIT : integer := CLK_FREQ_HZ / BAUD_RATE;
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        state        <= IDLE;
        clk_count    <= 0;
        bit_index    <= 0;
        rx_reg       <= (others => '0');
        data_o       <= (others => '0');
        data_valid_o <= '0';
      else
        data_valid_o <= '0';

        case state is
          when IDLE =>
            if rx_i = '0' then
              state     <= START;
              clk_count <= 0;
            end if;

          when START =>
            if clk_count = (CLKS_PER_BIT/2) then
              if rx_i = '0' then
                clk_count <= 0;
                bit_index <= 0;
                state     <= DATA;
              else
                state     <= IDLE;
              end if;
            else
              clk_count <= clk_count + 1;
            end if;

          when DATA =>
            if clk_count = CLKS_PER_BIT-1 then
              clk_count         <= 0;
              rx_reg(bit_index) <= rx_i;
              if bit_index = 7 then
                bit_index <= 0;
                state     <= STOP;
              else
                bit_index <= bit_index + 1;
              end if;
            else
              clk_count <= clk_count + 1;
            end if;

          when STOP =>
            if clk_count = CLKS_PER_BIT-1 then
              clk_count    <= 0;
              state        <= IDLE;
              data_o       <= rx_reg;
              data_valid_o <= '1';
            else
              clk_count <= clk_count + 1;
            end if;

        end case;
      end if;
    end if;
  end process;

end architecture;
