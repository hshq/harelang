// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

let pathbuf: [PATH_MAX]u8 = [0...];

// For functions that need more than one path, i.e. unveil, linkat, renameat, etc.
let pathbuf1: [PATH_MAX]u8 = [0...];

export type path = (str | []u8 | *const u8);

fn copy_cpath(path: path, buf: []u8) (*const u8 | errno) = {
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
	if (len(path) + 1 >= len(buf)) {
		return ENAMETOOLONG;
	};
	memcpy(buf: *[*]u8, path: *[*]u8, len(path));
	buf[len(path)] = 0;
	return buf: *[*]u8: *const u8;
};

// NUL terminates a string and stores it in a static buffer of PATH_MAX bytes in
// length.
fn cpath(path: path) (*const u8 | errno) = {
	return copy_cpath(path, pathbuf);
};

// /usr/include/errno.h: #define errno (*__errno())
@symbol("__errno") fn __errno() *int;

// exit
export @symbol("exit") fn exit(status: int) never;

// fork

@symbol("fork") fn libc_fork() int;

export fn fork() (int | void | errno) = {
	let res = libc_fork();
	if (res == -1) {
		return *__errno(): errno;
	};
	if (res == 0) {
		return;
	};
	return res;
};

// read

@symbol("read") fn libc_read(d: int, buf: *opaque, nbytes: size) size;

