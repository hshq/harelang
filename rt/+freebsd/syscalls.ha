// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Thomas Bracht Laumann Jespersen <t@laumann.xyz>

fn syscall0(_: u64) u64;
fn syscall1(_: u64, _: u64) u64;
fn syscall2(_: u64, _: u64, _: u64) u64;
fn syscall3(_: u64, _: u64, _: u64, _: u64) u64;
fn syscall4(_: u64, _: u64, _: u64, _: u64, _: u64) u64;
fn syscall5(_: u64, _: u64, _: u64, _: u64, _: u64, _: u64) u64;
fn syscall6(_: u64, _: u64, _: u64, _: u64, _: u64, _: u64, _: u64) u64;

export def PATH_MAX: size = 1024z;
export type path = (str | []u8 | *const char);
let pathbuf: [PATH_MAX + 1]u8 = [0...];

fn copy_kpath(path: path, buf: []u8) (*const char | errno) = {
	let path = match (path) {
	case let c: *const char =>
		return c;
	case let s: str =>
		let ptr = &s: *struct {
			buf: *[*]u8,
			length: size,
			capacity: size,
		};
		yield ptr.buf[..ptr.length];
	case let b: []u8 =>
		yield b;
	};
	if (len(path) + 1 >= len(pathbuf)) {
		return ENAMETOOLONG;
	};
	memcpy(buf: *[*]u8, path: *[*]u8, len(path));
	buf[len(path)] = 0;
	return buf: *[*]u8: *const char;
};

// NUL terminates a string and stores it in a static buffer of PATH_MAX+1 bytes
// in length.
fn kpath(path: path) (*const char | errno) = {
	return copy_kpath(path, pathbuf);
};

export fn read(fd: int, buf: *void, count: size) (size | errno) = {
	return wrap_return(syscall3(SYS_read,
		fd: u64, buf: uintptr: u64, count: u64))?: size;
};

export fn write(fd: int, buf: *const void, count: size) (size | errno) = {
	return wrap_return(syscall3(SYS_write,
		fd: u64, buf: uintptr: u64, count: u64))?: size;
};

export fn readv(fd: int, iov: const *[*]iovec, iovcnt: int) (size | errno) = {
	return wrap_return(syscall3(SYS_readv,
		fd: u64, iov: uintptr: u64, iovcnt: u64))?: size;
};

export fn writev(fd: int, iov: const *[*]iovec, iovcnt: int) (size | errno) = {
	return wrap_return(syscall3(SYS_writev,
		fd: u64, iov: uintptr: u64, iovcnt: u64))?: size;
};

export fn close(fd: int) (void | errno) = {
	wrap_return(syscall1(SYS_close, fd: u64))?;
};

export fn lseek(fd: int, off: i64, whence: int) (i64 | errno) = {
	return wrap_return(syscall3(SYS_lseek,
		fd: u64, off: u64, whence: u64))?: i64;
};

export fn pipe2(pipefd: *[2]int, flags: int) (void | errno) = {
	wrap_return(syscall2(SYS_pipe2, pipefd: uintptr: u64, flags: u64))?;
};

export fn ioctl(fd: int, req: u64, arg: nullable *void) (int | errno) = {
	return wrap_return(syscall3(SYS_ioctl, fd: u64,
		req, arg: uintptr: u64))?: int;
};

export fn openat(
	dirfd: int,
	path: path,
	flags: int,
	mode: uint,
) (int | errno) = {
	let path = kpath(path)?;
	return wrap_return(syscall4(SYS_openat, dirfd: u64,
		path: uintptr: u64, flags: u64, mode: u64))?: int;
};

export fn open(path: str, flags: int, mode: uint) (int | errno) = {
	return openat(AT_FDCWD, path, flags, mode);
};

export fn unlink(path: path) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall3(SYS_unlinkat,
		AT_FDCWD: u64, path: uintptr: u64, 0u64))?;
};

