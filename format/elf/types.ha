// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// TODO:
// - Flesh out ELF32 structures

export def MAGIC: str = "\x7FELF";
export def EI_MAG0: uint = 0;
export def EI_MAG1: uint = 1;
export def EI_MAG2: uint = 2;
export def EI_MAG3: uint = 3;
export def EI_CLASS: uint = 4;
export def EI_DATA: uint = 5;
export def EI_VERSION: uint = 6;
export def EI_OSABI: uint = 7;
export def EI_ABIVERSION: uint = 8;
export def EI_PAD: uint = 9;
export def EI_NIDENT: uint = 16;
export def EV_CURRENT: u32 = 1;

// ELF header for ELF64
export type header64 = struct {
	// ELF identification
	e_ident: [EI_NIDENT]u8,
	// Object file type
	e_type: elf_type,
	// Machine type
	e_machine: elf_machine,
	// Object file version ([EV_CURRENT])
	e_version: u32,
	// Entry point address
	e_entry: u64,
	// Program header offset
	e_phoff: u64,
	// Section header offset
	e_shoff: u64,
	// Processor-specific flags
	e_flags: u32,
	// ELF header size
	e_ehsize: u16,
	// Size of program header entry
	e_phentsize: u16,
	// Number of program header entries
	e_phnum: u16,
	// Size of section header entry
	e_shentsize: u16,
	// Number of section header entries
	e_shnum: u16,
	// Section name string table index, or [shn::UNDEF]
	e_shstrndx: u16,
};

// Section header for ELF64
export type section64 = struct {
	// Section name
	sh_name: u32,
	// Section type
	sh_type: u32,
	// Section attributes
	sh_flags: u64,
	// Virtual address in memory
	sh_addr: u64,
	// Offset in file
	sh_offset: u64,
	// Size of section
	sh_size: u64,
	// Link to other section
	sh_link: u32,
	// Miscellaenous information
	sh_info: u32,
	// Address alignment boundary
	sh_addralign: u64,
	// Size of entries, if section has table
	sh_entsize: u64,
};

// ELF file class
export type ident_class = enum u8 {
	// 32-bit objects
	ELF32 = 1,
	// 64-bit objects
	ELF64 = 2,
};

// Byte ordering
export type ident_data = enum u8 {
	// Object file data structures are little-endian
	LSB = 1,
	// Object file data structures are big-endian
	MSB = 2,
};

