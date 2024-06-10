// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

fn syscall0(u64) u64;
fn syscall1(u64, u64) u64;
fn syscall2(u64, u64, u64) u64;
fn syscall3(u64, u64, u64, u64) u64;
fn syscall4(u64, u64, u64, u64, u64) u64;
fn syscall5(u64, u64, u64, u64, u64, u64) u64;
fn syscall6(u64, u64, u64, u64, u64, u64, u64) u64;

let pathbuf: [PATH_MAX]u8 = [0...];

// The use of this function is discouraged, as it can create race conditions.
// TOCTOU is preferred: attempt to simply use the resource you need and handle
// any access errors which occur.
export fn access(path: path, mode: int) (bool | errno) =
	faccessat(AT_FDCWD, path, mode, 0);

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

export fn fchmod(fd: int, mode: uint) (void | errno) = {
	wrap_return(syscall2(SYS_fchmod,
		fd: u64, mode: u64))?;
};

export fn fchmodat(dirfd: int, path: path, mode: uint, flags: int) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall4(SYS_fchmodat,
		dirfd: u64, path: uintptr: u64, mode: u64, flags: u64))?;
};

export fn fchown(fd: int, uid: uint, gid: uint) (void | errno) = {
	wrap_return(syscall3(SYS_fchown,
		fd: u64, uid: u32, gid: u32))?;
};

export fn fchownat(dirfd: int, path: path, uid: uint, gid: uint, flags: int) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall5(SYS_fchownat,
		dirfd: u64, path: uintptr: u64, uid: u32, gid: u32, flags: u64))?;
};

export fn fstatat(fd: int, path: path, _stat: *st, flag: int) (void | errno) = {
	let path = kpath(path)?;
	let sb = stat { ... };
	wrap_return(syscall4(SYS_fstatat, fd: u64,
		path: uintptr: u64, &sb: uintptr: u64, flag: u64))?;
	_stat.dev = sb.st_dev;
	_stat.ino = sb.st_ino;
	_stat.mode = sb.st_mode;
	_stat.nlink = sb.st_nlink;
	_stat.uid = sb.st_uid;
	_stat.gid = sb.st_gid;
	_stat.rdev = sb.st_rdev;
	_stat.atime.tv_sec = sb.st_atim.tv_sec;
	_stat.atime.tv_nsec = sb.st_atim.tv_nsec: i64;
	_stat.mtime.tv_sec = sb.st_mtim.tv_sec;
	_stat.mtime.tv_nsec = sb.st_mtim.tv_nsec: i64;
	_stat.ctime.tv_sec = sb.st_ctim.tv_sec;
	_stat.ctime.tv_nsec = sb.st_ctim.tv_nsec: i64;
	_stat.btime.tv_sec = sb.st_birthtim.tv_sec;
	_stat.btime.tv_nsec = sb.st_birthtim.tv_nsec: i64;
	_stat.sz = sb.st_size;
	_stat.blocks = sb.st_blocks;
	_stat.blksz = sb.st_blksize;
	_stat.flags = sb.st_flags;
};

export fn fstatvfs1(fd: int, _statvfs: *statvfs, flag: int) (void | errno) = {
	wrap_return(syscall3(SYS___fstatvfs190, fd: u64,
		_statvfs: uintptr: u64, flag: u64))?;
};

export fn futimens(fd: int, ts: *[2]timespec) (void | errno) = {
	wrap_return(syscall2(SYS_futimens,
		fd: u64, ts: uintptr: u64))?;
};

export fn getdents(dirfd: int, buf: *opaque, nbytes: size) (size | errno) = {
	return wrap_return(syscall3(SYS___getdents30, dirfd: u64,
		buf: uintptr: u64, nbytes: u64))?: size;
};

// The return value is statically allocated and must be duplicated before
// calling getcwd again.
export fn getcwd() (*const u8 | errno) = {
	static let pathbuf: [PATH_MAX]u8 = [0...];
	wrap_return(syscall2(SYS___getcwd,
		&pathbuf: *[*]u8: uintptr: u64,
		PATH_MAX))?;
	return &pathbuf: *const u8;
};

