// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Mykyta Holubakha <hilobakho@gmail.com>
// (c) 2021 Thomas Bracht Laumann Jespersen <t@laumann.xyz>
// (c) 2022 Vincent Dagonneau <v@vda.io>

fn syscall0(_: u64) u64;
fn syscall1(_: u64, _: u64) u64;
fn syscall2(_: u64, _: u64, _: u64) u64;
fn syscall3(_: u64, _: u64, _: u64, _: u64) u64;
fn syscall4(_: u64, _: u64, _: u64, _: u64, _: u64) u64;
fn syscall5(_: u64, _: u64, _: u64, _: u64, _: u64, _: u64) u64;
fn syscall6(_: u64, _: u64, _: u64, _: u64, _: u64, _: u64, _: u64) u64;

export def PATH_MAX: size = 4096z;
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

export fn open(path: path, flags: int, mode: uint) (int | errno) = {
	let path = kpath(path)?;
	return wrap_return(syscall4(SYS_openat, AT_FDCWD: u64,
		path: uintptr: u64, flags: u64, mode: u64))?: int;
};

fn openat(
	dirfd: int,
	path: *const char,
	flags: int,
	mode: uint,
) (int | errno) = wrap_return(syscall4(SYS_openat, dirfd: u64,
	path: uintptr: u64, flags: u64, mode: u64))?: int;

export fn openat2(
	dirfd: int,
	path: path,
	how: *open_how,
	how_sz: size,
) (int | errno) = {
	let path = kpath(path)?;
	return openat(dirfd, path, how.flags: int, how.mode: uint);
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

export fn unlink(path: path) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall3(SYS_unlinkat,
		AT_FDCWD: u64, path: uintptr: u64, 0u64))?;
};

export fn unlinkat(dirfd: int, path: path, flags: int) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall3(SYS_unlinkat,
		dirfd: u64, path: uintptr: u64, flags: u64))?;
};

export fn linkat(
	olddirfd: int,
	oldpath: str,
	newdirfd: int,
	newpath: str,
	flags: int,
) (void | errno) = {
	let oldpath = kpath(oldpath)?;
	static let newpathbuf: [PATH_MAX + 1]u8 = [0...];
	let newpath = copy_kpath(newpath, newpathbuf)?;
	wrap_return(syscall5(SYS_linkat,
		olddirfd: u64, oldpath: uintptr: u64,
		newdirfd: u64, newpath: uintptr: u64, flags: u64))?;
};

export fn symlinkat(
	target: str,
	newdirfd: int,
	linkpath: str,
) (void | errno) = {
	let target = kpath(target)?;
	static let linkpathbuf: [PATH_MAX + 1]u8 = [0...];
	let linkpath = copy_kpath(linkpath, linkpathbuf)?;
	wrap_return(syscall3(SYS_symlinkat, target: uintptr: u64,
		newdirfd: u64, linkpath: uintptr: u64))?;
};

export fn mknodat(
	dirfd: int,
	path: path,
	mode: mode_t,
	dev: dev_t,
) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall3(SYS_mknodat,
		path: uintptr: u64, mode: u64, dev: u64))?;
};

export fn chmod(path: path, mode: uint) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall4(SYS_fchmodat,
		AT_FDCWD: u64, path: uintptr: u64, mode: u64, 0))?;
};

export fn fchmodat(dirfd: int, path: path, mode: uint, flags: int) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall4(SYS_fchmodat,
		dirfd: u64, path: uintptr: u64, mode: u64, flags: u64))?;
};

export fn chown(path: path, uid: uint, gid: uint) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall5(SYS_fchownat,
		AT_FDCWD: u64, path: uintptr: u64, uid: u32, gid: u32, 0))?;
};

export fn fchownat(dirfd: int, path: path, uid: uint, gid: uint, flags: int) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall5(SYS_fchownat,
		dirfd: u64, path: uintptr: u64, uid: u32, gid: u32, flags: u64))?;
};

