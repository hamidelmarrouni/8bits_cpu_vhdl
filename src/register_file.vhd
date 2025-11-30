library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants_pkg.all;

entity register_file is
  port (
    clk     : in  std_logic;
    rst_n   : in  std_logic;

    rs_sel  : in  std_logic_vector(2 downto 0);
    rt_sel  : in  std_logic_vector(2 downto 0);
    rd_sel  : in  std_logic_vector(2 downto 0);

    rf_we   : in  std_logic;
    bus_in  : in  std_logic_vector(DATA_W-1 downto 0);

    rs_data : out std_logic_vector(DATA_W-1 downto 0);
    rt_data : out std_logic_vector(DATA_W-1 downto 0)
  );
end entity;

architecture rtl of register_file is
  type reg_arr_t is array(0 to 7) of std_logic_vector(DATA_W-1 downto 0);
  signal regs : reg_arr_t := (others=>(others=>'0'));

  function idx(s: std_logic_vector(2 downto 0)) return integer is
  begin
    return to_integer(unsigned(s));
  end function;
begin

  -- synchronous write
  process(clk, rst_n)
  begin
    if rst_n='0' then
      regs <= (others=>(others=>'0'));
    elsif rising_edge(clk) then
      if rf_we='1' then
        regs(idx(rd_sel)) <= bus_in;
      end if;
    end if;
  end process;

  -- async reads
  rs_data <= regs(idx(rs_sel));
  rt_data <= regs(idx(rt_sel));

end architecture;