export fn renameat(
	olddirfd: int,
	oldpath: str,
	newdirfd: int,
	newpath: str,
) (void | errno) = {
	let oldpath = kpath(oldpath)?;
	static let newpathbuf: [PATH_MAX + 1]u8 = [0...];
	let newpath = copy_kpath(newpath, newpathbuf)?;
	wrap_return(syscall4(SYS_renameat,
		olddirfd: u64, oldpath: uintptr: u64,
		newdirfd: u64, newpath: uintptr: u64))?;
};

export fn unlinkat(dirfd: int, path: path, flags: int) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall3(SYS_unlinkat,
		dirfd: u64, path: uintptr: u64, flags: u64))?;
};

export fn fstatat(fd: int, path: path, stat: *st, flag: int) (void | errno) = {
	let path = kpath(path)?;
	let fbstat = freebsd11_stat { ... };
	wrap_return(syscall4(SYS_freebsd11_fstatat, fd: u64,
		path: uintptr: u64, &fbstat: uintptr: u64, flag: u64))?;
	stat.dev = fbstat.st_dev;
	stat.ino = fbstat.st_ino;
	stat.mode = fbstat.st_mode;
	stat.nlink = fbstat.st_nlink;
	stat.uid = fbstat.st_uid;
	stat.gid = fbstat.st_gid;
	stat.rdev = fbstat.st_rdev;
	stat.atime.tv_sec = fbstat.st_atim.tv_sec;
	stat.atime.tv_nsec = fbstat.st_atim.tv_nsec: i64;
	stat.mtime.tv_sec = fbstat.st_mtim.tv_sec;
	stat.mtime.tv_nsec = fbstat.st_mtim.tv_nsec: i64;
	stat.ctime.tv_sec = fbstat.st_ctim.tv_sec;
	stat.ctime.tv_nsec = fbstat.st_ctim.tv_nsec: i64;
	stat.btime.tv_sec = fbstat.st_birthtim.tv_sec;
	stat.btime.tv_nsec = fbstat.st_birthtim.tv_nsec: i64;
	stat.sz = fbstat.st_size;
	stat.blocks = fbstat.st_blocks;
	stat.blksz = fbstat.st_blksize;
	stat.flags = fbstat.st_flags;
};

export fn readlinkat(
	dirfd: int,
	path: path,
	buf: []u8,
) (size | errno) = {
	let path = kpath(path)?;
	return wrap_return(syscall4(SYS_readlinkat,
		dirfd: u64, path: uintptr: u64,
		buf: *[*]u8: uintptr: u64,
		len(buf): u64))?: size;
};

export fn mkdirat(dirfd: int, path: path, mode: uint) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall3(SYS_mkdirat,
		dirfd: u64, path: uintptr: u64, mode: u64))?;
};

export fn fchmodat(dirfd: int, path: path, mode: uint, flags: int) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall4(SYS_fchmodat,
		dirfd: u64, path: uintptr: u64, mode: u64, flags: u64))?;
};

export fn fchownat(dirfd: int, path: path, uid: uint, gid: uint, flags: int) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall5(SYS_fchownat,
		dirfd: u64, path: uintptr: u64, uid: u32, gid: u32, flags: u64))?;
};

export fn faccessat(
	dirfd: int,
	path: path,
	mode: int,
	flags: int,
) (bool | errno) = {
	let path = kpath(path)?;
	match (wrap_return(syscall4(SYS_faccessat, dirfd: u64,
		path: uintptr: u64, mode: u64, flags: u64))) {
	case let err: errno =>
		switch (err) {
		case EACCES =>
			return false;
		case =>
			return err;
		};
	case let n: u64 =>
		assert(n == 0);
		return true;
	};
};

// The use of this function is discouraged, as it can create race conditions.
// TOCTOU is preferred: attempt to simply use the resource you need and handle
// any access errors which occur.
export fn access(path: path, mode: int) (bool | errno) =
	faccessat(AT_FDCWD, path, mode, 0);

// TODO: Consider updating this to use SYS_freebsd11_getdirentries
export fn getdents(dirfd: int, buf: *void, nbytes: size) (size | errno) = {
	return wrap_return(syscall3(SYS_freebsd11_getdents, dirfd: u64,
		buf: uintptr: u64, nbytes: u64))?: size;
};

