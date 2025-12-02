import re
import tkinter as tk
from tkinter import ttk, messagebox

# Try to import pyserial (for UART). If missing, we handle it gracefully.
try:
    import serial
except ImportError:
    serial = None

# =============================
#  CPU OPCODES & REGISTERS
#  (must match your VHDL constants_pkg)
# =============================

OPCODES = {
    "NOP": 0x0,
    "LDI": 0x1,
    "ADD": 0x2,
    "SUB": 0x3,
    "AND": 0x4,
    "OR" : 0x5,
    "XOR": 0x6,
    "LD" : 0x7,
    "ST" : 0x8,
    "BRZ": 0x9,
    "JMP": 0xA,
}

REGS = {
    "R0": 0,
    "R1": 1,
    "R2": 2,
    "R3": 3,
    "R4": 4,
    "R5": 5,
    "R6": 6,
    "R7": 7,
}

# =============================
#  ASSEMBLER HELPERS
# =============================

def parse_reg(token: str) -> int:
    token = token.upper().strip()
    if token in REGS:
        return REGS[token]
    raise ValueError(f"Unknown register: {token}")

def parse_imm(token: str, labels=None, pc=None) -> int:
    token = token.strip()
    # Label reference
    if labels is not None and token in labels:
        return labels[token]
    # Hex
    if token.lower().startswith("0x"):
        return int(token, 16) & 0xFF
    # Decimal
    return int(token) & 0xFF

def assemble_line(line: str, labels: dict, pc: int):
    """
    Assemble a single line -> list of bytes
    """
    # Remove comments
    line = line.split(";")[0].strip()
    if not line:
        return []

    # Label-only line
    if line.endswith(":"):
        return []

    parts = re.split(r"[,\s]+", line)
    parts = [p for p in parts if p]
    if not parts:
        return []

    mnemonic = parts[0].upper()

    # NOP (1 byte)
    if mnemonic == "NOP":
        byte0 = (OPCODES["NOP"] << 4)
        return [byte0]

    if mnemonic not in OPCODES:
        raise ValueError(f"Unknown instruction: {mnemonic}")

    op = OPCODES[mnemonic]

    # LDI Rd, imm
    if mnemonic == "LDI":
        if len(parts) != 3:
            raise ValueError("LDI syntax: LDI Rn, imm")
        rd = parse_reg(parts[1])
        imm = parse_imm(parts[2], labels, pc)
        byte0 = (op << 4) | (rd << 1)
        byte1 = imm
        return [byte0, byte1]

    # ADD/SUB/AND/OR/XOR  Rd, Rs
    elif mnemonic in ["ADD", "SUB", "AND", "OR", "XOR"]:
        if len(parts) != 3:
            raise ValueError(f"{mnemonic} syntax: {mnemonic} Rd, Rs")
        rd = parse_reg(parts[1])
        rs = parse_reg(parts[2])
        byte0 = (op << 4) | (rd << 1)
        byte1 = rs & 0x07
        return [byte0, byte1]

    # LD / ST  Rd, [addr]
    elif mnemonic in ["LD", "ST"]:
        if len(parts) != 3:
            raise ValueError(f"{mnemonic} syntax: {mnemonic} Rd, [addr]")
        rd = parse_reg(parts[1])
        addr_token = parts[2].replace("[", "").replace("]", "")
        addr = parse_imm(addr_token, labels, pc)
        byte0 = (op << 4) | (rd << 1)
        byte1 = addr
        return [byte0, byte1]

    # JMP addr_or_label
    elif mnemonic == "JMP":
        if len(parts) != 2:
            raise ValueError("JMP syntax: JMP addr_or_label")
        addr = parse_imm(parts[1], labels, pc)
        byte0 = (op << 4)
        byte1 = addr
        return [byte0, byte1]

    # BRZ addr_or_label (PC-relative offset)
    elif mnemonic == "BRZ":
        if len(parts) != 2:
            raise ValueError("BRZ syntax: BRZ addr_or_label")
        target = parse_imm(parts[1], labels, pc)
        # PC-relative offset from (pc+2) to target
        offset = (target - (pc + 2)) & 0xFF
        byte0 = (op << 4)
        byte1 = offset
        return [byte0, byte1]

    else:
        raise ValueError(f"Assembler: {mnemonic} not implemented")

def assemble(asm_text: str):
    """
    Two-pass assembler:
      Pass 1: build label table
      Pass 2: generate bytes
    """
    lines = asm_text.splitlines()

    # PASS 1: label addresses
    labels = {}
    pc = 0
    for line in lines:
        stripped = line.split(";")[0].strip()
        if not stripped:
            continue
        if stripped.endswith(":"):
            label = stripped[:-1].strip()
            if label in labels:
                raise ValueError(f"Duplicate label: {label}")
            labels[label] = pc
        else:
            parts = re.split(r"[,\s]+", stripped)
            parts = [x for x in parts if x]
            if not parts:
                continue
            mnem = parts[0].upper()
            # NOP = 1 byte, others = 2 bytes
            if mnem == "NOP":
                pc += 1
            else:
                pc += 2

    # PASS 2: generate code
    bytes_out = []
    pc = 0
    for line in lines:
        b = assemble_line(line, labels, pc)
        pc += len(b)
        bytes_out.extend(b)

    return bytes_out

