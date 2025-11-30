library ieee;
use ieee.std_logic_1164.all;
use work.constants_pkg.all;

entity internal_bus is
  port (
    bus_src  : in  bus_src_t;
    mem_data : in  std_logic_vector(DATA_W-1 downto 0);
    alu_data : in  std_logic_vector(DATA_W-1 downto 0);
    imm_data : in  std_logic_vector(DATA_W-1 downto 0);
    rf_data  : in  std_logic_vector(DATA_W-1 downto 0);
    bus_data : out std_logic_vector(DATA_W-1 downto 0)
  );
end entity;

architecture comb of internal_bus is
begin
  process(bus_src, mem_data, alu_data, imm_data, rf_data)
  begin
    case bus_src is
      when BUS_MEM  => bus_data <= mem_data;
      when BUS_ALU  => bus_data <= alu_data;
      when BUS_IMM  => bus_data <= imm_data;
      when BUS_RF   => bus_data <= rf_data;
      when others   => bus_data <= (others=>'0');
    end case;
  end process;
end architecture;