// The return value is statically allocated and must be duplicated before
// calling getcwd again.
export fn getcwd() (*const char | errno) = {
	static let pathbuf: [PATH_MAX + 1]u8 = [0...];
	wrap_return(syscall2(SYS___getcwd,
		&pathbuf: *[*]u8: uintptr: u64,
		PATH_MAX + 1))?;
	return &pathbuf: *const char;
};

export fn fchdir(fd: int) (void | errno) = {
	wrap_return(syscall1(SYS_fchdir, fd: u64))?;
};

export fn chdir(path: path) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall1(SYS_chdir, path: uintptr: u64))?;
};

export fn chroot(path: path) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall1(SYS_chroot, path: uintptr: u64))?;
};

export fn mmap(
	addr: nullable *void,
	length: size,
	prot: uint,
	flags: uint,
	fd: int,
	offs: size
) (errno | *void) = {
	return wrap_return(syscall6(SYS_mmap, addr: uintptr: u64,
		length: u64, prot: u64, flags: u64,
		fd: u64, offs: u64))?: uintptr: *void;
};

export fn munmap(addr: *void, length: size) (void | errno) = {
	wrap_return(syscall2(SYS_munmap, addr: uintptr: u64, length: u64))?;
};

export @noreturn fn exit(status: int) void = {
	syscall1(SYS_exit, status: u64);
};

export fn kill(pid: int, signal: int) (void | errno) = {
	wrap_return(syscall2(SYS_kill, pid: u64, signal: u64))?;
};

export fn fork() (int | void | errno) = {
	let n = wrap_return(syscall0(SYS_fork))?: int;
	switch (n) {
	case 0 =>
		return;
	case =>
		return n;
	};
};

export fn fexecve(fd: int, argv: *[*]nullable *const char,
		envp: *[*]nullable *const char) errno = {
	return match (wrap_return(syscall3(SYS_fexecve, fd: u64,
		argv: uintptr: u64, envp: uintptr: u64))) {
	case let err: errno =>
		yield err;
	case u64 =>
		abort("unreachable");
	};
};

export fn wait4(
	pid: int,
	wstatus: *int,
	options: int,
	rusage: *rusage,
) (int | errno) = {
	return wrap_return(syscall4(SYS_wait4,
		pid: u64, wstatus: uintptr: u64,
		options: u64, rusage: uintptr: u64))?: int;
};

export fn wifexited(status: int) bool = wtermsig(status) == 0;
export fn wexitstatus(status: int) int = (status & 0xff00) >> 8;

export fn wtermsig(status: int) int = status & 0x7f;
export fn wifsignaled(status: int) bool =
	wtermsig(status) != 0o177 && wtermsig(status) != 0 && status != 0x13;

export fn getpid() int = syscall0(SYS_getpid): int;

export fn getpriority(which: int, who: id_t) (int | errno) = {
	return wrap_return(syscall2(SYS_setpriority,
		which: u64, who: u64))?: int;
};

export fn setpriority(which: int, who: id_t, prio: int) (void | errno) = {
	wrap_return(syscall3(SYS_setpriority, which: u64, who: u64, prio: u64))?;
};

export fn umask(mode: mode_t) (mode_t | errno) = {
	return wrap_return(syscall1(SYS_umask, mode: u64))?: mode_t;
};

export fn setresuid(uid: uid_t, euid: uid_t, suid: uid_t) (void | errno) = {
	wrap_return(syscall3(SYS_setresuid, uid: u64, euid: u64, suid: u64))?;
};

export fn setresgid(gid: gid_t, egid: gid_t, sgid: gid_t) (void | errno) = {
	wrap_return(syscall3(SYS_setresgid, gid: u64, egid: u64, sgid: u64))?;
};

export fn getgroups(gids: []uint) (uint | errno) = {
	return wrap_return(syscall2(SYS_getgroups,
		len(gids): u64, gids: *[*]uint: uintptr: u64))?: uint;
};

export fn setgroups(gids: []uint) (void | errno) = {
	wrap_return(syscall2(SYS_setgroups,
		len(gids): u64, gids: *[*]uint: uintptr: u64))?;
};