def save_hex_file(bytes_out, filename: str = "program.hex"):
    with open(filename, "w") as f:
        for b in bytes_out:
            f.write(f"{b:02X}\n")

# =============================
#  UART SENDER (REAL HARDWARE)
# =============================

def send_program_via_uart(port_name: str, baud: int, data_bytes):
    """
    Real-world mode:
      Frame: 0x55 0xAA LEN_H LEN_L <data...>
    """
    if serial is None:
        raise RuntimeError(
            "pyserial is not installed. Install with:\n"
            "    pip install pyserial"
        )

    length = len(data_bytes)
    if length == 0:
        raise ValueError("Program is empty")

    frame = bytearray()
    frame.append(0x55)
    frame.append(0xAA)
    frame.append((length >> 8) & 0xFF)
    frame.append(length & 0xFF)
    frame.extend(b & 0xFF for b in data_bytes)

    with serial.Serial(port_name, baudrate=baud, timeout=1) as ser:
        ser.write(frame)

# =============================
#  SIMPLE CALC → ASSEMBLY
#  (friendly mode, using all instructions)
# =============================

def generate_assembly_for_op(a: int, b: int, op: str) -> str:
    """
    Generates a tiny COMPLETE program:
      - Computes R0 = a <op> b
      - Stores R0 at [0xF0]
      - Loops forever

    Supported ops:
      +  → ADD
      -  → SUB
      &  → AND
      |  → OR
      ^  → XOR
      *  → implemented by loop: repeated addition using BRZ + JMP
    """
    op = op.strip()

    # Basic sanity
    if op not in ["+", "-", "&", "|", "^", "*"]:
        raise ValueError("Supported operations: +, -, &, |, ^, *")

    asm = []

    # Arithmetic & logic that fit in one ALU op
    if op in ["+", "-", "&", "|", "^"]:
        asm.append(f"LDI R0, {a}")
        asm.append(f"LDI R1, {b}")

        if op == "+":
            asm.append("ADD R0, R1")
        elif op == "-":
            asm.append("SUB R0, R1")
        elif op == "&":
            asm.append("AND R0, R1")
        elif op == "|":
            asm.append("OR R0, R1")
        elif op == "^":
            asm.append("XOR R0, R1")

        asm.append("ST R0, [0xF0]")
        asm.append("loop:")
        asm.append("JMP loop")

        return "\n".join(asm)

    # Multiplication with a simple loop using only our instructions
    if op == "*":
        # result in R0, multiplicand in R1, counter in R2, constant(1) in R3
        asm.append("LDI R0, 0")       # result = 0
        asm.append(f"LDI R1, {a}")    # multiplicand
        asm.append(f"LDI R2, {b}")    # counter
        asm.append("LDI R3, 1")       # constant 1

        asm.append("loop_mul:")
        asm.append("ADD R0, R1")      # result += a
        asm.append("SUB R2, R3")      # R2--, sets flags
        asm.append("BRZ end_mul")     # if R2 == 0 → done
        asm.append("JMP loop_mul")

        asm.append("end_mul:")
        asm.append("ST R0, [0xF0]")   # store result to I/O
        asm.append("loop:")
        asm.append("JMP loop")

        return "\n".join(asm)

    # Should never reach here
    raise ValueError("Unknown operation")

# =============================
#  TKINTER GUI
# =============================