export fn read(fd: int, buf: *opaque, count: size) (size | errno) = {
	let res: u64 = libc_read(fd, buf, count);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// write

@symbol("write") fn libc_write(d: int, buf: *const opaque, nbytes: size) size;

export fn write(fd: int, buf: *const opaque, count: size) (size | errno) = {
	let res: u64 = libc_write(fd, buf, count);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// open

@symbol("open") fn libc_open(path: *opaque, flags: int, mode: int) int;

export fn open(path: path, flags: int, mode: int) (int | errno) = {
	let res = libc_open(cpath(path)?, flags, mode);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// posix_openpt (libc function not a syscall)

@symbol("posix_openpt") fn libc_openpt(oflag: int) int;

export fn posix_openpt(flags: int) (int | errno) = {
	let res = libc_openpt(flags);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// close

@symbol("close") fn libc_close(d: int) int;

export fn close(fd: int) (void | errno) = {
	let res = libc_close(fd);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// getentropy
// __tfork
// link
// unlink
// wait4

@symbol("wait4") fn libc_wait4(
	wpid: pid_t,
	status: nullable *int,
	options: int,
	rusage: nullable *rusage
) pid_t;

export fn wait4(
	pid: pid_t,
	wstatus: nullable *int,
	options: int,
	rusage: nullable *rusage,
) (pid_t | errno) = {
	let res = libc_wait4(pid, wstatus, options, rusage);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// chdir

@symbol("chdir") fn libc_chdir(path: *const u8) int;

export fn chdir(path: path) (void | errno) = {
	let res = libc_chdir(cpath(path)?);

	if (res == -1)  {
		return *__errno(): errno;
	};
};

// fchdir

@symbol("fchdir") fn libc_fchdir(fd: int) int;

export fn fchdir(fd: int) (void | errno) = {
	let res = libc_fchdir(fd);

	if (res == -1)  {
		return *__errno(): errno;
	};
};

// mknod
// chmod
// chown
// obreak
// getdtablecount
// getrusage
// getpid

export @symbol("getpid") fn getpid() pid_t;

// mount
// unmount
// setuid

@symbol("setuid") fn libc_setuid(uid: uid_t) int;

export fn setuid(uid: uid_t) (void | errno) = {
	let res = libc_setuid(uid);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// getuid

export @symbol("getuid") fn getuid() uid_t;

// geteuid

export @symbol("geteuid") fn geteuid() uid_t;

// ptrace
// recvmsg

@symbol("recvmsg") fn libc_recvmsg(s: int, msg: *const msghdr, flags: int) i64;

export fn recvmsg(fd: int, msg: *const msghdr, flags: int) (int | errno) = {
	let res = libc_recvmsg(fd, msg, flags);
	if (res == -1) {
		return *__errno(): errno;
	};
	// TODO: could overflow
	return res: int;
};

// sendmsg

@symbol("sendmsg") fn libc_sendmsg(s: int, msg: *const msghdr, flags: int) i64;

export fn sendmsg(fd: int, msg: *const msghdr, flags: int) (int | errno) = {
	let res = libc_sendmsg(fd, msg, flags);
	if (res == -1) {
		return *__errno(): errno;
	};
	// TODO: could overflow
	return res: int;
};

// recvfrom

@symbol("recvfrom") fn libc_recvfrom(
	s: int,
	buf: *opaque,
	length: size,
	flags: int,
	from: nullable *sockaddr,
	fromlen: nullable *u32,
) i64;

export fn recvfrom(
	sockfd: int,
	buf: *opaque,
	length: size,
	flags: int,
	from: nullable *sockaddr,
	fromlen: nullable *u32
) (size | errno) = {
	let res = libc_recvfrom(sockfd, buf, length, flags, from, fromlen);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res: size;
};

// accept
// getpeername

@symbol("getpeername") fn libc_getpeername(
	s: int,
	name: *sockaddr,
	namelen: *u32
) int;

export fn getpeername(
	sockfd: int,
	addr: *sockaddr,
	addrlen: *u32
) (void | errno) = {
	let res = libc_getpeername(sockfd, addr, addrlen);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// getsockname

@symbol("getsockname") fn libc_getsockname(
	sockfd: int,
	addr: nullable *sockaddr,
	addrlen: nullable *u32
) int;

export fn getsockname(
	sockfd: int,
	addr: nullable *sockaddr,
	addrlen: nullable *u32
) (void | errno) = {
	let res = libc_getsockname(sockfd, addr, addrlen);
	if (res == -1) {
		return *__errno(): errno;
	};

};
// access

@symbol("access") fn libc_access(path: *const u8, amode: int) int;

export fn access(path: path, amode: int) (bool | errno) = {
	let res = libc_access(cpath(path)?, amode);
	if (res == -1) {
		let err = *__errno(): errno;

		switch (res) {
		case EACCES =>
			return false;
		case =>
			return err;
		};
	};

	return true;
};


// chflags
// fchflags
// sync
// msyscall
// stat

// getppid

export @symbol("getppid") fn getppid() pid_t;

// lstat
// dup
// fstatat

@symbol("fstatat") fn libc_fstatat(fd: int, path: *const u8, sb: *stat, flag: int) int;

export fn fstatat(
	dirfd: int,
	path: path,
	stat: *stat,
	flag: int
) (void | errno) = {
	let res = libc_fstatat(dirfd, cpath(path)?, stat, flag);
	if (res == -1) {
		return *__errno(): errno;
	};
};


// getegid

export @symbol("getegid") fn getegid() gid_t;

// profil
// ktrace
// sigaction
// sigaltstack

export @symbol("sigaction") fn libc_sigaction(
	sig: int,
	act: *const sigact,
	oact: nullable *sigact
) int;

export fn sigaction(
	signum: int,
	act: *const sigact,
	old: nullable *sigact,
) (void | errno) = {
	let res = libc_sigaction(signum, act, old);
	if (res == -1) {
		return *__errno(): errno;
	};
};

export @symbol("sigaltstack") fn libc_sigaltstack(
	ss: const nullable *stack_t, oss: nullable *stack_t,
) int;

export fn sigaltstack(
	ss: const nullable *stack_t,
	oss: nullable *stack_t,
) (void | errno) = {
	let res = libc_sigaltstack(ss, oss);
	if (res == -1) {
		return *__errno(): errno;
	};
};
// getgid

export @symbol("getgid") fn getgid() gid_t;

// sigprocmask

@symbol("sigprocmask") fn libc_sigprocmask(
	how: int,
	set: nullable *const sigset,
	old: nullable *sigset
) int;

export fn sigprocmask(
	how: int,
	set: nullable *const sigset,
	old: nullable *sigset
) (void | errno) = {
	let res = libc_sigprocmask(how, set, old);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// mmap

@symbol("mmap") fn libc_mmap(
	addr: nullable *opaque,
	len_: size,
	prot: int,
	flags: int,
	fd: int,
	pos: i64
) nullable *opaque;

export fn mmap(
	addr: nullable *opaque,
	len_: size,
	prot: int,
	flags: int,
	fd: int,
	pos: i64
) (*opaque | errno) = {
	let res = libc_mmap(addr, len_, prot, flags, fd, pos);

	if (res == null) {
		return *__errno(): errno;
	};
	return res: *opaque;
};

// setlogin
// acct
// sigpending
// fstat
// ioctl

@symbol("ioctl") fn libc_ioctl(fd: int, req: u64, arg: u64) int;

export type ioctl_arg = (nullable *opaque | u64);

export fn ioctl(fd: int, req: u64, arg: ioctl_arg) (int | errno) = {
	let res = match (arg) {
	case let u: u64 =>
		yield libc_ioctl(fd, req, u);
	case let ptr: nullable *opaque =>
		yield libc_ioctl(fd, req, ptr: uintptr: u64);
	};
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// reboot
// revoke
// symlink
// readlink
// execve

@symbol("execve") fn libc_execve(path: *const u8, argv: *[*]nullable *const u8,
		envp: *[*]nullable *const u8) int;

export fn execve(path: path, argv: *[*]nullable *const u8,
		envp: *[*]nullable *const u8) errno = {
	let res = libc_execve(cpath(path)?, argv, envp);
	return *__errno(): errno;
};

// umask

@symbol("umask") fn libc_umask(numask: mode_t) mode_t;

export fn umask(mode: mode_t) (mode_t | errno) = {
	// Always successful on OpenBSD.
	return libc_umask(mode);
};

// chroot

@symbol("chroot") fn libc_chroot(dirname: *const u8) int;

export fn chroot(path: path) (void | errno) = {
	let res = libc_chroot(cpath(path)?);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// getfsstat
// statfs
// fstatfs
// fhstatfs
// vfork
// gettimeofday
// settimeofday
// select
// kevent

@symbol("kevent") fn libc_kevent(
	kq: int,
	changelist: nullable *const [*]kevent,
	nchanges: int,
	eventlist: nullable *[*]kevent,
	nevents: int,
	timeout: nullable *const timespec
) int;

// kevent() wrapper. Renamed to not conflict with the struct "kevent"
export fn kevent_poll(
	kq: int,
	changelist: nullable *const [*]kevent,
	nchanges: int,
	eventlist: nullable *[*]kevent,
	nevents: int,
	timeout: nullable *const timespec
) (int | errno) = {
	let res = libc_kevent(kq, changelist, nchanges, eventlist, nevents,
		timeout);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// munmap

@symbol("munmap") fn libc_munmap(addr: *opaque, len_: size) int;

export fn munmap(addr: *opaque, len_: size) (void | errno) = {
	let res = libc_munmap(addr, len_);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// mprotect
// madvise
// utimes
// futimes
// mquery
// getgroups

@symbol("getgroups") fn libc_getgroups(gidsetlen: int, gidset: *[*]gid_t) int;

export fn getgroups(gids: []gid_t) (uint | errno) = {
	let res = libc_getgroups(len(gids): int, gids: *[*]gid_t);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res: uint;
};

// setgroups

@symbol("setgroups") fn libc_setgroups(
	ngroups: int,
	gidset: *[*]gid_t,
) int;

export fn setgroups(gids: []gid_t) (void | errno) = {
	let res = libc_setgroups(len(gids): int, gids: *[*]gid_t);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// getpgrp

export @symbol("getpgrp") fn getpgrp() pid_t;

// setpgid

@symbol("setpgid") fn libc_setpgid(pid: pid_t, pgrp: pid_t) int;

export fn setpgid(pid: pid_t, pgrp: pid_t) (void | errno) = {
	let res = libc_setpgid(pid, pgrp);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// futex
// utimensat

@symbol("utimensat") fn libc_utimensat(
	fd: int,
	path: *const u8,
	times: *const [2]timespec,
	flag: int
) int;

export fn utimensat(
	dirfd: int,
	path: str,
	ts: *[2]timespec,
	flags: int
) (void | errno) = {
	let res = libc_utimensat(dirfd, cpath(path)?, ts, flags);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// futimens

@symbol("futimens") fn libc_futimens(
	fd: int,
	times: *const [2]timespec
) int;

export fn futimens(fd: int, ts: *[2]timespec) (void | errno) = {
	let res = libc_futimens(fd, ts);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// kbind
// clock_gettime

@symbol("clock_gettime") fn libc_clock_gettime(clock: int, now: *timespec) int;

export fn clock_gettime(clock: int, now: *timespec) (void | errno) = {
	let res = libc_clock_gettime(clock, now);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// clock_settime
// clock_getres
// dup2

@symbol("dup2") fn libc_dup2(oldd: int, newd: int) int;

export fn dup2(oldfd: int, newfd: int) (int | errno) = {
	let res = libc_dup2(oldfd, newfd);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// nanosleep

@symbol("nanosleep") fn libc_nanosleep(
	timeout: *const timespec,
	remainder: *timespec
) int;

export fn nanosleep(
	timeout: *const timespec,
	remainder: *timespec
) (void | errno) = {
	let res = libc_nanosleep(timeout, remainder);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// fcntl

@symbol("fcntl") fn libc_fcntl(fd: int, cmd: int, arg: u64) int;

export type fcntl_arg = (void | int | *st_flock | *u64);

export fn fcntl(fd: int, cmd: int, arg: fcntl_arg) (int | errno) = {
	let res = match (arg) {
	case void =>
		yield libc_fcntl(fd, cmd, 0);
	case let i: int =>
		yield libc_fcntl(fd, cmd, i: u64);
	case let l: *st_flock =>
		yield libc_fcntl(fd, cmd, l: uintptr: u64);
	case let u: *u64 =>
		yield libc_fcntl(fd, cmd, u: uintptr: u64);
	};
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// accept4

@symbol("accept4") fn libc_accept4(
	s: int,
	addr: nullable *sockaddr,
	adddrlen: nullable *u32,
	flags: int
) int;

export fn accept4(
	sockfd: int,
	addr: nullable *sockaddr,
	addrlen: nullable *u32,
	flags: int
) (int | errno) = {
	let res = libc_accept4(sockfd, addr, addrlen, flags);
	if (res == -1) {
		return  *__errno(): errno;
	};
	return res;
};

// __thrsleep
// fsync
// setpriority

@symbol("setpriority") fn libc_setpriority(
	which: int,
	who: id_t,
	prio: int
) int;

export fn setpriority(which: int, who: id_t, prio: int) (void | errno) = {
	let res = libc_setpriority(which, who, prio);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// socket

@symbol("socket") fn libc_socket(domain: int, t: int, protocol: int) int;

export fn socket(domain: int, t: int, protocol: int) (int | errno) = {
	let res = libc_socket(domain, t, protocol);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// connect

@symbol("connect") fn libc_connect(
	sockfd: int,
	addr: *const sockaddr,
	addrlen: u32
) int;

export fn connect(
	sockfd: int,
	addr: *const sockaddr,
	addrlen: u32
) (void | errno) = {
	let res = libc_connect(sockfd, addr, addrlen);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// getdents

@symbol("getdents") fn libc_getdents(fd: int, buf: *opaque, nbytes: size) int;

export fn getdents(dirfd: int, buf: *opaque, nbytes: size) (int | errno) = {
	let res = libc_getdents(dirfd, buf, nbytes);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// getpriority

@symbol("getpriority") fn libc_getpriority(which: int, who: id_t) int;

export fn getpriority(which: int, who: id_t) (int | errno) = {
	let res = libc_getpriority(which, who);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// pipe2

@symbol("pipe2") fn libc_pipe2(pipefd: *[2]int, flags: int) int;

export fn pipe2(pipefd: *[2]int, flags: int) (void | errno) = {
	let res = libc_pipe2(pipefd, flags);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// dup3
// sigreturn
// bind

@symbol("bind") fn libc_bind(
	sockfd: int,
	addr: *const sockaddr,
	addrlen: u32
) int;

export fn bind(
	sockfd: int,
	addr: *const sockaddr,
	addrlen: u32
) (void | errno) = {
	let res = libc_bind(sockfd, addr, addrlen);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// setsockopt

@symbol("setsockopt") fn libc_setsockopt(
	s: int,
	level: int,
	optname: int,
	optval: *opaque,
	optlen: u32
) int;

export fn setsockopt(
	sockfd: int,
	level: int,
	optname: int,
	optval: *opaque,
	optlen: u32
) (void | errno) = {
	let res = libc_setsockopt(sockfd, level, optname, optval, optlen);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// listen

@symbol("listen") fn libc_listen(s: int, backlog: int) int;

export fn listen(sockfd: int, backlog: u32) (void | errno) = {
	let res = libc_listen(sockfd, backlog: int);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// chflagsat
// pledge

@symbol("pledge") fn libc_pledge(
	promises: nullable *const u8,
	execpromises: nullable *const u8
) int;

// The "stdio" pledge is always needed. Passing [[nullpromise]] to promises or
// execpromises specifies to not change the current value. Check the pledge(2)
// manual page for more information about the differrent promises.
export fn pledge(
	promises: (const str | nullpromise),
	execpromises: (const str | nullpromise),
) (void | errno) = {
	let promises: nullable *u8 = match(promises) {
	case let p: const str =>
		yield cpath(p)!;
	case nullpromise =>
		yield null;
	};

	let execpromises: nullable *u8 = match(execpromises) {
	case let ep: const str =>
		yield copy_cpath(ep, pathbuf1)!;
	case nullpromise =>
		yield null;
	};

	let res = libc_pledge(promises, execpromises);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// ppoll

@symbol("ppoll") fn libc_ppoll(
	fds: *[*]pollfd,
	nfds: nfds_t,
	timeout: const nullable *timespec,
	mask: const nullable *sigset,
) int;

export fn ppoll(
	fds: *[*]pollfd,
	nfds: nfds_t,
	timeout: const nullable *timespec,
	sigmask: const nullable *sigset,
) (int | errno) = {
	let ret = libc_ppoll(fds, nfds, timeout, sigmask);
	if (ret == -1) {
		return *__errno(): errno;
	};
	return ret;
};

// pselect
// sigsuspend
// sendsyslog
// unveil

@symbol("unveil") fn libc_unveil(
	path: nullable *const u8,
	permissions: nullable *const u8
) int;

// After establishing a collection of path and permissions rules, future
// calls to [[unveil]] can be disabled by calling [[unveil_lock]].
// Alternatively, [[pledge]] may be used to remove the "unveil" promise.
export fn unveil(
	path: path,
	permissions: const str,
) (void | errno) = {
	let res = libc_unveil(cpath(path)?, copy_cpath(permissions, pathbuf1)?);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// Disable future calls to [[unveil]].
export fn unveil_lock() (void | errno) = {
	let res = libc_unveil(null, null);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// __realpath
// recvmmsg
// sendmmsg
// getsockopt

@symbol("getsockopt") fn libc_getsockopt(
	s: int,
	level: int,
	optname: int,
	optval: nullable *opaque,
	optlen: nullable *u32
) int;

export fn getsockopt(
	sockfd: int,
	level: int,
	optname: int,
	optval: nullable *opaque,
	optlen: nullable *u32
) (void | errno) = {
	let res = libc_getsockopt(sockfd, level, optname, optval, optlen);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// thrkill
// readv

@symbol("readv") fn libc_readv(d: int, iov: const *[*]iovec, iovcnt: int) size;

export fn readv(fd: int, iov: const *[*]iovec, iovcnt: int) (size | errno) = {
	let res: u64 = libc_readv(fd, iov, iovcnt);

	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// writev

@symbol("writev") fn libc_writev(d: int, iov: const *[*]iovec, iovcnt: int) size;

export fn writev(fd: int, iov: const *[*]iovec, iovcnt: int) (size | errno) = {
	let res: u64 = libc_writev(fd, iov, iovcnt);

	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// kill

@symbol("kill") fn libc_kill(pid: int, signal: int) int;

export fn kill(pid: int, signal: int) (void | errno) = {
	let res = libc_kill(pid, signal);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// fchown

@symbol("fchown") fn libc_fchown(
	fd: int,
	owner: uid_t,
	group: gid_t
) int;

export fn fchown(fd: int, uid: uid_t, gid: gid_t) (void | errno) = {
	let res = libc_fchown(fd, uid, gid);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// fchmod

@symbol("fchmod") fn libc_fchmod(
	fd: int,
	mode: uint
) int;

export fn fchmod(fd: int, mode: uint) (void | errno) = {
	let res = libc_fchmod(fd, mode);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// setreuid
// setregid
// rename
// flock

@symbol("flock") fn libc_flock(fd: int, operation: int) int;

export fn flock(fd: int, op: int) (void | errno) = {
	let res = libc_flock(fd, op);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// mkfifo
// sendto

@symbol("sendto") fn libc_sendto(
	s: int,
	msg: *opaque,
	length: size,
	flags: int,
	to: nullable *sockaddr,
	tolen: socklen_t
) i64;

export fn sendto(
	sockfd: int,
	buf: *opaque,
	length: size,
	flags: int,
	dest_addr: nullable *sockaddr,
	addrlen: u32
) (size | errno) = {
	let res = libc_sendto(sockfd, buf, length, flags, dest_addr, addrlen);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res: size;
};

// shutdown

@symbol("shutdown") fn libc_shutdown(s: int, how: int) int;

export fn shutdown(s: int, how: int) (void | errno) = {
	let res = libc_shutdown(s, how);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// socketpair

@symbol("socketpair") fn libc_socketpair(
	domain: int,
	type_: int,
	protocol: int,
	sv: *[*]int
) int;

export fn socketpair(
	domain: int,
	type_: int,
	protocol: int,
	sv: *[*]int
) (void | errno) = {
	let res = libc_socketpair(domain, type_, protocol, sv);
	if (res == -1) {
		return *__errno(): errno;
	};

};
// mkdir
// rmdir
// adjtime
// getlogin_r
// getthrname
// setthrname
// pinsyscall

// setsid

@symbol("setsid") fn libc_setsid() pid_t;

export fn setsid() (void | errno) = {
	let res = libc_setsid();
	if (res == -1) {
		return *__errno(): errno;
	};
};

// quotactl
// ypconnect
// nfssvc
// mimmutable
// waitid
// getfh
// __tmpfd
// sysarch
// lseek

@symbol("lseek") fn libc_lseek(fildes: int, pos: i64, whence: int) i64;

export fn lseek(fd: int, off: i64, whence: int) (i64 | errno) = {
	let res = libc_lseek(fd, off, whence);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// truncate
// ftruncate

@symbol("ftruncate") fn libc_ftruncate(fd: int, length: i64) int;

export fn ftruncate(fd: int, length: i64) (void | errno) = {
	let res = libc_ftruncate(fd, length);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// pread
// pwrite
// preadv
// pwritev
// setgid

@symbol("setgid") fn libc_setgid(gid: gid_t) int;

export fn setgid(gid: gid_t) (void | errno) = {
	let res = libc_setgid(gid);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// setegid

@symbol("setegid") fn libc_setegid(gid: gid_t) int;

export fn setegid(gid: gid_t) (void | errno) = {
	let res = libc_setegid(gid);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// seteuid

@symbol("seteuid") fn libc_seteuid(uid: uid_t) int;

export fn seteuid(uid: uid_t) (void | errno) = {
	let res = libc_seteuid(uid);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// pathconf
// fpathconf
// swapctl
// getrlimit
// setrlimit
// sysctl

@symbol("sysctl") fn libc_sysctl(
	name: *[*]int,
	namelen: uint,
	oldp: nullable *opaque,
	oldlenp: nullable *size,
	newp: nullable *opaque,
	newlen: size
) int;

export fn sysctl(
	name: []int,
	namelen: uint,
	oldp: nullable *opaque,
	oldlenp: nullable *size,
	newp: nullable *opaque,
	newlen: size
) (void | errno) = {
	let res = libc_sysctl(name: *[*]int, namelen, oldp, oldlenp, newp, newlen);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// mlock
// munlock
// getpgid

@symbol("getpgid") fn libc_getpgid(pid: pid_t) pid_t;

export fn getpgid(pid: pid_t) (pid_t | errno) = {
	let res = libc_getpgid(pid);
	if (res == -1) {
		return *__errno(): errno;
	};

	return res;
};

// utrace
// semget
// msgget
// msgsnd
// msgrcv
// shmat
// shmdt
// minherit
// poll
// issetugid
// lchown

// shm_open

@symbol("shm_open") fn libc_shm_open(path: *const u8, flags: int, mode: mode_t) int;

export fn shm_open(path: path, flags: int, mode: mode_t) (int | errno) = {
	let res = libc_shm_open(cpath(path)?, flags, mode);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// shm_unlink

@symbol("shm_unlink") fn libc_shm_unlink(path: *const u8) int;

export fn shm_unlink(path: path) (void | errno) = {
	let res = libc_shm_unlink(cpath(path)?);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// getsid

@symbol("getsid") fn libc_getsid(pid: pid_t) pid_t;

export fn getsid(pid: pid_t) (pid_t | errno) = {
	let res = libc_getsid(pid);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// msync
// pipe
// fhopen
// kqueue

@symbol("kqueue") fn libc_kqueue() int;

export fn kqueue() (int | errno) = {
	let res = libc_kqueue();
	if (res == -1) {
		return *__errno(): errno;
	};

	return res;
};

// kqueue1

@symbol("kqueue1") fn libc_kqueue1(flags: int) int;

export fn kqueue1(flags: int) (int | errno) = {
	let res = libc_kqueue1(flags);
	if (res == -1) {
		return *__errno(): errno;
	};

	return res;
};

// mlockall
// munlockall
// getresuid
// setresuid
// getresgid
// setresgid
// closefrom
// sigaltstack
// shmget
// semop
// fhstat
// __semctl
// shmctl
// msgctl
// sched_yield
// getthrid
// __thrwakeup
// __threxit
// __thrsigdivert
// getcwd

@symbol("getcwd") fn libc_getcwd(buf: *u8, bufsz: size) *u8;

// The return value is statically allocated and must be duplicated before
// calling getcwd again.
export fn getcwd() (*const u8 | errno) = {
	static let pathbuf: [PATH_MAX]u8 = [0...];

	let res = libc_getcwd(&pathbuf: *u8, len(pathbuf));
	if (res == null) {
		return *__errno(): errno;
	};

	return res;
};

// adjfreq
// setrtable
// getrtable
// faccessat
// fchmodat

@symbol("fchmodat") fn libc_fchmodat(
	fd: int,
	path: *const u8,
	mode: mode_t,
	flag: int
) int;

export fn fchmodat(
	dirfd: int,
	path: path,
	mode: mode_t,
	flag: int
) (void | errno) = {
	let res = libc_fchmodat(dirfd, cpath(path)?, mode, flag);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// fchownat

@symbol("fchownat") fn libc_fchownat(
	fd: int,
	path: *const u8,
	owner: uid_t,
	group: gid_t,
	flag: int
) int;

export fn fchownat(
	dirfd: int,
	path: path,
	uid: uid_t,
	gid: gid_t,
	flag: int
) (void | errno) = {
	let res = libc_fchownat(dirfd, cpath(path)?, uid, gid, flag);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// linkat

@symbol("linkat") fn libc_linkat(
	fd1: int,
	name1: *const u8,
	fd2: int,
	name2: *const u8,
	flag: int
) int;

export fn linkat(
	olddirfd: int,
	oldpath: path,
	newdirfd: int,
	newpath: path,
	flags: int,
) (void | errno) = {
	let oldpath = cpath(oldpath)?;
	let newpath = copy_cpath(newpath, pathbuf1)?;

	let res = libc_linkat(olddirfd, oldpath, newdirfd, newpath, flags);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// mkdirat

@symbol("mkdirat") fn libc_mkdirat(fd: int, path: *const u8, mode: mode_t) int;

export fn mkdirat(dirfd: int, path: path, mode: mode_t) (void | errno) = {
	let res = libc_mkdirat(dirfd, cpath(path)?, mode);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// mkfifoat
// mknodat

@symbol("mknodat") fn libc_mknodat(
	fd: int,
	path: *const u8,
	mode: mode_t,
	dev: dev_t
) int;

// The OpenBSD implementation of mknodat *only* supports FIFO and
// device special files.
export fn mknodat(
	dirfd: int,
	path: path,
	mode: mode_t,
	dev: dev_t,
) (void | errno) = {
	let res = libc_mknodat(dirfd, cpath(path)?, mode, dev);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// openat

@symbol("openat") fn libc_openat(
	fd: int,
	path: *const u8,
	flags: int,
	mode: uint,
) int;

export fn openat(
	dirfd: int,
	path: path,
	flags: int,
	mode: uint,
) (int | errno) = {
	let res = libc_openat(dirfd, cpath(path)?, flags, mode);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// readlinkat

@symbol("readlinkat") fn libc_readlinkat(
	fd: int,
	path: *const u8,
	buf: *u8,
	bufsiz: size
) i64;

export fn readlinkat(
	dirfd: int,
	path: path,
	buf: []u8,
) (size | errno) = {
	let res = libc_readlinkat(dirfd, cpath(path)?, buf: *[*]u8: *u8, len(buf));
	if (res == -1) {
		return *__errno(): errno;
	};
	return res: size;
};

// renameat

@symbol("renameat") fn libc_renameat(
	fromfd: int,
	from: *const u8,
	tofd: int,
	to: *const u8
) int;

export fn renameat(
	olddirfd: int,
	oldpath: str,
	newdirfd: int,
	newpath: str,
) (void | errno) = {
	let newpath = copy_cpath(newpath, pathbuf1)?;

	let res = libc_renameat(olddirfd, cpath(oldpath)?, newdirfd,
			newpath);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// symlinkat

@symbol("symlinkat") fn libc_symlinkat(
	name1: *const u8,
	fd: int,
	name2: *const u8
) int;

export fn symlinkat(
	target: path,
	newdirfd: int,
	linkpath: path,
) (void | errno) = {
	let target = cpath(target)?;
	let linkpath = copy_cpath(linkpath, pathbuf1)?;

	let res = libc_symlinkat(target, newdirfd, linkpath);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// unlinkat

@symbol("unlinkat") fn libc_unlinkat(fd: int, path: *const u8, flag: int) int;

export fn unlinkat(dirfd: int, path: path, flags: int) (void | errno) = {
	let res = libc_unlinkat(dirfd, cpath(path)?, flags);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// __set_tcb
// __get_tcb