export fn getresuid(uid: *uid_t, euid: *uid_t, suid: *uid_t) (void | errno) = {
	wrap_return(syscall3(SYS_getresuid,
		uid: uintptr: u64,
		euid: uintptr: u64,
		suid: uintptr: u64))?;
};

export fn getresgid(gid: *gid_t, egid: *gid_t, sgid: *gid_t) (void | errno) = {
	wrap_return(syscall3(SYS_getresgid,
		gid: uintptr: u64,
		egid: uintptr: u64,
		sgid: uintptr: u64))?;
};

export fn clock_gettime(clock_id: int, tp: *timespec) (void | errno) = {
	wrap_return(syscall2(SYS_clock_gettime,
		clock_id: u64, tp: uintptr: u64))?;
};

export fn nanosleep(req: *const timespec, rem: *timespec) (void | errno) = {
	wrap_return(syscall2(SYS_nanosleep,
		req: uintptr: u64, rem: uintptr: u64))?;
};

export fn getrandom(buf: *void, bufln: size, flags: uint) (size | errno) = {
	return wrap_return(syscall3(SYS_getrandom,
		buf: uintptr: u64, bufln: u64, flags: u64))?: size;
};

export type fcntl_arg = (void | int | *st_flock | *u64);

export fn fcntl(fd: int, cmd: int, arg: fcntl_arg) (int | errno) = {
	let _fd = fd: u64, _cmd = cmd: u64;
	return wrap_return(match (arg) {
	case void =>
		yield syscall2(SYS_fcntl, _fd, _cmd);
	case let i: int =>
		yield syscall3(SYS_fcntl, _fd, _cmd, i: u64);
	case let l: *st_flock =>
		yield syscall3(SYS_fcntl, _fd, _cmd, l: uintptr: u64);
	case let u: *u64 =>
		yield syscall3(SYS_fcntl, _fd, _cmd, u: uintptr: u64);
	})?: int;
};

export fn ppoll(
	fds: *[*]pollfd,
	nfds: nfds_t,
	timeout: const nullable *timespec,
	sigmask: const nullable *sigset,
) (int | errno) = {
	return wrap_return(syscall4(SYS_ppoll, fds: uintptr: u64, nfds: u64,
		timeout: uintptr: u64, sigmask: uintptr: u64))?: int;
};

export fn poll(fds: *[*]pollfd, nfds: nfds_t, timeout: int) (int | errno) = {
	const ts = timespec {
		tv_sec = timeout % 1000,
		tv_nsec = timeout * 1000000,
	};
	return ppoll(fds, nfds, (if (timeout != -1) &ts else null), null);
};

export fn socket(domain: int, type_: int, protocol: int) (int | errno) = {
	return wrap_return(syscall3(SYS_socket,
		domain: u64, type_: u64, protocol: u64))?: int;
};

export fn socketpair(
	domain: int,
	type_: int,
	protocol: int,
	sv: *[*]int,
) (int | errno) = {
	return wrap_return(syscall4(SYS_socketpair, domain: u64,
		type_: u64, protocol: u64, sv: uintptr : u64))?: int;
};

export fn connect(sockfd: int, addr: *const sockaddr, addrlen: u32) (int | errno) = {
	return wrap_return(syscall3(SYS_connect,
		sockfd: u64, addr: uintptr: u64, addrlen: u64))?: int;
};

export fn bind(sockfd: int, addr: *const sockaddr, addrlen: u32) (int | errno) = {
	return wrap_return(syscall3(SYS_bind,
		sockfd: u64, addr: uintptr: u64, addrlen: u64))?: int;
};

export fn listen(sockfd: int, backlog: u32) (int | errno) = {
	return wrap_return(syscall2(SYS_listen,
		sockfd: u64, backlog: u64))?: int;
};

export fn accept(sockfd: int, addr: nullable *sockaddr, addrlen: nullable *u32) (int | errno) = {
	return wrap_return(syscall3(SYS_accept,
		sockfd: u64, addr: uintptr: u64, addrlen: uintptr: u64))?: int;
};

