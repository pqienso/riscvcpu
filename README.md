# RISC-V 32-bit Pipelined Processor

A 5-stage pipelined RISC-V processor implementation with comprehensive verification infrastructure supporting both Verilator and Xilinx Vivado simulation.

## Overview

This project implements a 32-bit RISC-V processor (RV32I) with a classic 5-stage pipeline architecture:

- **Fetch (F)**: Instruction fetch from instruction memory
- **Decode (D)**: Instruction decode and register file read
- **Execute (E)**: ALU operations and branch resolution
- **Memory (M)**: Data memory access
- **Writeback (W)**: Register file write

## Features

- **RV32I Base Instruction Set**: Complete implementation of RISC-V 32-bit integer instructions
- **Hazard Handling**: Load-to-use hazards and data forwarding
- **Pipeline Control**: Automatic stall insertion and bubble management
- **Dual Simulator Support**: Works with both Verilator and Xilinx Vivado XSIM
- **Comprehensive Testing**: Includes test programs and trace generation
- **Pattern Checking**: Automated verification against expected execution traces

## Project Structure

```
.
├── common/verif/tb/scripts/    # Common verification scripts
├── design/
│   ├── code/                   # RTL design files
│   │   ├── pd.v               # Top-level pipelined processor
│   │   ├── alu.v              # Arithmetic Logic Unit
│   │   ├── decoder.v          # Instruction decoder
│   │   ├── register_file.v    # Register file (x0-x31)
│   │   ├── branch_comp.v      # Branch comparator
│   │   ├── imemory.v          # Instruction memory
│   │   └── dmemory.v          # Data memory
│   ├── design_wrapper.v       # Design wrapper
│   └── signals.h              # Signal definitions for verification
├── verif/
│   ├── data/                  # Test programs
│   │   ├── rv32ui-p-add.x    # RISC-V test: ADD instructions
│   │   ├── rv32ui-p-sb.x     # RISC-V test: Store byte
│   │   ├── BubbleSort.x      # Bubble sort algorithm
│   │   ├── Fibonacci.x       # Fibonacci sequence
│   │   └── CheckVowel.x      # Vowel checking program
│   ├── scripts/              # Build and simulation scripts
│   │   ├── Makefile          # Main makefile
│   │   ├── Makefile.verilator # Verilator-specific rules
│   │   └── Makefile.xsim     # Vivado XSIM rules
│   └── tests/                # Testbench files
│       ├── test_pd.sv        # Main testbench
│       ├── test_pd.cpp       # Verilator C++ testbench
│       ├── clockgen.sv       # Clock generation
│       └── tracegen.v        # Trace generation logic
```

## Design Modules

### Core Processor (`pd.v`)
The top-level module implementing the 5-stage pipeline with hazard detection and forwarding logic.

### ALU (`alu.v`)
Supports all RV32I arithmetic and logical operations:
- Arithmetic: ADD, SUB, ADDI
- Logical: AND, OR, XOR, ANDI, ORI, XORI
- Shifts: SLL, SRL, SRA, SLLI, SRLI, SRAI
- Comparisons: SLT, SLTU, SLTI, SLTIU
- Upper immediates: LUI, AUIPC

### Decoder (`decoder.v`)
Decodes 32-bit RISC-V instructions into control signals and immediate values for all instruction formats (R, I, S, B, U, J).

### Branch Comparator (`branch_comp.v`)
Evaluates branch conditions (BEQ, BNE, BLT, BGE, BLTU, BGEU) and generates branch taken signal.

### Register File (`register_file.v`)
32 general-purpose registers with:
- Two read ports (rs1, rs2)
- One write port (rd)
- x0 hardwired to zero

### Memory Modules
- **Instruction Memory** (`imemory.v`): Block RAM for program storage
- **Data Memory** (`dmemory.v`): Supports byte, halfword, and word access

## Prerequisites

### For Verilator Simulation
- Verilator 4.210
- GCC/Clang C++ compiler
- Make

### For Vivado XSIM Simulation
- Xilinx Vivado (with XSIM)
- Make

## Building and Running

### Using Verilator (Default)

```bash
cd verif/scripts

# Run default test (rv32ui-p-add)
make

# Run specific test program
make MEM_PATH=../../verif/data/BubbleSort.x

# Generate VCD waveform
make MEM_PATH=../../verif/data/Fibonacci.x VCD=1

# View waveforms
make waves MEM_PATH=../../verif/data/Fibonacci.x
```

### Using Vivado XSIM

```bash
cd verif/scripts

# Run with XSIM
make XSIM=1

# Run specific test
make XSIM=1 MEM_PATH=../../verif/data/CheckVowel.x
```

### Makefile Options

- `MEM_PATH`: Path to program hex file (default: rv32ui-p-add.x)
- `MEM_DEPTH`: Memory depth in bytes (default: 1048576)
- `TIMEOUT`: Simulation timeout in cycles (default: 50000)
- `VCD`: Enable VCD waveform dump (default: 0)
- `GEN_TRACE`: Enable trace generation (default: 1)
- `WARN`: Enable warning checks (default: 1)

## Test Programs

The project includes several test programs:

1. **rv32ui-p-add.x / rv32ui-p-sb.x**: RISC-V ISA compliance tests
2. **BubbleSort.x**: Sorting algorithm implementation
3. **Fibonacci.x**: Fibonacci sequence generator
4. **CheckVowel.x**: String processing example
5. **read_rf.x**: Register file test

## Verification Features

### Trace Generation
The testbench can generate execution traces showing the state of each pipeline stage per cycle:
```
[F] pc_address instruction
[D] pc opcode rd rs1 rs2 funct3 funct7 imm shamt
[R] rs1_addr rs2_addr rs1_data rs2_data
[E] pc alu_result branch_taken
[M] pc mem_address read_write size data
[W] pc write_enable destination write_data
```

### Pattern Checking
Compare execution against golden reference patterns for automated verification:
```bash
make PATTERN_CHECK=1 PATTERN_FILE=path/to/pattern.hex
```

### Waveform Viewing
Generate and view VCD waveforms with GTKWave:
```bash
make waves MEM_PATH=path/to/program.x
```

## Memory Map

- **Instruction Memory**: `0x01000000` - `0x010FFFFF`
- **Data Memory**: `0x01000000` - `0x010FFFFF`
- **Stack Pointer**: Initialized to `0x01000000 + MEM_DEPTH`

## Pipeline Hazards

The processor handles:

1. **Load-to-Use Hazards**: Automatic stall when a load instruction's result is needed in the next instruction
2. **Data Hazards**: Forwarding from Execute/Memory/Writeback stages to Execute stage
3. **Control Hazards**: Pipeline flush on branches and jumps

## Contributing

When modifying the design:

1. Update `design/signals.h` if adding new signals for verification
2. Add corresponding entries in `verif/tests/fields.h` for pattern checking
3. Run existing test suite to ensure no regressions
4. Document any new features or instruction support

## License

This project is provided as-is for educational purposes.

## References

- [RISC-V ISA Specification](https://riscv.org/technical/specifications/)
- [Verilator User Guide](https://verilator.org/guide/latest/)
- [Xilinx Vivado Documentation](https://www.xilinx.com/support/documentation-navigation/design-hubs/dh0014-vivado-simulation-hub.html)
