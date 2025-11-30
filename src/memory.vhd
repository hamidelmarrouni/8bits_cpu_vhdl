library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants_pkg.all;

entity memory is
  generic (
    MEM_SIZE : natural := 256  -- bytes (edit if you want)
  );
  port (
    clk   : in  std_logic;
    addr  : in  std_logic_vector(ADDR_W-1 downto 0);
    dout  : in  std_logic_vector(DATA_W-1 downto 0); -- data to write
    din   : out std_logic_vector(DATA_W-1 downto 0); -- data read
    rd    : in  std_logic;
    wr    : in  std_logic;
    ready : out std_logic
  );
end entity;

architecture rtl of memory is
  type mem_t is array (0 to MEM_SIZE-1) of std_logic_vector(DATA_W-1 downto 0);
  signal mem : mem_t := (
    0 => x"10", -- example program (edit freely)
    1 => x"05", -- imm for LDI R0,#5
    2 => x"00", -- NOP
    others => x"00"
  );

  signal rdata_reg : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  signal addr_i    : integer;
begin
  addr_i <= to_integer(unsigned(addr(7 downto 0))); -- low 8 bits only for MEM_SIZE<=256

  process(clk)
  begin
    if rising_edge(clk) then
      -- synchronous WRITE
      if wr = '1' then
        if addr_i < MEM_SIZE then
          mem(addr_i) <= dout;
        end if;
      end if;

      -- registered READ (1-cycle latency)
      if rd = '1' then
        if addr_i < MEM_SIZE then
          rdata_reg <= mem(addr_i);
        else
          rdata_reg <= (others=>'0');
        end if;
      end if;
    end if;
  end process;

  din   <= rdata_reg;
  ready <= '1';
end architecture;