export fn accept4(sockfd: int, addr: nullable *sockaddr, addrlen: nullable *u32, flags: int) (int | errno) = {
	return wrap_return(syscall4(SYS_accept4,
		sockfd: u64, addr: uintptr: u64, addrlen: uintptr: u64, flags: u64))?: int;
};

export fn recvfrom(sockfd: int, buf: *void, len_: size, flags: int,
	src_addr: nullable *sockaddr, addrlen: nullable *u32
) (size | errno) = {
	return wrap_return(syscall6(SYS_recvfrom,
		sockfd: u64, buf: uintptr: u64, len_: u64, flags: u64,
		src_addr: uintptr: u64, addrlen: uintptr: u64))?: size;
};

export fn sendto(sockfd: int, buf: *void, len_: size, flags: int,
	dest_addr: nullable *sockaddr, addrlen: u32
) (size | errno) = {
	return wrap_return(syscall6(SYS_sendto,
		sockfd: u64, buf: uintptr: u64, len_: u64, flags: u64,
		dest_addr: uintptr: u64, addrlen: u64))?: size;
};

export fn recv(sockfd: int, buf: *void, len_: size, flags: int) (size | errno) = {
	return recvfrom(sockfd, buf, len_, flags, null, null);
};

export fn send(sockfd: int, buf: *void, len_: size, flags: int) (size | errno) = {
	return sendto(sockfd, buf, len_, flags, null, 0);
};

export fn sendmsg(fd: int, msg: *const msghdr, flags: int) (int | errno) = {
	return wrap_return(syscall3(SYS_sendmsg,
		fd: u64, msg: uintptr: u64, flags: u64))?: int;
};

export fn recvmsg(fd: int, msg: *const msghdr, flags: int) (int | errno) = {
	return wrap_return(syscall3(SYS_recvmsg,
		fd: u64, msg: uintptr: u64, flags: u64))?: int;
};

export fn getsockopt(sockfd: int, level: int, optname: int, optval: nullable *void, optlen: nullable *u32) (int | errno) = {
	return wrap_return(syscall5(SYS_getsockopt,
		sockfd: u64, level: u64, optname: u64,
		optval: uintptr: u64, optlen: uintptr: u64))?: int;
};

export fn setsockopt(sockfd: int, level: int, optname: int, optval: *void, optlen: u32) (int | errno) = {
	return wrap_return(syscall5(SYS_setsockopt,
		sockfd: u64, level: u64, optname: u64,
		optval: uintptr: u64, optlen: u64))?: int;
};

export fn getsockname(sockfd: int, addr: nullable *sockaddr, addrlen: nullable *u32) (int | errno) = {
	return wrap_return(syscall3(SYS_getsockname,
		sockfd: u64, addr: uintptr: u64, addrlen: uintptr: u64))?: int;
};

export fn getpeername(sockfd: int, addr: nullable *sockaddr, addrlen: nullable *u32) (int | errno) = {
	return wrap_return(syscall3(SYS_getpeername,
		sockfd: u64, addr: uintptr: u64, addrlen: uintptr: u64))?: int;
};

export fn sysctlbyname(name: str, oldp: nullable *void, oldlenp: nullable *size,
		newp: nullable *const void, newlen: size) (void | errno) = {
	let kname = kpath(name)?;
	wrap_return(syscall6(SYS___sysctlbyname,
		kname: uintptr: u64, len(name): u64,
		oldp: uintptr: u64, oldlenp: uintptr: u64,
		newp: uintptr: u64, newlen: u64))?;
};

export fn dup2(oldfd: int, newfd: int) (int | errno) = {
	return wrap_return(syscall2(SYS_dup2, oldfd: u64, newfd: u64))?: int;
};

export fn posix_openpt(flags: int) (int | errno) = {
	return wrap_return(syscall1(SYS_posix_openpt, flags: u64))?: int;
};

export fn posix_fallocate(fd: int, off: i64, ln: i64) (void | errno) = {
	wrap_return(syscall3(SYS_posix_fallocate,
		fd: u64, off: u64, ln: u64))?;
};
