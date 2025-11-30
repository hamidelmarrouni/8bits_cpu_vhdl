library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package constants_pkg is
  constant DATA_W : natural := 8;
  constant ADDR_W : natural := 12;

  -- Bus sources
  type bus_src_t is (BUS_NONE, BUS_MEM, BUS_ALU, BUS_IMM, BUS_RF);

  -- ALU 4-bit op codes
  constant ALU_ADD   : std_logic_vector(3 downto 0) := "0000";
  constant ALU_SUB   : std_logic_vector(3 downto 0) := "0001";
  constant ALU_AND   : std_logic_vector(3 downto 0) := "0010";
  constant ALU_OR    : std_logic_vector(3 downto 0) := "0011";
  constant ALU_XOR   : std_logic_vector(3 downto 0) := "0100";
  constant ALU_NAND  : std_logic_vector(3 downto 0) := "0101";
  constant ALU_NOR   : std_logic_vector(3 downto 0) := "0110";
  constant ALU_INC   : std_logic_vector(3 downto 0) := "0111";
  constant ALU_DEC   : std_logic_vector(3 downto 0) := "1000";
  constant ALU_SHL   : std_logic_vector(3 downto 0) := "1001";
  constant ALU_SHR   : std_logic_vector(3 downto 0) := "1010";
  constant ALU_PASSA : std_logic_vector(3 downto 0) := "1011";
  constant ALU_MUL   : std_logic_vector(3 downto 0) := "1100";

  -- CPU opcodes (from IR[7:4])
  constant OP_NOP : std_logic_vector(3 downto 0) := "0000";
  constant OP_LDI : std_logic_vector(3 downto 0) := "0001";
  constant OP_ADD : std_logic_vector(3 downto 0) := "0010";
  constant OP_SUB : std_logic_vector(3 downto 0) := "0011";
  constant OP_AND : std_logic_vector(3 downto 0) := "0100";
  constant OP_OR  : std_logic_vector(3 downto 0) := "0101";
  constant OP_XOR : std_logic_vector(3 downto 0) := "0110";
  constant OP_LD  : std_logic_vector(3 downto 0) := "0111";
  constant OP_ST  : std_logic_vector(3 downto 0) := "1000";
  constant OP_BRZ : std_logic_vector(3 downto 0) := "1001";
  constant OP_JMP : std_logic_vector(3 downto 0) := "1010";

end package;

package body constants_pkg is
end package body;