export fn renameat(
	olddirfd: int,
	oldpath: str,
	newdirfd: int,
	newpath: str,
	flags: uint,
) (void | errno) = {
	let oldpath = kpath(oldpath)?;
	static let newpathbuf: [PATH_MAX + 1]u8 = [0...];
	let newpath = copy_kpath(newpath, newpathbuf)?;
	wrap_return(syscall5(SYS_renameat2,
		olddirfd: u64, oldpath: uintptr: u64,
		newdirfd: u64, newpath: uintptr: u64,
		flags: u64))?;
};

export fn dup(fd: int) (int | errno) = {
	return wrap_return(syscall1(SYS_dup, fd: u64))?: int;
};

export fn dup2(oldfd: int, newfd: int) (int | errno) = {
	return dup3(oldfd, newfd, 0);
};

export fn dup3(oldfd: int, newfd: int, flags: int) (int | errno) = {
	return wrap_return(syscall3(SYS_dup3,
		oldfd: u64, newfd: u64, flags: u64))?: int;
};

export fn close(fd: int) (void | errno) = {
	wrap_return(syscall1(SYS_close, fd: u64))?;
};

export fn chdir(path: path) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall1(SYS_chdir, path: uintptr: u64))?;
};

export fn fchdir(fd: int) (void | errno) = {
	wrap_return(syscall1(SYS_fchdir, fd: u64))?;
};

export fn chroot(path: path) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall1(SYS_chroot, path: uintptr: u64))?;
};

export fn mkdir(path: path, mode: uint) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall3(SYS_mkdirat, AT_FDCWD: u64,
		path: uintptr: u64, mode: u64))?;
};

export fn mkdirat(dirfd: int, path: path, mode: uint) (void | errno) = {
	let path = kpath(path)?;
	wrap_return(syscall3(SYS_mkdirat,
		dirfd: u64, path: uintptr: u64, mode: u64))?;
};

export fn execveat(dirfd: int, path: path, argv: *[*]nullable *const char,
		envp: *[*]nullable *const char, flags: int) errno = {
	let path = kpath(path)?;
	return match (wrap_return(syscall5(SYS_execveat, dirfd: u64,
		path: uintptr: u64, argv: uintptr: u64,
		envp: uintptr: u64, flags: u64))) {
	case let err: errno =>
		yield err;
	case u64 =>
		abort("unreachable");
	};
};

// Returns the new PID to the parent, void to the child, or errno if something
// goes wrong.
export fn fork() (int | void | errno) = clone(null, SIGCHLD, null, null, 0);

export fn getpid() int = syscall0(SYS_getpid): int;

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

export fn sendfile(
	out: int,
	in: int,
	offs: nullable *size,
	count: size,
) (size | errno) = wrap_return(syscall4(SYS_sendfile,
	out: u64, in: u64, offs: uintptr: u64, count: u64))?: size;

export @noreturn fn exit(status: int) void = {
	syscall1(SYS_exit, status: u64);
};

export fn kill(pid: int, signal: int) (void | errno) = {
	wrap_return(syscall2(SYS_kill, pid: u64, signal: u64))?;
};

export fn pipe2(pipefd: *[2]int, flags: int) (void | errno) = {
	wrap_return(syscall2(SYS_pipe2, pipefd: uintptr: u64, flags: u64))?;
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
	return match (wrap_return(r)) {
	case let err: errno =>
		return if (r: int == -EPERM
				&& addr == null
				&& (flags & MAP_ANON) > 0
				&& (flags & MAP_FIXED) == 0) {
			// Fix up incorrect EPERM from kernel:
			yield wrap_errno(ENOMEM);
		} else err;
	case let n: u64 =>
		yield n: uintptr: *void;
	};
};

export fn munmap(addr: *void, length: size) (void | errno) = {
	wrap_return(syscall2(SYS_munmap,
		addr: uintptr: u64, length: u64))?;
};

