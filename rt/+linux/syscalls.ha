fn syscall0(u64) u64;
fn syscall1(u64, u64) u64;
fn syscall2(u64, u64, u64) u64;
fn syscall3(u64, u64, u64, u64) u64;
fn syscall4(u64, u64, u64, u64, u64) u64;
fn syscall5(u64, u64, u64, u64, u64, u64) u64;
fn syscall6(u64, u64, u64, u64, u64, u64, u64) u64;

export type path = (str | []u8 | *const char);

// NUL terminates a string and stores it in a static buffer of PATH_MAX+1 bytes
// in length.
fn kpath(path: path) (*const char | errno) = {
	static let buf: [4097]u8 = [0...];
	let path = match (path) {
		c: *const char => return c,
		s: str => {
			let ptr = &s: *struct {
				buf: *[*]u8,
				length: size,
				capacity: size,
			};
			ptr.buf[..ptr.length];
		},
		b: []u8 => b,
	};
	if (len(path) + 1 >= len(buf)) {
		return ENAMETOOLONG;
	};
	memcpy(&buf, path: *[*]u8, len(path));
	buf[len(path)] = 0;
	return &buf: *const char;
};

export fn read(fd: int, buf: *void, count: size) (size | errno) = {
	return wrap_return(syscall3(SYS_read,
		fd: u64, buf: uintptr: u64, count: u64))?: size;
};

export fn write(fd: int, buf: *const void, count: size) (size | errno) = {
	return wrap_return(syscall3(SYS_write,
		fd: u64, buf: uintptr: u64, count: u64))?: size;
};

export fn open(path: path, flags: int, mode: uint) (int | errno) = {
	let path = kpath(path)?;
	return wrap_return(syscall4(SYS_openat, AT_FDCWD: u64,
		path: uintptr: u64, flags: u64, mode: u64))?: int;
};

export fn openat2(
	dirfd: int,
	path: path,
	how: *open_how,
	how_sz: size,
) (int | errno) = {
	let path = kpath(path)?;
	return wrap_return(syscall4(SYS_openat2, dirfd: u64,
		path: uintptr: u64, how: uintptr: u64, how_sz: u64))?: int;
};

export fn dup(fd: int) (int | errno) = {
	return wrap_return(syscall1(SYS_dup, fd: u64))?: int;
};

export fn close(fd: int) (void | errno) = {
	wrap_return(syscall1(SYS_close, fd: u64))?;
	return;
};

export fn chdir(path: path) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall1(SYS_chdir, path: uintptr: u64))?;
	return;
};

export fn fchdir(fd: int) (void | errno) = {
	wrap_return(syscall1(SYS_fchdir, fd: u64))?;
	return;
};

export fn chroot(path: path) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall1(SYS_chroot, path: uintptr: u64))?;
	return;
};

export fn mkdir(path: path, mode: uint) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall2(SYS_mkdir, path: uintptr: u64, mode: u64))?;
	return;
};

export fn mkdirat(dirfd: int, path: path, mode: uint) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall3(SYS_mkdirat,
		dirfd: u64, path: uintptr: u64, mode: u64))?;
	return;
};

export fn execveat(dirfd: int, path: path, argv: *[*]nullable *const char,
		envp: *[*]nullable *const char, flags: int) errno = {
	let path = kpath(path)?;
	return match (wrap_return(syscall5(SYS_execveat, dirfd: u64,
			path: uintptr: u64, argv: uintptr: u64,
			envp: uintptr: u64, flags: u64))) {
		err: errno => err,
		u64 => abort("unreachable"),
	};
};

// Returns the new PID to the parent, void to the child, or errno if something
// goes wrong.
export fn fork() (int | void | errno) = clone(null, SIGCHLD, null, null, 0);

export fn getpid() int = syscall0(SYS_getpid): int;