export fn mkdirat(dirfd: int, path: path, mode: uint) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall3(SYS_mkdirat,
		dirfd: u64, path: uintptr: u64, mode: u64))?;
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

export fn renameat(
	olddirfd: int,
	oldpath: str,
	newdirfd: int,
	newpath: str,
) (void | errno) = {
	let oldpath = kpath(oldpath)?;
	static let newpathbuf: [PATH_MAX]u8 = [0...];
	let newpath = copy_kpath(newpath, newpathbuf)?;
	wrap_return(syscall4(SYS_renameat,
		olddirfd: u64, oldpath: uintptr: u64,
		newdirfd: u64, newpath: uintptr: u64))?;
};

export fn sysctl(name: []const u32, oldp: nullable *opaque, oldlenp: nullable *size,
		newp: nullable *const opaque, newlen: size) (void | errno) = {
	wrap_return(syscall6(SYS___sysctl,
		&name[0]: uintptr: u64, len(name): u64,
		oldp: uintptr: u64, oldlenp: uintptr: u64,
		newp: uintptr: u64, newlen: u64))?;
};

export fn unlink(path: path) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall1(SYS_unlink, path: uintptr: u64))?;
};

export fn unlinkat(dirfd: int, path: path, flags: int) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall3(SYS_unlinkat,
		dirfd: u64, path: uintptr: u64, flags: u64))?;
};

export fn utimensat(dirfd: int, path: str, ts: *[2]timespec, flags: int) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall4(SYS_utimensat,
		dirfd: u64, path: uintptr: u64, ts: uintptr: u64, flags: u64))?;
};

export fn close(fd: int) (void | errno) = {
	wrap_return(syscall1(SYS_close, fd: u64))?;
};

export fn lseek(fd: int, off: i64, whence: int) (i64 | errno) = {
	return wrap_return(syscall3(SYS_lseek,
		fd: u64, off: u64, whence: u64))?: i64;
};

export fn dup2(old: int, new: int) (int | errno) =
	wrap_return(syscall2(SYS_dup2, old: u64, new: u64))?: int;

export fn getpid() pid_t = syscall0(SYS_getpid): pid_t;

export def EXIT_SUCCESS: int = 0;

export fn exit(status: int) never = {
	syscall1(SYS_exit, status: u64);
	abort();
};

export fn fork() (pid_t | void | errno) = {
	let n = wrap_return(syscall0(SYS_fork))?: pid_t;
	switch (n) {
	case 0 =>
		return;
	case =>
		return n;
	};
};

export fn execve(
	path: *const u8,
	argv: *[*]nullable *const u8,
	envp: *[*]nullable *const u8,
) int = syscall3(SYS_execve,
	path: uintptr: u64,
	argv: uintptr: u64,
	envp: uintptr: u64): int;

export fn wait4(
	pid: pid_t,
	wstatus: nullable *int,
	options: int,
	rusage: nullable *rusage,
) (int | errno) = {
	return wrap_return(syscall4(SYS___wait450,
		pid: u64, wstatus: uintptr: u64,
		options: u64, rusage: uintptr: u64))?: int;
};

export fn wifexited(status: int) bool = wtermsig(status) == 0;
export fn wexitstatus(status: int) int = (status & 0xff00) >> 8;

export fn wtermsig(status: int) int = status & 0x7f;
export fn wifsignaled(status: int) bool =
	wtermsig(status) != 0o177 && wtermsig(status) != 0 && status != 0x13;

export fn kill(pid: pid_t, signal: int) (void | errno) = {
	wrap_return(syscall2(SYS_kill, pid: u64, signal: u64))?;
};

export fn pipe2(pipefd: *[2]int, flags: int) (void | errno) = {
	wrap_return(syscall2(SYS_pipe2, pipefd: uintptr: u64, flags: u64))?;
};

export fn mmap(
	addr: nullable *opaque,
	length: size,
	prot: uint,
	flags: uint,
	fd: int,
	offs: size
) (errno | *opaque) = {
	return wrap_return(syscall6(SYS_mmap, addr: uintptr: u64, length: u64,
		prot: u64, flags: u64, fd: u64, offs: u64)): uintptr: *opaque;
};

