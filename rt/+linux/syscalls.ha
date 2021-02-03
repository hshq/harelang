fn syscall0(u64) u64;
fn syscall1(u64, u64) u64;
fn syscall2(u64, u64, u64) u64;
fn syscall3(u64, u64, u64, u64) u64;
fn syscall4(u64, u64, u64, u64, u64) u64;
fn syscall5(u64, u64, u64, u64, u64, u64) u64;
fn syscall6(u64, u64, u64, u64, u64, u64, u64) u64;

export fn read(fd: int, buf: *void, count: size) size =
	syscall3(SYS_read, fd: u64, buf: uintptr: u64, count: u64): size;

export fn write(fd: int, buf: *const void, count: size) size =
	syscall3(SYS_write, fd: u64, buf: uintptr: u64, count: u64): size;

export fn open(path: *const char, flags: int, mode: uint) size =
	syscall3(SYS_open, path: uintptr: u64, flags: u64, mode: u64): size;

export fn close(fd: int) int = syscall1(SYS_close, fd: u64): int;

export fn getpid() int = syscall0(SYS_getpid): int;

export fn sendfile(out: int, in: int, offs: nullable *size, count: size) size =
	syscall4(SYS_sendfile, out: u64, in: u64, offs: uintptr: u64, count: u64): size;

export @noreturn fn exit(status: int) void = syscall1(SYS_exit, status: u64);

export fn kill(pid: int, signal: int) int =
	syscall2(SYS_kill, pid: u64, signal: u64): int;

export def SIGHUP: int		= 1;
export def SIGINT: int		= 2;
export def SIGQUIT: int		= 3;
export def SIGILL: int		= 4;
export def SIGTRAP: int		= 5;
export def SIGABRT: int		= 6;
export def SIGBUS: int		= 7;
export def SIGFPE: int		= 8;
export def SIGKILL: int		= 9;
export def SIGUSR1: int		= 10;
export def SIGSEGV: int		= 11;
export def SIGUSR2: int		= 12;
export def SIGPIPE: int		= 13;
export def SIGALRM: int		= 14;
export def SIGTERM: int		= 15;
export def SIGSTKFLT: int	= 16;
export def SIGCHLD: int		= 17;
export def SIGCONT: int		= 18;
export def SIGSTOP: int		= 19;
export def SIGTSTP: int		= 20;
export def SIGTTIN: int		= 21;
export def SIGTTOU: int		= 22;
export def SIGURG: int		= 23;
export def SIGXCPU: int		= 24;
export def SIGXFSZ: int		= 25;
export def SIGVTALRM: int	= 26;
export def SIGPROF: int		= 27;
export def SIGWINCH: int	= 28;
export def SIGIO: int		= 29;
export def SIGPOLL: int		= 29;
export def SIGPWR: int		= 30;
export def SIGSYS: int		= 31;

export def MAP_SHARED: uint		= 0x01u;
export def MAP_PRIVATE: uint		= 0x02u;
export def MAP_SHARED_VALIDATE: uint	= 0x03u;
export def MAP_FIXED: uint		= 0x10u;
export def MAP_ANON: uint		= 0x20u;
export def MAP_NORESERVE: uint		= 0x4000u;
export def MAP_GROWSDOWN: uint		= 0x0100u;
export def MAP_DENYWRITE: uint		= 0x0800u;
export def MAP_EXECUTABLE: uint		= 0x1000u;
export def MAP_LOCKED: uint		= 0x2000u;
export def MAP_POPULATE: uint		= 0x8000u;
export def MAP_NONBLOCK: uint		= 0x10000u;
export def MAP_STACK: uint		= 0x20000u;
export def MAP_HUGETLB: uint		= 0x40000u;
export def MAP_SYNC: uint		= 0x80000u;
export def MAP_FIXED_NOREPLACE: uint	= 0x100000u;
export def MAP_FILE: uint		= 0u;
export def MAP_HUGE_SHIFT: uint		= 26u;
export def MAP_HUGE_MASK: uint		= 0x3fu;
export def MAP_HUGE_64KB: uint		= 16u << 26u;
export def MAP_HUGE_512KB: uint		= 19u << 26u;
export def MAP_HUGE_1MB: uint		= 20u << 26u;
export def MAP_HUGE_2MB: uint		= 21u << 26u;
export def MAP_HUGE_8MB: uint		= 23u << 26u;
export def MAP_HUGE_16MB: uint		= 24u << 26u;
export def MAP_HUGE_32MB: uint		= 25u << 26u;
export def MAP_HUGE_256MB: uint		= 28u << 26u;
export def MAP_HUGE_512MB: uint		= 29u << 26u;
export def MAP_HUGE_1GB: uint		= 30u << 26u;
export def MAP_HUGE_2GB: uint		= 31u << 26u;
export def MAP_HUGE_16GB: uint		= 34u << 26u;

export def PROT_NONE: uint	= 0u;
export def PROT_READ: uint 	= 1u;
export def PROT_WRITE: uint	= 2u;
export def PROT_EXEC: uint	= 4u;
export def PROT_GROWSDOWN: uint	= 0x01000000u;
export def PROT_GROWSUP: uint	= 0x02000000u;

export fn mmap(
	addr: nullable *void,
	length: size,
	prot: uint,
	flags: uint,
	fd: int,
	offs: size
) *void = {
	let r: u64 = syscall6(SYS_mmap, addr: uintptr: u64,
		length: u64, prot: u64, flags: u64, fd: u64, offs: u64): u64;
	// TODO: Type promotion
	return if (r: int == -EPERM && addr: uintptr == null: uintptr
			&& (flags & MAP_ANON) > 0u && (flags & MAP_FIXED) == 0u) {
		(-ENOMEM): uintptr: *void; // Fix up incorrect EPERM from kernel
	} else r: uintptr: *void;
};

export fn munmap(addr: *void, length: size) int =
	syscall2(SYS_munmap, addr: uintptr: u64, length: u64): int;

export fn mprotect(addr: *void, length: size, prot: uint) int =
	syscall3(SYS_mprotect, addr: uintptr: u64, length: u64, prot: u64): int;