// Machine architecture
export type elf_machine = enum u16 {
	// Unknown machine
	NONE = 0,
	// AT&T WE32100
	M32 = 1,
	// Sun SPARC
	SPARC = 2,
	// Intel i386
	I386 = 3,
	// Motorola 68000
	M68K = 4,
	// Motorola 88000
	M88K = 5,
	// Intel i860
	M860 = 7,
	// MIPS R3000 Big-Endian only
	MIPS = 8,
	// IBM System/370
	S370 = 9,
	// MIPS R3000 Little-Endian
	MIPS_RS3_LE = 10,
	// HP PA-RISC
	PARISC = 15,
	// Fujitsu VPP500
	VPP500 = 17,
	// SPARC v8plus
	SPARC32PLUS = 18,
	// Intel 80960
	I960 = 19,
	// PowerPC 32-bit
	PPC = 20,
	// PowerPC 64-bit
	PPC64 = 21,
	// IBM System/390
	S390 = 22,
	// NEC V800
	V800 = 36,
	// Fujitsu FR20
	FR20 = 37,
	// TRW RH-32
	RH32 = 38,
	// Motorola RCE
	RCE = 39,
	// ARM
	ARM = 40,
	// Hitachi SH
	SH = 42,
	// SPARC v9 64-bit
	SPARCV9 = 43,
	// Siemens TriCore embedded processor
	TRICORE = 44,
	// Argonaut RISC Core
	ARC = 45,
	// Hitachi H8/300
	H8_300 = 46,
	// Hitachi H8/300H
	H8_300H = 47,
	// Hitachi H8S
	H8S = 48,
	// Hitachi H8/500
	H8_500 = 49,
	// Intel IA-64 Processor
	IA_64 = 50,
	// Stanford MIPS-X
	MIPS_X = 51,
	// Motorola ColdFire
	COLDFIRE = 52,
	// Motorola M68HC12
	M68HC12 = 53,
	// Fujitsu MMA
	MMA = 54,
	// Siemens PCP
	PCP = 55,
	// Sony nCPU
	NCPU = 56,
	// Denso NDR1 microprocessor
	NDR1 = 57,
	// Motorola Star*Core processor
	STARCORE = 58,
	// Toyota ME16 processor
	ME16 = 59,
	// STMicroelectronics ST100 processor
	ST100 = 60,
	// Advanced Logic Corp. TinyJ processor
	TINYJ = 61,
	// Advanced Micro Devices x86-64
	X86_64 = 62,
	// Sony DSP Processor
	PDSP = 63,
	// Digital Equipment Corp. PDP-10
	PDP10 = 64,
	// Digital Equipment Corp. PDP-11
	PDP11 = 65,
	// Siemens FX66 microcontroller
	FX66 = 66,
	// STMicroelectronics ST9+ 8/16 bit microcontroller
	ST9PLUS = 67,
	// STMicroelectronics ST7 8-bit microcontroller
	ST7 = 68,
	// Motorola MC68HC16 Microcontroller
	M68HC16 = 69,
	// Motorola MC68HC11 Microcontroller
	M68HC11 = 70,
	// Motorola MC68HC08 Microcontroller
	M68HC08 = 71,
	// Motorola MC68HC05 Microcontroller
	M68HC05 = 72,
	// Silicon Graphics SVx
	SVX = 73,
	// STMicroelectronics ST19 8-bit microcontroller
	ST19 = 74,
	// Digital VAX
	VAX = 75,
	// Axis Communications 32-bit embedded processor
	CRIS = 76,
	// Infineon Technologies 32-bit embedded processor
	JAVELIN = 77,
	// Element 14 64-bit DSP Processor
	FIREPATH = 78,
	// LSI Logic 16-bit DSP Processor
	ZSP = 79,
	// Donald Knuth's educational 64-bit processor
	MMIX = 80,
	// Harvard University machine-independent object files
	HUANY = 81,
	// SiTera Prism
	PRISM = 82,
	// Atmel AVR 8-bit microcontroller
	AVR = 83,
	// Fujitsu FR30
	FR30 = 84,
	// Mitsubishi D10V
	D10V = 85,
	// Mitsubishi D30V
	D30V = 86,
	// NEC v850
	V850 = 87,
	// Mitsubishi M32R
	M32R = 88,
	// Matsushita MN10300
	MN10300 = 89,
	// Matsushita MN10200
	MN10200 = 90,
	// picoJava
	PJ = 91,
	// OpenRISC 32-bit embedded processor
	OPENRISC = 92,
	// ARC International ARCompact processor
	ARC_COMPACT = 93,
	// Tensilica Xtensa Architecture
	XTENSA = 94,
	// Alphamosaic VideoCore processor
	VIDEOCORE = 95,
	// Thompson Multimedia General Purpose Processor
	TMM_GPP = 96,
	// National Semiconductor 32000 series
	NS32K = 97,
	// Tenor Network TPC processor
	TPC = 98,
	// Trebia SNP 1000 processor
	SNP1K = 99,
	// STMicroelectronics (www.st.com) ST200 microcontroller
	ST200 = 100,
	// Ubicom IP2xxx microcontroller family
	IP2K = 101,
	// MAX Processor
	MAX = 102,
	// National Semiconductor CompactRISC microprocessor
	CR = 103,
	// Fujitsu F2MC16
	F2MC16 = 104,
	// Texas Instruments embedded microcontroller msp430
	MSP430 = 105,
	// Analog Devices Blackfin (DSP) processor
	BLACKFIN = 106,
	// S1C33 Family of Seiko Epson processors
	SE_C33 = 107,
	// Sharp embedded microprocessor
	SEP = 108,
	// Arca RISC Microprocessor
	ARCA = 109,
	// Microprocessor series from PKU-Unity Ltd. and MPRC of Peking University
	UNICORE = 110,
	// eXcess: 16/32/64-bit configurable embedded CPU
	EXCESS = 111,
	// Icera Semiconductor Inc. Deep Execution Processor
	DXP = 112,
	// Altera Nios II soft-core processor
	ALTERA_NIOS2 = 113,
	// National Semiconductor CompactRISC CRX microprocessor
	CRX = 114,
	// Motorola XGATE embedded processor
	XGATE = 115,
	// Infineon C16x/XC16x processor
	C166 = 116,
	// Renesas M16C series microprocessors
	M16C = 117,
	// Microchip Technology dsPIC30F Digital Signal Controller
	DSPIC30F = 118,
	// Freescale Communication Engine RISC core
	CE = 119,
	// Renesas M32C series microprocessors
	M32C = 120,
	// Altium TSK3000 core
	TSK3000 = 131,
	// Freescale RS08 embedded processor
	RS08 = 132,
	// Analog Devices SHARC family of 32-bit DSP processors
	SHARC = 133,
	// Cyan Technology eCOG2 microprocessor
	ECOG2 = 134,
	// Sunplus S+core7 RISC processor
	SCORE7 = 135,
	// New Japan Radio (NJR) 24-bit DSP Processor
	DSP24 = 136,
	// Broadcom VideoCore III processor
	VIDEOCORE3 = 137,
	// RISC processor for Lattice FPGA architecture
	LATTICEMICO32 = 138,
	// Seiko Epson C17 family
	SE_C17 = 139,
	// The Texas Instruments TMS320C6000 DSP family
	TI_C6000 = 140,
	// The Texas Instruments TMS320C2000 DSP family
	TI_C2000 = 141,
	// The Texas Instruments TMS320C55x DSP family
	TI_C5500 = 142,
	// Texas Instruments Application Specific RISC Processor, 32bit fetch
	TI_ARP32 = 143,
	// Texas Instruments Programmable Realtime Unit
	TI_PRU = 144,
	// STMicroelectronics 64bit VLIW Data Signal Processor
	MMDSP_PLUS = 160,
	// Cypress M8C microprocessor
	CYPRESS_M8C = 161,
	// Renesas R32C series microprocessors
	R32C = 162,
	// NXP Semiconductors TriMedia architecture family
	TRIMEDIA = 163,
	// QUALCOMM DSP6 Processor
	QDSP6 = 164,
	// Intel 8051 and variants
	I8051 = 165,
	// STMicroelectronics STxP7x family of configurable and extensible RISC processors
	STXP7X = 166,
	// Andes Technology compact code size embedded RISC processor family
	NDS32 = 167,
	// Cyan Technology eCOG1X family
	ECOG1 = 168,
	// Cyan Technology eCOG1X family
	ECOG1X = 168,
	// Dallas Semiconductor MAXQ30 Core Micro-controllers
	MAXQ30 = 169,
	// New Japan Radio (NJR) 16-bit DSP Processor
	XIMO16 = 170,
	// M2000 Reconfigurable RISC Microprocessor
	MANIK = 171,
	// Cray Inc. NV2 vector architecture
	CRAYNV2 = 172,
	// Renesas RX family
	RX = 173,
	// Imagination Technologies META processor architecture
	METAG = 174,
	// MCST Elbrus general purpose hardware architecture
	MCST_ELBRUS = 175,
	// Cyan Technology eCOG16 family
	ECOG16 = 176,
	// National Semiconductor CompactRISC CR16 16-bit microprocessor
	CR16 = 177,
	// Freescale Extended Time Processing Unit
	ETPU = 178,
	// Infineon Technologies SLE9X core
	SLE9X = 179,
	// Intel L10M
	L10M = 180,
	// Intel K10M
	K10M = 181,
	// ARM 64-bit Architecture (AArch64)
	AARCH64 = 183,
	// Atmel Corporation 32-bit microprocessor family
	AVR32 = 185,
	// STMicroeletronics STM8 8-bit microcontroller
	STM8 = 186,
	// Tilera TILE64 multicore architecture family
	TILE64 = 187,
	// Tilera TILEPro multicore architecture family
	TILEPRO = 188,
	// Xilinx MicroBlaze 32-bit RISC soft processor core
	MICROBLAZE = 189,
	// NVIDIA CUDA architecture
	CUDA = 190,
	// Tilera TILE-Gx multicore architecture family
	TILEGX = 191,
	// CloudShield architecture family
	CLOUDSHIELD = 192,
	// KIPO-KAIST Core-A 1st generation processor family
	COREA_1ST = 193,
	// KIPO-KAIST Core-A 2nd generation processor family
	COREA_2ND = 194,
	// Synopsys ARCompact V2
	ARC_COMPACT2 = 195,
	// Open8 8-bit RISC soft processor core
	OPEN8 = 196,
	// Renesas RL78 family
	RL78 = 197,
	// Broadcom VideoCore V processor
	VIDEOCORE5 = 198,
	// Renesas 78KOR family
	R78KOR = 199,
	// Freescale 56800EX Digital Signal Controller (DSC)
	F56800EX = 200,
	// Beyond BA1 CPU architecture
	BA1 = 201,
	// Beyond BA2 CPU architecture
	BA2 = 202,
	// XMOS xCORE processor family
	XCORE = 203,
	// Microchip 8-bit PIC(r) family
	MCHP_PIC = 204,
	// Reserved by Intel
	INTEL205 = 205,
	// Reserved by Intel
	INTEL206 = 206,
	// Reserved by Intel
	INTEL207 = 207,
	// Reserved by Intel
	INTEL208 = 208,
	// Reserved by Intel
	INTEL209 = 209,
	// KM211 KM32 32-bit processor
	KM32 = 210,
	// KM211 KMX32 32-bit processor
	KMX32 = 211,
	// KM211 KMX16 16-bit processor
	KMX16 = 212,
	// KM211 KMX8 8-bit processor
	KMX8 = 213,
	// KM211 KVARC processor
	KVARC = 214,
	// Paneve CDP architecture family
	CDP = 215,
	// Cognitive Smart Memory Processor
	COGE = 216,
	// Bluechip Systems CoolEngine
	COOL = 217,
	// Nanoradio Optimized RISC
	NORC = 218,
	// CSR Kalimba architecture family
	CSR_KALIMBA = 219,
	// Zilog Z80
	Z80 = 220,
	// Controls and Data Services VISIUMcore processor
	VISIUM = 221,
	// FTDI Chip FT32 high performance 32-bit RISC architecture
	FT32 = 222,
	// Moxie processor family
	MOXIE = 223,
	// AMD GPU architecture
	AMDGPU = 224,
	// RISC-V
	RISCV = 243,
	// Lanai 32-bit processor
	LANAI = 244,
	// Linux BPF – in-kernel virtual machine
	BPF = 247,

	// Intel i486 (deprecated)
	I486 = 6,
	// MIPS R4000 Big-Endian (deprecated)
	MIPS_RS4_BE = 10,
	// Digital Alpha (deprecated)
	ALPHA_STD = 41,
	// Alpha (deprecated)
	ALPHA = 0x9026,
};