export fn munmap(addr: *opaque, length: size) (void | errno) = {
	wrap_return(syscall2(SYS_munmap, addr: uintptr: u64, length: u64))?;
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

export fn read(fd: int, buf: *opaque, count: size) (size | errno) = {
	return wrap_return(syscall3(SYS_read,
		fd: u64, buf: uintptr: u64, count: u64))?: size;
};

export fn write(fd: int, buf: *const opaque, count: size) (size | errno) = {
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

export fn flock(fd: int, op: int) (void | errno) = {
	wrap_return(syscall2(SYS_flock,
		fd: u64, op: u64))?;
};

export fn ftruncate(fd: int, ln: off_t) (void | errno) = {
	wrap_return(syscall2(SYS_ftruncate, fd: u64, ln: u32))?;
};

export fn nanosleep(req: *const timespec, rem: *timespec) (void | errno) = {
	wrap_return(syscall2(SYS___nanosleep50,
		req: uintptr: u64, rem: uintptr: u64))?;
};

export fn clock_gettime(clock_id: int, tp: *timespec) (void | errno) = {
	wrap_return(syscall2(SYS___clock_gettime50,
		clock_id: u64, tp: uintptr: u64))?;
};

export fn clock_settime(clock_id: int, tp: *const timespec) (void | errno) = {
	wrap_return(syscall2(SYS___clock_settime50,
		clock_id: u64, tp: uintptr: u64))?;
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

// NUL terminates a string and stores it in a static buffer of PATH_MAX bytes in
// length.
fn kpath(path: path) (*const u8 | errno) = {
	return copy_kpath(path, pathbuf);
};

fn copy_kpath(path: path, buf: []u8) (*const u8 | errno) = {
	let path = match (path) {
	case let c: *const u8 =>
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
	return buf: *[*]u8: *const u8;
};

export fn getgroups(gids: []gid_t) (uint | errno) = {
	return wrap_return(syscall2(SYS_getgroups,
		len(gids): u64, gids: *[*]gid_t: uintptr: u64))?: uint;
};

export fn setgroups(gids: []gid_t) (void | errno) = {
	wrap_return(syscall2(SYS_setgroups,
		len(gids): u64, gids: *[*]gid_t: uintptr: u64))?;
};

export fn getppid() pid_t = syscall0(SYS_getppid): pid_t;

export fn getpgrp() pid_t = syscall0(SYS_getpgrp): pid_t;

export fn getsid(pid: pid_t) (pid_t | errno) = {
	return wrap_return(syscall1(SYS_getsid, pid))?: pid_t;
};

export fn getpriority(which: int, who: id_t) (int | errno) = {
	return wrap_return(syscall2(SYS_getpriority,
		which: u64, who: u64))?: int;
};

export fn setpriority(which: int, who: id_t, prio: int) (void | errno) = {
	wrap_return(syscall3(SYS_setpriority, which: u64, who: u64, prio: u64))?;
};

export fn umask(mode: mode_t) (mode_t | errno) = {
	return wrap_return(syscall1(SYS_umask, mode: u64))?: mode_t;
};

export fn getuid() (uid_t | errno) = {
	return wrap_return(syscall0(SYS_getuid))?: uid_t;
};

export fn geteuid() (uid_t | errno) = {
	return wrap_return(syscall0(SYS_geteuid))?: uid_t;
};

export fn getgid() (gid_t | errno) = {
	return wrap_return(syscall0(SYS_getgid))?: gid_t;
};

export fn getegid() (gid_t | errno) = {
	return wrap_return(syscall0(SYS_getegid))?: gid_t;
};

export fn setuid(uid: *uid_t) (void | errno) = {
	wrap_return(syscall1(SYS_setuid,
		uid: uintptr: u64))?;
};

export fn seteuid(euid: *uid_t) (void | errno) = {
	wrap_return(syscall1(SYS_seteuid,
		euid: uintptr: u64))?;
};

export fn setgid(gid: *gid_t) (void | errno) = {
	wrap_return(syscall1(SYS_setgid,
		gid: uintptr: u64))?;
};

export fn setegid(egid: *gid_t) (void | errno) = {
	wrap_return(syscall1(SYS_setegid,
		egid: uintptr: u64))?;
};

export fn sigaction(
	signum: int,
	act: *const sigact,
	old: nullable *sigact,
) (int | errno) = {
	return wrap_return(syscall3(SYS___sigaction_sigtramp,
		signum: u64, act: uintptr: u64, old: uintptr: u64))?: int;
};

export fn sigprocmask(
	how: int,
	set: nullable *const sigset,
	old: nullable *sigset,
) (int | errno) = {
	return wrap_return(syscall3(SYS___sigprocmask14,
		how: u64, set: uintptr: u64, old: uintptr: u64))?: int;
};

export fn open(
	path: path,
	flags: int,
	mode: uint,
) (int | errno) = {
	let path = kpath(path)?;
	return wrap_return(syscall3(SYS_open,
		path: uintptr: u64, flags: u64, mode: u64))?: int;
};

export fn fstat(fd: int, _stat: *st) (void | errno) = {
	let sb = stat { ... };
	wrap_return(syscall2(SYS___fstat50, fd: u64,
		&sb: uintptr: u64))?;
	_stat.dev = sb.st_dev;
	_stat.ino = sb.st_ino;
	_stat.mode = sb.st_mode;
	_stat.nlink = sb.st_nlink;
	_stat.uid = sb.st_uid;
	_stat.gid = sb.st_gid;
	_stat.rdev = sb.st_rdev;
	_stat.atime.tv_sec = sb.st_atim.tv_sec;
	_stat.atime.tv_nsec = sb.st_atim.tv_nsec: i64;
	_stat.mtime.tv_sec = sb.st_mtim.tv_sec;
	_stat.mtime.tv_nsec = sb.st_mtim.tv_nsec: i64;
	_stat.ctime.tv_sec = sb.st_ctim.tv_sec;
	_stat.ctime.tv_nsec = sb.st_ctim.tv_nsec: i64;
	_stat.btime.tv_sec = sb.st_birthtim.tv_sec;
	_stat.btime.tv_nsec = sb.st_birthtim.tv_nsec: i64;
	_stat.sz = sb.st_size;
	_stat.blocks = sb.st_blocks;
	_stat.blksz = sb.st_blksize;
	_stat.flags = sb.st_flags;
};

export fn fexecve(fd: int, argv: *[*]nullable *const u8,
		envp: *[*]nullable *const u8) errno = {
	return match (wrap_return(syscall3(SYS_fexecve, fd: u64,
		argv: uintptr: u64, envp: uintptr: u64))) {
	case let err: errno =>
		yield err;
	case u64 =>
		abort("unreachable");
	};
};

export type ioctl_arg = (nullable *opaque | u64);

export fn ioctl(fd: int, req: u64, arg: ioctl_arg) (int | errno) = {
	let fd = fd: u64, req = req: u64;
	return wrap_return(match (arg) {
	case let u: u64 =>
		yield syscall3(SYS_ioctl, fd, req, u);
	case let v: nullable *opaque =>
		yield syscall3(SYS_ioctl, fd, req, v: uintptr: u64);
	})?: int;
};

export fn posix_openpt(flags: int) (int | errno) = {
	return open("/dev/ptmx", flags, 0);
};

export fn sigaltstack(
	ss: nullable *stack_t,
	old_ss: nullable *stack_t,
) (void | errno) = {
	wrap_return(syscall2(SYS___sigaltstack14,
		ss: uintptr: u64, old_ss: uintptr: u64))?;
};

export fn ppoll(
	fds: *[*]pollfd,
	nfds: nfds_t,
	timeout: const nullable *timespec,
	sigmask: const nullable *sigset,
) (int | errno) = {
	return wrap_return(syscall4(SYS___pollts50, fds: uintptr: u64,
		nfds: u64, timeout: uintptr: u64,
		sigmask: uintptr: u64))?: int;
};

export fn getrandom(buf: *opaque, bufln: size, flags: uint) (size | errno) = {
	return wrap_return(syscall3(SYS_getrandom,
		buf: uintptr: u64, bufln: u64, flags: u64))?: size;
};

export fn paccept(sockfd: int, addr: nullable *sockaddr, addrlen: nullable *u32, mask: nullable *int, flags: int) (int | errno) = {
	return wrap_return(syscall5(SYS_paccept, sockfd: u64, addr: uintptr: u64, addrlen: uintptr: u64, mask: uintptr: u64, flags: u64))?: int;
};

export fn accept4(sockfd: int, addr: nullable *sockaddr, addrlen: nullable *u32, flags: int) (int | errno) = {
	return paccept(sockfd, addr, addrlen, null, flags);
};

export fn sendmsg(fd: int, msg: *const msghdr, flags: int) (int | errno) = {
	return wrap_return(syscall3(SYS_sendmsg,
		fd: u64, msg: uintptr: u64, flags: u64))?: int;
};

export fn recvmsg(fd: int, msg: *const msghdr, flags: int) (int | errno) = {
	return wrap_return(syscall3(SYS_recvmsg,
		fd: u64, msg: uintptr: u64, flags: u64))?: int;
};

export fn shutdown(sockfd: int, how: int) (void | errno) = {
	wrap_return(syscall2(SYS_shutdown,
		sockfd: u64, how: u64))?;
};

export fn socket(domain: int, type_: int, protocol: int) (int | errno) = {
	return wrap_return(syscall3(SYS___socket30,
		domain: u64, type_: u64, protocol: u64))?: int;
};

export fn connect(sockfd: int, addr: *const sockaddr, addrlen: u32) (int | errno) = {
	return wrap_return(syscall3(SYS_connect,
		sockfd: u64, addr: uintptr: u64, addrlen: u64))?: int;
};

export fn bind(sockfd: int, addr: *const sockaddr, addrlen: u32) (int | errno) = {
	return wrap_return(syscall3(SYS_bind,
		sockfd: u64, addr: uintptr: u64, addrlen: u64))?: int;
};

export fn getsockname(sockfd: int, addr: nullable *sockaddr, addrlen: nullable *u32) (int | errno) = {
	return wrap_return(syscall3(SYS_getsockname,
		sockfd: u64, addr: uintptr: u64, addrlen: uintptr: u64))?: int;
};

export fn send(sockfd: int, buf: *opaque, len_: size, flags: int) (size | errno) = {
	return sendto(sockfd, buf, len_, flags, null, 0);
};

export fn sendto(sockfd: int, buf: *opaque, len_: size, flags: int,
	dest_addr: nullable *sockaddr, addrlen: u32
) (size | errno) = {
	return wrap_return(syscall6(SYS_sendto,
		sockfd: u64, buf: uintptr: u64, len_: u64, flags: u64,
		dest_addr: uintptr: u64, addrlen: u64))?: size;
};

export fn recv(sockfd: int, buf: *opaque, len_: size, flags: int) (size | errno) = {
	return recvfrom(sockfd, buf, len_, flags, null, null);
};

export fn setsockopt(sockfd: int, level: int, optname: int, optval: *opaque, optlen: u32) (int | errno) = {
	return wrap_return(syscall5(SYS_setsockopt,
		sockfd: u64, level: u64, optname: u64,
		optval: uintptr: u64, optlen: u64))?: int;
};

export fn recvfrom(sockfd: int, buf: *opaque, len_: size, flags: int,
	src_addr: nullable *sockaddr, addrlen: nullable *u32
) (size | errno) = {
	return wrap_return(syscall6(SYS_recvfrom,
		sockfd: u64, buf: uintptr: u64, len_: u64, flags: u64,
		src_addr: uintptr: u64, addrlen: uintptr: u64))?: size;
};

export fn listen(sockfd: int, backlog: u32) (int | errno) = {
	return wrap_return(syscall2(SYS_listen,
		sockfd: u64, backlog: u64))?: int;
};

export fn getpeername(sockfd: int, addr: nullable *sockaddr, addrlen: nullable *u32) (int | errno) = {
	return wrap_return(syscall3(SYS_getpeername,
		sockfd: u64, addr: uintptr: u64, addrlen: uintptr: u64))?: int;
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
