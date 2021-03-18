// An implementation of the ELF64 file format. Best accompanied with a reading
// of the ELF-64 Object Format (Version 1.5).
//
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
	e_machine: u16,
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

// Application binary interface
export type ident_abi = enum u8 {
	// System-V ABI
	SYSV = 0,
	// HP-UX operating system
	HPUX = 1,
	// Standalone (embedded) application
	STANDALONE = 255,
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
	LOPROC = 0x7000000,
	// Processor-specific use
	HIPROC = 0x7FFFFFF,
};

// Section flags
export type shf = enum u32 {
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
	REALENT = 9,
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

// Auxillary vector
export type auxv64 = struct {
	a_type: u64, // Entry type
	union {
		a_val: u64, // Integer value
	}
};

// Legal auxillary vector entry types
export type at = enum u32 {
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

// Auxillary version information
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
