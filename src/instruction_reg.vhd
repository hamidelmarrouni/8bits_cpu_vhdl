library ieee;
use ieee.std_logic_1164.all;
use work.constants_pkg.all;

entity instruction_reg is
  port (
    clk      : in  std_logic;
    rst_n    : in  std_logic;
    ir_load  : in  std_logic;
    imm_load : in  std_logic;
    bus_in   : in  std_logic_vector(DATA_W-1 downto 0);

    opcode   : out std_logic_vector(3 downto 0);
    rd_sel   : out std_logic_vector(2 downto 0);
    rs_sel   : out std_logic_vector(2 downto 0);
    imm      : out std_logic_vector(DATA_W-1 downto 0);

    ir_byte  : out std_logic_vector(DATA_W-1 downto 0);
    imm_byte : out std_logic_vector(DATA_W-1 downto 0)
  );
end entity;

architecture rtl of instruction_reg is
  signal ir_reg  : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  signal imm_reg : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
begin
  process(clk, rst_n)
  begin
    if rst_n='0' then
      ir_reg  <= (others=>'0');
      imm_reg <= (others=>'0');
    elsif rising_edge(clk) then
      if ir_load='1' then
        ir_reg <= bus_in;
      end if;
      if imm_load='1' then
        imm_reg <= bus_in;
      end if;
    end if;
  end process;

  opcode <= ir_reg(7 downto 4);
  rd_sel <= ir_reg(3 downto 1);
  rs_sel <= imm_reg(2 downto 0); -- R-type source from byte1
  imm    <= imm_reg;

  ir_byte  <= ir_reg;
  imm_byte <= imm_reg;
end architecture;