class CpuGui(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("8-bit CPU Tool - Assembly & Simple Calc")
        self.geometry("950x600")

        notebook = ttk.Notebook(self)
        notebook.pack(fill="both", expand=True)

        # TAB 1: Assembly mode
        asm_frame = ttk.Frame(notebook)
        notebook.add(asm_frame, text="Assembly Mode")

        top_asm = ttk.Frame(asm_frame)
        top_asm.pack(fill="x", padx=10, pady=5)

        ttk.Button(
            top_asm,
            text="Assemble → HEX (simulation)",
            command=self.on_assemble_hex
        ).pack(side="left", padx=5)

        ttk.Button(
            top_asm,
            text="Assemble → HEX + UART (real)",
            command=self.on_assemble_uart
        ).pack(side="left", padx=5)

        ttk.Label(top_asm, text="Port:").pack(side="left", padx=5)
        self.port_entry = tk.Entry(top_asm, width=8)
        self.port_entry.insert(0, "COM3")
        self.port_entry.pack(side="left")

        ttk.Label(top_asm, text="Baud:").pack(side="left", padx=5)
        self.baud_entry = tk.Entry(top_asm, width=8)
        self.baud_entry.insert(0, "115200")
        self.baud_entry.pack(side="left")

        main_asm = ttk.Panedwindow(asm_frame, orient=tk.HORIZONTAL)
        main_asm.pack(fill="both", expand=True, padx=10, pady=5)

        asm_box_frame = ttk.Frame(main_asm)
        hex_box_frame = ttk.Frame(main_asm)
        main_asm.add(asm_box_frame, weight=3)
        main_asm.add(hex_box_frame, weight=1)

        ttk.Label(asm_box_frame, text="Assembly code:").pack(anchor="w")
        self.asm_text = tk.Text(asm_box_frame, font=("Consolas", 11))
        self.asm_text.pack(fill="both", expand=True)

        ttk.Label(hex_box_frame, text="Generated HEX (program.hex):").pack(anchor="w")
        self.hex_text = tk.Text(hex_box_frame, font=("Consolas", 11), state="normal")
        self.hex_text.pack(fill="both", expand=True)

        sample = """; Example program
; R0 = 5, R1 = 10, R0 = R0 + R1, store to 0xF0, loop forever

LDI R0, 5
LDI R1, 10
ADD R0, R1
ST  R0, [0xF0]
loop:
JMP loop
"""
        self.asm_text.insert("1.0", sample)

        # TAB 2: Simple calc mode
        calc_frame = ttk.Frame(notebook)
        notebook.add(calc_frame, text="Simple Calc → Program")

        ttk.Label(calc_frame, text="Choose a, operator, b:").pack(anchor="w", padx=10, pady=5)

        row = ttk.Frame(calc_frame)
        row.pack(anchor="w", padx=10, pady=5)

        self.a_entry = tk.Entry(row, width=5)
        self.a_entry.insert(0, "5")
        self.a_entry.pack(side="left")

        self.op_var = tk.StringVar(value="+")
        # Now support +, -, &, |, ^, *
        op_box = ttk.Combobox(row, textvariable=self.op_var,
                              values=["+", "-", "&", "|", "^", "*"], width=3)
        op_box.pack(side="left", padx=5)

        self.b_entry = tk.Entry(row, width=5)
        self.b_entry.insert(0, "10")
        self.b_entry.pack(side="left")

        ttk.Button(
            calc_frame,
            text="Generate assembly from calc",
            command=self.on_generate_from_calc
        ).pack(anchor="w", padx=10, pady=5)

        ttk.Label(calc_frame, text="Generated assembly:").pack(anchor="w", padx=10)
        self.calc_asm_text = tk.Text(calc_frame, font=("Consolas", 11), height=10)
        self.calc_asm_text.pack(fill="x", padx=10, pady=5)

        ttk.Label(
            calc_frame,
            text="Supported operations: +  -  &  |  ^  *"
        ).pack(anchor="w", padx=10, pady=5)

    # -------- ASM TAB HANDLERS --------

    def assemble_current(self):
        asm = self.asm_text.get("1.0", tk.END)
        data = assemble(asm)

        self.hex_text.config(state="normal")
        self.hex_text.delete("1.0", tk.END)
        for b in data:
            self.hex_text.insert(tk.END, f"{b:02X}\n")
        self.hex_text.config(state="normal")

        save_hex_file(data, "program.hex")
        return data

    def on_assemble_hex(self):
        try:
            data = self.assemble_current()
            messagebox.showinfo(
                "OK",
                f"program.hex saved ({len(data)} bytes). Use it in simulation."
            )
        except Exception as e:
            messagebox.showerror("Assembly Error", str(e))

    def on_assemble_uart(self):
        try:
            data = self.assemble_current()
            port = self.port_entry.get().strip()
            baud = int(self.baud_entry.get().strip())
            send_program_via_uart(port, baud, data)
            messagebox.showinfo(
                "OK",
                f"Program of {len(data)} bytes sent to {port}."
            )
        except Exception as e:
            messagebox.showerror("UART Error", str(e))

    # -------- CALC TAB HANDLERS --------

    def on_generate_from_calc(self):
        try:
            a = int(self.a_entry.get().strip())
            b = int(self.b_entry.get().strip())
            op = self.op_var.get()
            asm = generate_assembly_for_op(a, b, op)

            # Show in calc tab
            self.calc_asm_text.delete("1.0", tk.END)
            self.calc_asm_text.insert("1.0", asm)

            # Also copy into main ASM tab for direct assemble/UART
            self.asm_text.delete("1.0", tk.END)
            self.asm_text.insert("1.0", asm)
        except Exception as e:
            messagebox.showerror("Calc Error", str(e))


if __name__ == "__main__":
    app = CpuGui()
    app.mainloop()
