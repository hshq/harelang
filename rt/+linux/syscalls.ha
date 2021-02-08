fn syscall0(u64) u64;
fn syscall1(u64, u64) u64;
fn syscall2(u64, u64, u64) u64;
fn syscall3(u64, u64, u64, u64) u64;
fn syscall4(u64, u64, u64, u64, u64) u64;
fn syscall5(u64, u64, u64, u64, u64, u64) u64;
fn syscall6(u64, u64, u64, u64, u64, u64, u64) u64;

export fn read(fd: int, buf: *void, count: size) (size | errno) = {
	return match (wrap_return(syscall3(SYS_read,
			fd: u64, buf: uintptr: u64, count: u64))) {
		err: errno => err,
		n: u64 => n: size,
	};
};

export fn write(fd: int, buf: *const void, count: size) (size | errno) = {
	return match (wrap_return(syscall3(SYS_write,
			fd: u64, buf: uintptr: u64, count: u64))) {
		err: errno => err,
		n: u64 => n: size,
	};
};

export fn open(path: *const char, flags: int, mode: uint) (int | errno) = {
	return match (wrap_return(syscall4(SYS_openat, AT_FDCWD: u64,
			path: uintptr: u64, flags: u64, mode: u64))) {
		err: errno => err,
		n: u64 => n: int,
	};
};

export fn close(fd: int) (void | errno) = {
	return match (wrap_return(syscall1(SYS_close, fd: u64))) {
		err: errno => err,
		u64 => void,
	};
};

export fn execveat(dirfd: int, path: *const char, argv: *[*]nullable *const char,
		envp: *[*]nullable *const char, flags: int) errno = {
	return match (wrap_return(syscall5(SYS_execveat, dirfd: u64,
			path: uintptr: u64, argv: uintptr: u64,
			envp: uintptr: u64, flags: u64))) {
		err: errno => err,
		u64 => abort("unreachable"),
	};
};

// Returns the new PID to the parent, void to the child, or errno if something
// goes wrong.
export fn fork() (int | void | errno) = clone(null, SIGCHLD, null, null, 0u64);

export fn getpid() int = syscall0(SYS_getpid): int;

export fn sendfile(
	out: int,
	in: int,
	offs: nullable *size,
	count: size,
) (size | errno) = match (wrap_return(syscall4(SYS_sendfile,
		out: u64, in: u64, offs: uintptr: u64, count: u64))) {
	n: u64 => n: size,
	err: errno => err,
};
	
export @noreturn fn exit(status: int) void = syscall1(SYS_exit, status: u64);

export fn kill(pid: int, signal: int) (void | errno) = {
	return match (wrap_return(syscall2(SYS_kill, pid: u64, signal: u64))) {
		err: errno => err,
		u64 => void,
	};
};

export fn pipe2(pipefd: *[2]int, flags: int) (void | errno) = {
	return match (wrap_return(syscall2(SYS_pipe2,
			pipefd: uintptr: u64, flags: u64))) {
		err: errno => err,
		u64 => void,
	};
};

export fn mmap(
	addr: nullable *void,
	length: size,
	prot: uint,
	flags: uint,
	fd: int,
	offs: size
) (*void | errno) = {
	let r = syscall6(SYS_mmap, addr: uintptr: u64,
		length: u64, prot: u64, flags: u64, fd: u64, offs: u64);
	match (wrap_return(r)) {
		err: errno => {
			// XXX: Type promotion would simplify this
			return if (r: int == -EPERM
					&& addr: uintptr == null: uintptr
					&& (flags & MAP_ANON) > 0u
					&& (flags & MAP_FIXED) == 0u) {
				 // Fix up incorrect EPERM from kernel:
				wrap_errno(ENOMEM);
			} else err;
		},
		n: u64 => n: uintptr: *void,
	};
};

export fn munmap(addr: *void, length: size) (void | errno) = {
	return match (wrap_return(syscall2(SYS_munmap,
			addr: uintptr: u64, length: u64))) {
		err: errno => err,
		u64 => void,
	};
};
	

export fn mprotect(addr: *void, length: size, prot: uint) (void | errno) = {
	return match (wrap_return(syscall3(SYS_mprotect,
			addr: uintptr: u64, length: u64, prot: u64))) {
		err: errno => err,
		u64 => void,
	};
};
	

export fn lseek(fd: int, off: i64, whence: uint) (i64 | errno) = {
	return match (wrap_return(syscall3(SYS_lseek,
			fd: u64, off: u64, whence: u64))) {
		err: errno => err,
		n: u64 => n: i64,
	};
};
