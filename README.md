# 8-bit CPU in VHDL

This project implements a simple 8-bit CPU using VHDL and ModelSim/Quartus (Altera 13.1).  
It includes a complete datapath and control unit, plus a testbench to simulate a small program.

> Repository: `hamidelmarrouni/8bits_cpu_vhdl`

---

## 🧠 CPU Overview

- **Data width**: 8 bits (`DATA_W`)
- **Address width**: 12 bits (`ADDR_W`)
- **Memory size**: configurable (default 256 bytes)
- **Register file**: 8 general-purpose registers (R0–R7)
- **Architecture**: simple von Neumann (same memory for instructions + data)
- **Control**: single-cycle FSM (fetch → decode → optional op-fetch → execute → mem → write-back)

The CPU is built from the following main blocks:

- `program_counter` – holds the current program address, supports:
  - `PC = PC + 1`
  - `PC = PC + offset` (branch)
  - `PC = immediate` (jump)
- `instruction_reg` – stores the instruction bytes and decodes:
  - opcode
  - destination register (Rd)
  - source register (Rs)
  - immediate value
- `register_file` – 8 × 8-bit registers with 2 read ports and 1 write port
- `alu` – arithmetic and logic unit with flags:
  - Zero (Z), Negative (N), Carry (C), Overflow (V)
- `memory` – byte-addressable RAM / program memory
- `internal_bus` – 4-to-1 bus multiplexer for:
  - ALU result, memory data, immediate value, register data
- `control_unit` – FSM that:
  - sequences instruction fetch/execute
  - generates control signals for PC, RF, ALU, memory, and bus
- `cpu_top` – top-level that connects all of the above
- `tb_cpu_full` – testbench for simulating the full CPU

---

## 🧾 Instruction Set

The instruction format is 8-bit opcodes with an optional second byte (immediate / extra info).

**Main opcodes (from `constants_pkg.vhd`):**

- `OP_NOP` – no operation
- `OP_LDI` – load immediate: `Rd ← imm8`
- `OP_ADD` – `Rd ← Rd + Rs`
- `OP_SUB` – `Rd ← Rd - Rs`
- `OP_AND` – `Rd ← Rd AND Rs`
- `OP_OR`  – `Rd ← Rd OR Rs`
- `OP_XOR` – `Rd ← Rd XOR Rs`
- `OP_LD`  – load from memory: `Rd ← [addr]`
- `OP_ST`  – store to memory: `[addr] ← Rs`
- `OP_BRZ` – branch if zero flag set: `if Z = 1 then PC ← PC + offset`
- `OP_JMP` – unconditional jump: `PC ← addr`

The exact bit encoding (opcode / Rd / Rs / imm8) is defined and decoded in:

- `constants_pkg.vhd`
- `instruction_reg.vhd`
- `control_unit.vhd`

---

## 📁 Project Structure

Typical structure of this repo:

```text
8bits_cpu_vhdl/
├─ src/
│  ├─ constants_pkg.vhd      -- global constants & opcodes
│  ├─ program_counter.vhd    -- PC with increment, branch, and jump
│  ├─ instruction_reg.vhd    -- IR + immediate register + decode
│  ├─ register_file.vhd      -- 8×8-bit register file
│  ├─ alu.vhd                -- arithmetic and logic unit + flags
│  ├─ internal_bus.vhd       -- bus multiplexer (MEM/ALU/IMM/RF)
│  ├─ memory.vhd             -- simple RAM / program memory
│  ├─ control_unit.vhd       -- FSM (fetch/decode/execute/mem/wb)
│  └─ cpu_top.vhd            -- top-level CPU
│
├─ testbench/
│  └─ tb_cpu_full.vhd        -- full CPU testbench
│
├─ cpu 8bits.mpf             -- ModelSim/Quartus project file (local)
├─ cpu 8bits.cr.mti          -- ModelSim config (local)
├─ work/                     -- ModelSim work library (generated)
├─ vsim.wlf                  -- ModelSim waveform dump (generated)
└─ README.md