// ELF file type
export type elf_type = enum u16 {
	// No file type
	NONE = 0,
	// Relocatable object file
	REL = 1,
	// Executable file
	EXEC = 2,
	// Shared object file
	DYN = 3,
	// Core file
	CORE = 4,
	// Environment-specific use
	LOOS = 0xFE00,
	// Environment-specific use
	HIOS = 0xFEFF,
	// Processor-specific use
	LOPROC = 0xFF00,
	// Processor-specific use
	HIPROC = 0xFFFF,
};

// Application binary interface
export type ident_abi = enum u8 {
	// System-V ABI
	SYSV = 0,
	// HP-UX operating system
	HPUX = 1,
	// Standalone (embedded) application
	STANDALONE = 255,
};

// Special section indicies
export type shn = enum u16 {
	// Used to mark an undefined or meaningless section reference
	UNDEF = 0,
	// Processor-specific use
	LOPROC = 0xFF00,
	// Processor-specific use
	HIPROC = 0xFF1F,
	// Environment-specific-use
	LOOS = 0xFF20,
	// Environment-specific-use
	HIOS = 0xFF3F,
	// Indicates that the corresponding reference is an absolute value
	ABS = 0xFFF1,
	// Indicates a symbol that has been declared as a common block
	COMMON = 0xFFF2,
};