export fn mprotect(addr: *void, length: size, prot: uint) (void | errno) = {
	wrap_return(syscall3(SYS_mprotect,
		addr: uintptr: u64, length: u64, prot: u64))?;
};

export fn lseek(fd: int, off: i64, whence: uint) (i64 | errno) = {
	return wrap_return(syscall3(SYS_lseek,
		fd: u64, off: u64, whence: u64))?: i64;
};

fn faccessat1(dirfd: int, path: *const char, mode: int) (bool | errno) = {
	return match (wrap_return(syscall3(SYS_faccessat, dirfd: u64,
		path: uintptr: u64, mode: u64))) {
	case let err: errno =>
		yield switch (err) {
		case EACCES =>
			yield false;
		case =>
			yield err;
		};
	case let n: u64 =>
		assert(n == 0);
		yield true;
	};
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
	match (wrap_return(syscall4(SYS_faccessat2, dirfd: u64,
			path: uintptr: u64, mode: u64, flags: u64))) {
	case let err: errno =>
		switch (err) {
		case EACCES =>
			return false;
		case ENOSYS =>
			if (flags == 0) {
				return faccessat1(dirfd, path, mode);
			} else {
				return err;
			};
		case =>
			return err;
		};
	case let n: u64 =>
		assert(n == 0);
		return true;
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
	case void =>
		yield syscall2(SYS_fcntl, _fd, _cmd);
	case let i: int =>
		yield syscall3(SYS_fcntl, _fd, _cmd, i: u64);
	case let l: *st_flock =>
		yield syscall3(SYS_fcntl, _fd, _cmd, l: uintptr: u64);
	case let o: *f_owner_ex =>
		yield syscall3(SYS_fcntl, _fd, _cmd, o: uintptr: u64);
	case let u: *u64 =>
		yield syscall3(SYS_fcntl, _fd, _cmd, u: uintptr: u64);
	})?: int;
};

export fn getrandom(buf: *void, bufln: size, flags: uint) (size | errno) = {
	return wrap_return(syscall3(SYS_getrandom,
		buf: uintptr: u64, bufln: u64, flags: u64))?: size;
};

export fn clock_gettime(clock_id: int, tp: *timespec) (void | errno) = {
	wrap_return(syscall2(SYS_clock_gettime,
		clock_id: u64, tp: uintptr: u64))?;
};

export fn nanosleep(req: *const timespec, rem: *timespec) (void | errno) = {
	wrap_return(syscall2(SYS_nanosleep,
		req: uintptr: u64, rem: uintptr: u64))?;
};

export fn uname(uts: *utsname) (void | errno) = {
	wrap_return(syscall1(SYS_uname, uts: uintptr: u64))?;
};