export fn sendfile(
	out: int,
	in: int,
	offs: nullable *size,
	count: size,
) (size | errno) = wrap_return(syscall4(SYS_sendfile,
	out: u64, in: u64, offs: uintptr: u64, count: u64))?: size;
	
export @noreturn fn exit(status: int) void = syscall1(SYS_exit, status: u64);

export fn kill(pid: int, signal: int) (void | errno) = {
	wrap_return(syscall2(SYS_kill, pid: u64, signal: u64))?;
	return;
};

export fn pipe2(pipefd: *[2]int, flags: int) (void | errno) = {
	wrap_return(syscall2(SYS_pipe2, pipefd: uintptr: u64, flags: u64))?;
	return;
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
					&& (flags & MAP_ANON) > 0
					&& (flags & MAP_FIXED) == 0) {
				 // Fix up incorrect EPERM from kernel:
				wrap_errno(ENOMEM);
			} else err;
		},
		n: u64 => n: uintptr: *void,
	};
};

export fn munmap(addr: *void, length: size) (void | errno) = {
	wrap_return(syscall2(SYS_munmap,
		addr: uintptr: u64, length: u64))?;
	return;
};
	

export fn mprotect(addr: *void, length: size, prot: uint) (void | errno) = {
	wrap_return(syscall3(SYS_mprotect,
		addr: uintptr: u64, length: u64, prot: u64))?;
	return;
};
	

export fn lseek(fd: int, off: i64, whence: uint) (i64 | errno) = {
	return wrap_return(syscall3(SYS_lseek,
		fd: u64, off: u64, whence: u64))?: i64;
};

// The use of this function is discouraged, as it can create race conditions.
// TOCTOU is preferred: attempt to simply use the resource you need and handle
// any access errors which occur.
export fn faccessat(
	dirfd: int,
	path: path,
	mode: int,
	flags: int,
) (bool | errno) = {
	let path = kpath(path)?;
	return match (wrap_return(syscall4(SYS_faccessat2, dirfd: u64,
			path: uintptr: u64, mode: u64, flags: u64))) {
		err: errno => switch (err) {
			EACCES => false,
			* => err,
		},
		n: u64 => {
			assert(n == 0);
			true;
		},
	};
};

export fn getdents64(dirfd: int, dirp: *void, count: size) (size | errno) = {
	return wrap_return(syscall3(SYS_getdents64, dirfd: u64,
		dirp: uintptr: u64, count: u64))?: size;
};

// The use of this function is discouraged, as it can create race conditions.
// TOCTOU is preferred: attempt to simply use the resource you need and handle
// any access errors which occur.
export fn access(path: path, mode: int) (bool | errno) =
	faccessat(AT_FDCWD, path, mode, 0);

export type fcntl_arg = (void | int | *st_flock | *f_owner_ex | *u64);

export fn fcntl(fd: int, cmd: int, arg: fcntl_arg) (int | errno) = {
	let _fd = fd: u64, _cmd = cmd: u64;
	return wrap_return(match (arg) {
		void => syscall2(SYS_fcntl, _fd, _cmd),
		i: int => syscall3(SYS_fcntl, _fd, _cmd, i: u64),
		l: *st_flock => syscall3(SYS_fcntl, _fd, _cmd, l: uintptr: u64),
		o: *f_owner_ex => syscall3(SYS_fcntl, _fd, _cmd, o: uintptr: u64),
		u: *u64 => syscall3(SYS_fcntl, _fd, _cmd, u: uintptr: u64),
	})?: int;
};

export fn getrandom(buf: *void, bufln: size, flags: uint) (size | errno) = {
	return wrap_return(syscall3(SYS_getrandom,
		buf: uintptr: u64, bufln: u64, flags: u64))?: size;
};

// TODO: Implement me with VDSO
export fn clock_gettime(clock_id: int, tp: *timespec) (void | errno) = {
	wrap_return(syscall2(SYS_clock_gettime,
		clock_id: u64, tp: uintptr: u64))?;
	return;
};