// Section type
export type sht = enum u32 {
	// Marks an unused section header
	NULL = 0,
	// Contains information defined by the program
	PROGBITS = 1,
	// Contains a linker symbol table
	SYMTAB = 2,
	// Contains a string table
	STRTAB = 3,
	// Contains "Rela" type relocation entries
	RELA = 4,
	// Contains a symbol hash table
	HASH = 5,
	// Contains dynamic linking tables
	DYNAMIC = 6,
	// Contains note information
	NOTE = 7,
	// Contains uninitialized space; does not occupy any space in the file
	NOBITS = 8,
	// Contains "Rel" type relocation entries
	REL = 9,
	// Reserved
	SHLIB = 10,
	// Contains a dynamic loader symbol table
	DYNSYM = 11,
	// Environment-specific use
	LOOS = 0x60000000,
	// Environment-specific use
	HIOS = 0x6FFFFFFF,
	// Processor-specific use
	LOPROC = 0x70000000,
	// Processor-specific use
	HIPROC = 0x7FFFFFFF,
};

// Section flags
export type shf = enum u32 {
	// Section contains no data
	NONE = 0,
	// Section contains writable data
	WRITE = 0x1,
	// Section is allocated in memory image of program
	ALLOC = 0x2,
	// Section contains executable instructions
	EXECINSTR = 0x4,
	// Environment-specific use
	MASKOS = 0x0F000000,
	// Processor-specific use
	MASKPROC = 0xF0000000,
};