// The return value is statically allocated and must be duplicated before
// calling getcwd again.
export fn getcwd() (*const char | errno) = {
	static let pathbuf: [PATH_MAX + 1]u8 = [0...];
	wrap_return(syscall2(SYS_getcwd,
		&pathbuf: *[*]u8: uintptr: u64,
		PATH_MAX + 1))?;
	return &pathbuf: *const char;
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

export fn epoll_create1(flags: int) (int | errno) = {
	return wrap_return(syscall1(SYS_epoll_create1, flags: u64))?: int;
};

export fn epoll_create(size_: int) (int | errno) = {
	return epoll_create1(0);
};

export fn epoll_ctl(
	epfd: int,
	op: int,
	fd: int,
	event: nullable *epoll_event
) (int | errno) = {
	return wrap_return(syscall4(SYS_epoll_ctl,
		epfd: u64, op: u64, fd: u64, event: uintptr: u64))?: int;
};

export fn epoll_pwait(
	epfd: int,
	events: *epoll_event,
	maxevents: int,
	timeout: int,
	sigmask: nullable *sigset
) (int | errno) = {
	return wrap_return(syscall6(SYS_epoll_pwait,
		epfd: u64, events: uintptr: u64,
		maxevents: u64, timeout: u64,
		sigmask: uintptr: u64, size(sigset): u64))?: int;
};

export fn epoll_wait(
	epfd: int,
	events: *epoll_event,
	maxevents: int,
	timeout: int,
) (int | errno) = {
	return epoll_pwait(epfd, events, maxevents, timeout, null);
};

export fn timerfd_create(clock_id: int, flags: int) (int | errno) = {
	return wrap_return(syscall2(SYS_timerfd_create,
		clock_id: u64, flags: u64))?: int;
};

export fn eventfd(initval: uint, flags: int) (int | errno) = {
	return wrap_return(syscall2(SYS_eventfd2,
		initval: u64, flags: u64))?: int;
};

export fn timerfd_settime(
	fd: int,
	flags: int,
	new_value: *const itimerspec,
	old_value: nullable *itimerspec
) (int | errno) = {
	return wrap_return(syscall4(SYS_timerfd_settime,
		fd: u64, flags: u64,
		new_value: uintptr: u64, old_value: uintptr: u64))?: int;
};

export fn timerfd_gettime(fd: int, curr_value: *itimerspec) (int | errno) = {
	return wrap_return(syscall2(SYS_timerfd_gettime,
		fd: u64, curr_value: uintptr: u64))?: int;
};

export fn signalfd(fd: int, mask: *const sigset, flags: int) (int | errno) = {
	return wrap_return(syscall4(SYS_signalfd4,
		fd: u64, mask: uintptr: u64, size(sigset): u64,
		flags: u64))?: int;
};

export fn sigprocmask(
	how: int,
	set: nullable *const sigset,
	old: nullable *sigset
) (int | errno) = {
	return wrap_return(syscall4(SYS_rt_sigprocmask,
		how: u64, set: uintptr: u64, old: uintptr: u64,
		size(sigset): u64))?: int;
};

fn restore() void;
fn restore_si() void;

export fn sigaction(
	signum: int,
	act: *const sigact,
	old: nullable *sigact
) (int | errno) = {
	let real_act = *act;
	real_act.sa_flags |= SA_RESTORER;
	let restore_fn = if ((act.sa_flags & SA_SIGINFO) != 0) &restore_si else &restore;
	real_act.sa_restorer = &restore;
	return wrap_return(syscall4(SYS_rt_sigaction,
		signum: u64, &real_act: uintptr: u64, old: uintptr: u64,
		size(sigset): u64))?: int;
};

export fn socket(domain: int, type_: int, protocol: int) (int | errno) = {
	return wrap_return(syscall3(SYS_socket,
		domain: u64, type_: u64, protocol: u64))?: int;
};

export fn socketpair(
	domain: int,
	type_: int,
	protocol: int,
	sv: *[2]int
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

export type ioctl_arg = (nullable *void | u64);

export fn ioctl(fd: int, req: u64, arg: ioctl_arg) (int | errno) = {
	let fd = fd: u64, req = req: u64;
	return wrap_return(match (arg) {
	case let u: u64 =>
		yield syscall3(SYS_ioctl, fd, req, u);
	case let v: nullable *void =>
		yield syscall3(SYS_ioctl, fd, req, v: uintptr: u64);
	})?: int;
};

export fn getsockname(sockfd: int, addr: nullable *sockaddr, addrlen: nullable *u32) (int | errno) = {
	return wrap_return(syscall3(SYS_getsockname,
		sockfd: u64, addr: uintptr: u64, addrlen: uintptr: u64))?: int;
};

export fn getpeername(sockfd: int, addr: nullable *sockaddr, addrlen: nullable *u32) (int | errno) = {
	return wrap_return(syscall3(SYS_getpeername,
		sockfd: u64, addr: uintptr: u64, addrlen: uintptr: u64))?: int;
};

export fn readv(fd: int, iov: const *[*]iovec, iovcnt: int) (size | errno) = {
	return wrap_return(syscall3(SYS_readv,
		fd: u64, iov: uintptr: u64, iovcnt: u64))?: size;
};

export fn writev(fd: int, iov: const *[*]iovec, iovcnt: int) (size | errno) = {
	return wrap_return(syscall3(SYS_writev,
		fd: u64, iov: uintptr: u64, iovcnt: u64))?: size;
};

export fn sendmsg(fd: int, msg: *const msghdr, flags: int) (int | errno) = {
	return wrap_return(syscall3(SYS_sendmsg,
		fd: u64, msg: uintptr: u64, flags: u64))?: int;
};

export fn recvmsg(fd: int, msg: *const msghdr, flags: int) (int | errno) = {
	return wrap_return(syscall3(SYS_recvmsg,
		fd: u64, msg: uintptr: u64, flags: u64))?: int;
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

export fn getpriority(which: int, who: id_t) (int | errno) = {
	return wrap_return(syscall2(SYS_setpriority,
		which: u64, who: u64))?: int;
};

export fn setpriority(which: int, who: id_t, prio: int) (void | errno) = {
	wrap_return(syscall3(SYS_setpriority, which: u64, who: u64, prio: u64))?;
};

export fn io_uring_setup(entries: u32, params: *void) (int | errno) = {
	return wrap_return(syscall2(SYS_io_uring_setup,
		entries: u64, params: uintptr: u64))?: int;
};

export fn io_uring_register(
	fd: int,
	opcode: uint,
	arg: nullable *void,
	nr_args: uint,
) (int | errno) = wrap_return(syscall4(SYS_io_uring_register,
	fd: u64, opcode: u64, arg: uintptr: u64, nr_args: u64))?: int;

export fn io_uring_enter(
	fd: int,
	to_submit: uint,
	min_complete: uint,
	flags: uint,
	sig: const nullable *sigset,
) (uint | errno) = {
	return wrap_return(syscall5(SYS_io_uring_enter,
		fd: u64, to_submit: u64, min_complete: u64,
		flags: u64, sig: uintptr: u64))?: uint;
};

export fn mlock2(addr: *void, length: size, flags: uint) (void | errno) = {
	return wrap_return(syscall3(SYS_mlock2, addr: uintptr: u64,
		length: u64, flags: u64))?: void;
};

export fn munlock(addr: *void, length: size) (void | errno) = {
	return wrap_return(syscall2(SYS_munlock, addr: uintptr: u64,
		length: u64))?: void;
};

export fn mlockall(flags: uint) (void | errno) = {
	return wrap_return(syscall1(SYS_mlockall, flags: u64))?: void;
};

export fn munlockall() (void | errno) = {
	return wrap_return(syscall0(SYS_munlockall))?: void;
};

export fn prctl(
	option: int,
	arg2: u64,
	arg3: u64,
	arg4: u64,
	arg5: u64,
) (int | errno) = {
	return wrap_return(syscall5(SYS_prctl, option: u64, arg2, arg3, arg4,
		arg5))?: int;
};

export fn add_key(
	keytype: *const char,
	name: *const char,
	payload: *void,
	plen: size,
	keyring: int,
) (int | errno) = {
	return wrap_return(syscall5(SYS_add_key,
		keytype: uintptr: u64, name: uintptr: u64,
		payload: uintptr: u64, plen: u64,
		keyring: u64))?: int;
};

export fn keyctl(
	operation: int,
	arg2: u64,
	arg3: u64,
	arg4: u64,
	arg5: u64,
) (int | errno) = {
	return wrap_return(syscall5(SYS_keyctl, operation: u64,
		arg2, arg3, arg4, arg5))?: int;
};

export fn getsid(pid: int) (int | errno) = {
	return wrap_return(syscall1(SYS_getsid, pid: u64))?: int;
};

export fn setsid() (void | errno) = {
	return wrap_return(syscall0(SYS_setsid))?: void;
};
