library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants_pkg.all;

entity cpu_top is
  port (
    clk   : in std_logic;
    rst_n : in std_logic
  );
end entity;

architecture rtl of cpu_top is

  -- PC
  signal s_pc_addr  : std_logic_vector(ADDR_W-1 downto 0);

  -- IMM resized to address width (STATIC for old ModelSim)
  signal s_imm_addr : std_logic_vector(ADDR_W-1 downto 0);

  -- Memory interface
  signal s_mem_addr : std_logic_vector(ADDR_W-1 downto 0);
  signal s_mem_dout : std_logic_vector(DATA_W-1 downto 0);
  signal s_mem_din  : std_logic_vector(DATA_W-1 downto 0);
  signal c_mem_rd, c_mem_wr, c_mem_addr_sel : std_logic;
  signal s_mem_ready : std_logic;

  -- Bus
  signal s_bus_data : std_logic_vector(DATA_W-1 downto 0);
  signal c_bus_src  : bus_src_t;

  -- IR
  signal c_ir_load, c_imm_load : std_logic;
  signal s_opcode : std_logic_vector(3 downto 0);
  signal s_rd_sel : std_logic_vector(2 downto 0);
  signal s_rs_sel : std_logic_vector(2 downto 0);
  signal s_imm    : std_logic_vector(DATA_W-1 downto 0);

  -- RF
  signal c_rf_we : std_logic;
  signal s_rs_data, s_rt_data : std_logic_vector(DATA_W-1 downto 0);

  -- ALU
  signal c_alu_op : std_logic_vector(3 downto 0);
  signal s_alu_y  : std_logic_vector(DATA_W-1 downto 0);
  signal s_zf, s_nf, s_cf, s_vf : std_logic;

  -- PSR latch
  signal psr_zf, psr_nf, psr_cf, psr_vf : std_logic := '0';
  signal c_flag_we : std_logic;

  -- Branch / jump
  signal c_pc_inc, c_pc_load, c_do_branch : std_logic;

begin

  -------------------------------------------------------------------
  -- Precompute resized immediate address (STATIC WIDTH)
  -------------------------------------------------------------------
  s_imm_addr <= std_logic_vector(resize(unsigned(s_imm), ADDR_W));

  -------------------------------------------------------------------
  -- Address mux: PC for fetch, IMM for LD/ST
  -------------------------------------------------------------------
  s_mem_addr <= s_pc_addr when c_mem_addr_sel='0'
                else s_imm_addr;

  -------------------------------------------------------------------
  -- PROGRAM COUNTER
  -------------------------------------------------------------------
  u_pc: entity work.program_counter
    port map(
      clk         => clk,
      rst_n       => rst_n,
      pc_inc      => c_pc_inc,
      pc_load     => c_pc_load,
      pc_load_val => s_imm_addr,   -- FIXED (no resize here)
      do_branch   => c_do_branch,
      off8        => s_imm,
      pc_addr     => s_pc_addr
    );

  -------------------------------------------------------------------
  -- MEMORY
  -------------------------------------------------------------------
  u_mem: entity work.memory
    port map(
      clk   => clk,
      addr  => s_mem_addr,
      dout  => s_bus_data,
      din   => s_mem_din,
      rd    => c_mem_rd,
      wr    => c_mem_wr,
      ready => s_mem_ready
    );

  -------------------------------------------------------------------
  -- INSTRUCTION REGISTER
  -------------------------------------------------------------------
  u_ir: entity work.instruction_reg
    port map(
      clk      => clk,
      rst_n    => rst_n,
      ir_load  => c_ir_load,
      imm_load => c_imm_load,
      bus_in   => s_bus_data,
      opcode   => s_opcode,
      rd_sel   => s_rd_sel,
      rs_sel   => s_rs_sel,
      imm      => s_imm,
      ir_byte  => open,
      imm_byte => open
    );

  -------------------------------------------------------------------
  -- REGISTER FILE
  -------------------------------------------------------------------
  u_rf: entity work.register_file
    port map(
      clk     => clk,
      rst_n   => rst_n,
      rs_sel  => s_rd_sel,  -- A = Rd old value
      rt_sel  => s_rs_sel,  -- B = Rs
      rd_sel  => s_rd_sel,  -- write back to Rd
      rf_we   => c_rf_we,
      bus_in  => s_bus_data,
      rs_data => s_rs_data,
      rt_data => s_rt_data
    );

  -------------------------------------------------------------------
  -- ALU
  -------------------------------------------------------------------
  u_alu: entity work.alu
    port map(
      a      => s_rs_data,
      b      => s_rt_data,
      alu_op => c_alu_op,
      y      => s_alu_y,
      zf     => s_zf,
      nf     => s_nf,
      cf     => s_cf,
      vf     => s_vf
    );

  -------------------------------------------------------------------
  -- INTERNAL BUS
  -------------------------------------------------------------------
  u_bus: entity work.internal_bus
    port map(
      bus_src  => c_bus_src,
      mem_data => s_mem_din,
      alu_data => s_alu_y,
      imm_data => s_imm,
      rf_data  => s_rs_data,
      bus_data => s_bus_data
    );

  -------------------------------------------------------------------
  -- FLAGS latch (PSR)
  -------------------------------------------------------------------
  process(clk, rst_n)
  begin
    if rst_n='0' then
      psr_zf <= '0';
      psr_nf <= '0';
      psr_cf <= '0';
      psr_vf <= '0';
    elsif rising_edge(clk) then
      if c_flag_we='1' then
        psr_zf <= s_zf;
        psr_nf <= s_nf;
        psr_cf <= s_cf;
        psr_vf <= s_vf;
      end if;
    end if;
  end process;

  -------------------------------------------------------------------
  -- CONTROL UNIT
  -------------------------------------------------------------------
  u_cu: entity work.control_unit
    port map(
      clk     => clk,
      rst_n   => rst_n,
      opcode  => s_opcode,
      zf      => psr_zf,
      nf      => psr_nf,
      cf      => psr_cf,
      vf      => psr_vf,
      mem_ready => s_mem_ready,

      ir_load  => c_ir_load,
      imm_load => c_imm_load,
      pc_inc   => c_pc_inc,
      pc_load  => c_pc_load,
      do_branch=> c_do_branch,
      rf_we    => c_rf_we,
      alu_op   => c_alu_op,
      bus_src  => c_bus_src,
      mem_rd   => c_mem_rd,
      mem_wr   => c_mem_wr,
      mem_addr_sel => c_mem_addr_sel,
      flag_we  => c_flag_we
    );

end architecture;