// Symbol table entry
export type sym64 = struct {
	// Symbol name offset
	st_name: u32,
	// Type and binding attributes
	st_info: u8,
	// Reserved
	st_other: u8,
	// Section table index
	st_shndx: u16,
	// Symbol value
	st_value: u64,
	// Size of object
	st_size: u64,
};

// Symbol bindings
export type stb = enum u8 {
	// Not visible outside the object file
	LOCAL = 0,
	// Global symbol, visible to all object files
	GLOBAL = 1,
	// Global scope, but with lower precedence than global symbols
	WEAK = 2,
	// Environment-specific use
	LOOS = 10,
	// Environment-specific use
	HIOS = 12,
	// Processor-specific use
	LOPROC = 13,
	// Processor-specific use
	HIPROC = 15,
};

// Obtains the binding part of [sym64.st_info].
//
// Equivalent to the ELF64_ST_BIND macro.
export fn st_bind(i: u8) stb = (i >> 4): stb;

// Symbol types
export type stt = enum u8 {
	// No type specified (e.g. an absolute symbol)
	NOTYPE = 0,
	// Data object
	OBJECT = 1,
	// Function entry point
	FUNC = 2,
	// Symbol is associated with a section
	SECTION = 3,
	// Source file associated with the object
	FILE = 4,
	// Symbol is a common data object
	COMMON = 5,
	// Environment-specific use
	LOOS = 10,
	// Environment-specific use
	HIOS = 12,
	// Processor-specific use
	LOPROC = 13,
	// Processor-specific use
	HIPROC = 15,
};

// Obtains the type part of [sym64.st_info].
//
// Equivalent to the ELF64_ST_TYPE macro.
export fn st_type(i: u8) stt = (i & 0xF): stt;

// Converts symbol bindings and type into [sym64.st_info].
//
// Equivalent to the ELF64_ST_INFO macro.
export fn st_info(b: stb, t: stt) u8 = b: u8 << 4 + t: u8 & 0xF;

// Relocation entry
export type rel64 = struct {
	// Address of reference
	r_offset: u64,
	// Symbol table index and type of relocation
	r_info: u64,
};

// Relocation entry with explicit addend
export type rela64 = struct {
	// Address of reference
	r_offset: u64,
	// Symbol table index and type of relocation
	r_info: u64,
	// Constant part of expression
	r_addend: i64,
};

// Obtains the symbol table index part of [rel64.r_info].
//
// Equivalent to the ELF64_R_SYM macro.
export fn r64_sym(info: u64) u64 = info >> 32;

// Obtains the relocation type part of [rel64.r_info].
//
// Equivalent to the ELF64_R_TYPE macro.
export fn r64_type(info: u64) u64 = info & 0xFFFFFFFF;

// Converts symbol table index and a relocation type into [rel64.r_info].
//
// Equivalent to the ELF64_R_INFO macro.
export fn r64_info(sym: u64, stype: u64) u64 = sym << 32 | stype & 0xFFFFFFFF;

// Program header table entry (segment)
export type phdr64 = struct {
	// Type of segment
	p_type: pt,
	// Segment attributes
	p_flags: u32,
	// Offset in file
	p_offset: u64,
	// Virtual address in memory
	p_vaddr: u64,
	// Reserved
	p_paddr: u64,
	// Size of segment in file
	p_filesz: u64,
	// Size of segment in memory
	p_memsz: u64,
	// Alignment of segment
	p_align: u64,
};

