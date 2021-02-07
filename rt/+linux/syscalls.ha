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

export fn open(path: *const char, flags: int, mode: uint) size = {
	return syscall4(SYS_openat, AT_FDCWD: u64,
		path: uintptr: u64, flags: u64, mode: u64): size;
};

export fn close(fd: int) int = syscall1(SYS_close, fd: u64): int;

export fn getpid() int = syscall0(SYS_getpid): int;

export fn sendfile(out: int, in: int, offs: nullable *size, count: size) size =
	syscall4(SYS_sendfile, out: u64, in: u64, offs: uintptr: u64, count: u64): size;

export @noreturn fn exit(status: int) void = syscall1(SYS_exit, status: u64);

export fn kill(pid: int, signal: int) int =
	syscall2(SYS_kill, pid: u64, signal: u64): int;

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

export fn lseek(fd: int, off: i64, whence: uint) i64 =
	syscall3(SYS_lseek, fd: u64, off: u64, whence: u64): i64;
