library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants_pkg.all;

entity control_unit is
  port (
    clk     : in  std_logic;
    rst_n   : in  std_logic;

    opcode  : in  std_logic_vector(3 downto 0);
    zf      : in  std_logic;
    nf      : in  std_logic;
    cf      : in  std_logic;
    vf      : in  std_logic;
    mem_ready : in std_logic;

    -- control outs
    ir_load  : out std_logic;
    imm_load : out std_logic;

    pc_inc   : out std_logic;
    pc_load  : out std_logic;
    do_branch: out std_logic;

    rf_we    : out std_logic;

    alu_op   : out std_logic_vector(3 downto 0);
    bus_src  : out bus_src_t;

    mem_rd   : out std_logic;
    mem_wr   : out std_logic;
    mem_addr_sel : out std_logic;  -- 0=PC, 1=IMM(addr8)

    flag_we  : out std_logic       -- latch flags from ALU
  );
end entity;

architecture fsm of control_unit is
  type state_t is (S_RESET, S_FETCH, S_DECODE, S_OPFETCH, S_EXEC, S_MEM, S_WB);
  signal st, st_n : state_t := S_RESET;

  function uses_imm(op: std_logic_vector(3 downto 0)) return boolean is
  begin
    return (op=OP_LDI) or (op=OP_LD) or (op=OP_ST) or (op=OP_BRZ) or (op=OP_JMP)
           or (op=OP_ADD) or (op=OP_SUB) or (op=OP_AND) or (op=OP_OR) or (op=OP_XOR);
  end function;

begin

  -- state register
  process(clk, rst_n)
  begin
    if rst_n='0' then
      st <= S_RESET;
    elsif rising_edge(clk) then
      st <= st_n;
    end if;
  end process;

  -- next state + outputs
  process(st, opcode, mem_ready, zf)
  begin
    -- defaults
    ir_load <= '0'; imm_load<='0';
    pc_inc<='0'; pc_load<='0'; do_branch<='0';
    rf_we<='0';
    alu_op <= ALU_PASSA;
    bus_src <= BUS_NONE;
    mem_rd<='0'; mem_wr<='0'; mem_addr_sel<='0';
    flag_we<='0';

    st_n <= st;

    case st is

      when S_RESET =>
        st_n <= S_FETCH;

      when S_FETCH =>
        mem_addr_sel <= '0';   -- address from PC
        mem_rd <= '1';
        bus_src <= BUS_MEM;
        ir_load <= '1';
        pc_inc <= '1';
        st_n <= S_DECODE;

      when S_DECODE =>
        if uses_imm(opcode) then
          st_n <= S_OPFETCH;
        else
          st_n <= S_EXEC;
        end if;

      when S_OPFETCH =>
        mem_addr_sel <= '0';
        mem_rd <= '1';
        bus_src <= BUS_MEM;
        imm_load <= '1';
        pc_inc <= '1';
        st_n <= S_EXEC;

      when S_EXEC =>
        case opcode is
          when OP_NOP =>
            st_n <= S_FETCH;

          when OP_LDI =>
            st_n <= S_WB;

          when OP_ADD =>
            alu_op <= ALU_ADD;
            bus_src <= BUS_ALU;
            st_n <= S_WB;

          when OP_SUB =>
            alu_op <= ALU_SUB;
            bus_src <= BUS_ALU;
            st_n <= S_WB;

          when OP_AND =>
            alu_op <= ALU_AND;
            bus_src <= BUS_ALU;
            st_n <= S_WB;

          when OP_OR =>
            alu_op <= ALU_OR;
            bus_src <= BUS_ALU;
            st_n <= S_WB;

          when OP_XOR =>
            alu_op <= ALU_XOR;
            bus_src <= BUS_ALU;
            st_n <= S_WB;

          when OP_LD =>
            st_n <= S_MEM;

          when OP_ST =>
            alu_op <= ALU_PASSA;   -- PASS Rs to bus through ALU
            bus_src <= BUS_ALU;
            st_n <= S_MEM;

          when OP_BRZ =>
            if zf='1' then
              do_branch <= '1';
            end if;
            st_n <= S_FETCH;

          when OP_JMP =>
            pc_load <= '1';
            st_n <= S_FETCH;

          when others =>
            st_n <= S_FETCH;
        end case;

      when S_MEM =>
        mem_addr_sel <= '1'; -- address from IMM (addr8)

        if opcode = OP_LD then
          mem_rd <= '1';
          st_n <= S_WB;

        elsif opcode = OP_ST then
          mem_wr <= '1';
          bus_src <= BUS_ALU; -- keep data
          st_n <= S_FETCH;

        else
          st_n <= S_FETCH;
        end if;

      when S_WB =>
        case opcode is
          when OP_LDI =>
            bus_src <= BUS_IMM;
            rf_we <= '1';
            st_n <= S_FETCH;

          when OP_LD =>
            bus_src <= BUS_MEM;
            rf_we <= '1';
            st_n <= S_FETCH;

          when OP_ADD | OP_SUB | OP_AND | OP_OR | OP_XOR =>
            bus_src <= BUS_ALU;
            rf_we <= '1';
            flag_we <= '1';
            st_n <= S_FETCH;

          when others =>
            st_n <= S_FETCH;
        end case;

    end case;
  end process;

end architecture;