// Segment types
export type pt = enum u32 {
	// Unused entry
	NULL = 0,
	// Loadable segment
	LOAD = 1,
	// Dynamic linking tables
	DYNAMIC = 2,
	// Program interpreter path name
	INTERP = 3,
	// Note sections
	NOTE = 4,
	// Reserved
	SHLIB = 5,
	// Program header table
	PHDR = 6,
	// Environment-specific use
	LOOS = 0x60000000,
	// Environment-specific use
	HIOS = 0x6FFFFFFF,
	// Processor-specific use
	LOPROC = 0x70000000,
	// Processor-specific use
	HIPROC = 0x7FFFFFFF,
};

// Segment attributes
export type pf = enum u32 {
	// No permission
	NONE = 0,
	// Execute permission
	X = 0x1,
	// Write permission
	W = 0x2,
	// Read permission
	R = 0x4,
	// Reserved for environment-specific use
	MASKOS = 0x00FF0000,
	// Reserved for processor-specific use
	MASKPROC = 0xFF000000,
};

// Dynamic table entry
export type dyn64 = struct {
	// The type of this entry
	d_tag: dt,
	// Additional data associated with this entry. The value which is valid
	// is selected based on the entry type.
	union {
		d_val: u64,
		d_ptr: u64,
	},
};

// Dynamic table entry type
export type dt = enum i64 {
	// Marks the end of the dynamic array.
	NULL = 0,
	// The string table offset of the name of a needed library.
	NEEDED = 1,
	// Total size, in bytes, of the relocation entries associated with the
	// procedure linkage table.
	PLTRELSZ = 2,
	// Contains an address associated with the linkage table. The specific
	// meaning of this field is processor-dependent.
	PLTGOT = 3,
	// Address of the symbol hash table.
	HASH = 4,
	// Address of the dynamic string table.
	STRTAB = 5,
	// Address of the dynamic symbol table.
	SYMTAB = 6,
	// Address of a relocation table with rela64 entries.
	RELA = 7,
	// Total size, in bytes, of the RELA relocation table.
	RELASZ = 8,
	// Size, in bytes, of each RELA relocation entry.
	RELAENT = 9,
	// Total size, in bytes, of the string table.
	STRSZ = 10,
	// Size, in bytes, of each symbol table entry.
	SYMENT = 11,
	// Address of the initialization function.
	INIT = 12,
	// Address of the termination function.
	FINI = 13,
	// The string table offset of the name of this shared object.
	SONAME = 14,
	// The string table offset of a shared library search path string.
	RPATH = 15,
	// The presence of this dynamic table entry modifies the symbol
	// resolution algorithm for references within the library. Symbols
	// defined within the library are used to resolve references before the
	// dynamic linker searches the usual search path.
	SYMBOLIC = 16,
	// Address of a relocation table with rel64 entries.
	REL = 17,
	// Total size, in bytes, of the REL relocation table.
	RELSZ = 18,
	// Size, in bytes, of each REL relocation entry.
	RELENT = 19,
	// Type of relocation entry used for the procedure linkage table. The
	// d_val member contains either [dt::REL] or [dt::RELA].
	PLTREL = 20,
	// Reserved for debugger use.
	DEBUG = 21,
	// The presence of this dynamic table entry signals that the relocation
	// table contains relocations for a non-writable segment.
	TEXTREL = 22,
	// Address of the relocations associated with the procedure linkage
	// table.
	JMPREL = 23,
	// The presence of this dynamic table entry signals that the dynamic
	// loader should process all relocations for this object before
	// transferring control to the program.
	BIND_NOW = 24,
	// Pointer to an array of initialiation functions.
	INIT_ARRAY = 25,
	// Pointer to an array of termination functions.
	FINI_ARRAY = 26,
	// Size, in bytes, of the array of initialization functions.
	INIT_ARRAYSZ = 27,
	// Size, in bytes, of the array of termination functions.
	FINI_ARRAYSZ = 28,
	// Reserved for environment-specific use.
	LOOS = 0x60000000,

	// Symbol versioning entry types, GNU extension
	// Version table records
	// .gnu.version  section address
	VERSYM = 0x6FFFFFF0,
	// .gnu.version_d section address
	VERDEF = 0x6FFFFFFC,
	// Number of version definitions
	VERDEFNUM = 0x6FFFFFFD,
	// .gnu.version_r section address
	VERNEED = 0x6FFFFFFE,
	// Number of needed versions
	VERNEEDNUM = 0x6FFFFFFF,

	// Reserved for environment-specific use.
	HIOS = 0x6FFFFFFF,
	// Reserved for processor-specific use.
	LOPROC = 0x70000000,
	// Reserved for processor-specific use.
	HIPROC = 0x7FFFFFFF,
};

// Auxiliary vector
export type auxv64 = struct {
	// Entry type
	a_type: at,
	union {
		// Integer value
		a_val: u64,
		a_ptr: *opaque,
		a_fnc: *fn() void,
	}
};

// Legal auxiliary vector entry types
export type at = enum u64 {
	// End of vector
	NULL = 0,
	// Entry should be ignored
	IGNORE = 1,
	// File descriptor of program
	EXECFD = 2,
	// Program headers for program
	PHDR = 3,
	// Size of program header entry
	PHENT = 4,
	// Number of program headers
	PHNUM = 5,
	// System page size
	PAGESZ = 6,
	// Base address of interpreter
	BASE = 7,
	// Flags
	FLAGS = 8,
	// Entry point of program
	ENTRY = 9,
	// Program is not ELF
	NOTELF = 10,
	// Real uid
	UID = 11,
	// Effective uid
	EUID = 12,
	// Real gid
	GID = 13,
	// Effective gid
	EGID = 14,
	// Frequency of times()
	CLKTCK = 17,

	// String identifying platform.
	PLATFORM = 15,
	// Machine-dependent hints about processor capabilities.
	HWCAP = 16,

	// Used FPU control word.
	FPUCW = 18,

	// Data cache block size.
	DCACHEBSIZE = 19,
	// Instruction cache block size.
	ICACHEBSIZE = 20,
	// Unified cache block size.
	UCACHEBSIZE = 21,

	// A special ignored value for PPC, used by the kernel to control the
	// interpretation of the AUXV. Must be > 16.
	// Entry should be ignored.
	IGNOREPPC = 22,
	// Boolean, was exec setuid-like?
	SECURE = 23,
	// String identifying real platforms.
	BASE_PLATFORM = 24,
	// Address of 16 random bytes.
	RANDOM = 25,
	// More machine-dependent hints about processor capabilities.
	HWCAP2 = 26,
	// Filename of executable.
	EXECFN = 31,

	// Pointer to the global system page used for system calls and other
	// nice things.
	SYSINFO = 32,
	SYSINFO_EHDR = 33,

	// Shapes of the caches.  Bits 0-3 contains associativity, bits 4-7 contains
	// log2 of line size, mask those to get cache size.
	L1I_CACHESHAPE = 34,
	L1D_CACHESHAPE = 35,
	L2_CACHESHAPE = 36,
	L3_CACHESHAPE = 37,

	// Shapes of the caches, with more room to describe them.
	// *GEOMETRY are comprised of cache line size in bytes in the bottom 16 bits
	// and the cache associativity in the next 16 bits.
	L1I_CACHESIZE = 40,
	L1I_CACHEGEOMETRY = 41,
	L1D_CACHESIZE = 42,
	L1D_CACHEGEOMETRY = 43,
	L2_CACHESIZE = 44,
	L2_CACHEGEOMETRY = 45,
	L3_CACHESIZE = 46,
	L3_CACHEGEOMETRY = 47,

	// Stack needed for signal delivery (AArch64).
	MINSIGSTKSZ = 51,
};

// Version definition section
export type verdef64 = struct {
	// Version revision
	vd_version: u16,
	// Version information
	vd_flags: u16,
	// Version Index
	vd_ndx: u16,
	// Number of associated aux entries
	vd_cnt: u16,
	// Version name hash value
	vd_hash: u32,
	// Offset in bytes to verdaux array
	vd_aux: u32,
	// Offset in bytes to next verdef entry
	vd_next: u32,
};

// Auxiliary version information
export type verdaux64 = struct {
	vda_name: u32,
	vda_next: u32,
};

// Version revision values
export type ver_def = enum u16 {
	NONE = 0,
	CURRENT = 1,
	NUM = 2,
};

// Version information flags
export type ver_flg = enum u16 {
	BASE = 0x1,
	WEAK = 0x2,
};

// Versym index values
export type ver_ndx = enum u16 {
	LOCAL = 0,
	GLOBAL = 1,
	LORESERVE = 0xff00,
	ELIMINATE = 0xff01,
};

// DT_HASH section header
export type hashhdr = struct {
	nbucket: u32,
	nchain: u32,
};
