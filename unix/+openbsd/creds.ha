// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
// Unix credentials types & functions; ref credentials(7)

use errors;
use rt;

// Process ID.
export type pid = rt::pid_t;

// User ID.
export type uid = rt::uid_t;

// Group ID.
export type gid = rt::gid_t;

// Returns the current process user ID.
export fn getuid() uid = rt::getuid();

// Returns the current process effective user ID.
export fn geteuid() uid = rt::geteuid();

// Returns the current process group ID.
export fn getgid() uid = rt::getgid();

// Returns the current process effective group ID.
export fn getegid() uid = rt::getegid();

// Sets the caller's user ID to the specified value. This generally requires
// elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setuid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[rt::]] yourself,
// and take extreme care to handle errors correctly.
export fn setuid(uid: uid) void = rt::setuid(uid)!;

// Sets the caller's effective user ID to the specified value. This generally
// requires elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from seteuid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[rt::]] yourself,
// and take extreme care to handle errors correctly.
export fn seteuid(uid: uid) void = rt::seteuid(uid)!;

// Sets the caller's group ID to the specified value. This generally requires
// elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setuid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[rt::]] yourself,
// and take extreme care to handle errors correctly.
export fn setgid(gid: gid) void = rt::setgid(gid)!;

// Sets the caller's effective group ID to the specified value. This generally
// requires elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setegid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[rt::]] yourself,
// and take extreme care to handle errors correctly.
export fn setegid(gid: gid) void = rt::setegid(gid)!;

// Returns a list of supplementary group IDs for the current process. The
// returned slice is statically allocated.
export fn getgroups() []gid = {
	static let gids: [rt::NGROUPS_MAX]rt::gid_t = [0...];
	const n = rt::getgroups(gids)!;
	return gids[..n]: []gid;
};

// Sets the list of supplementary group IDs which apply to the current process.
// This generally requires elevated permissions.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setgroups is a grave security issue in your program,
// and therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[rt::]]
// yourself, and take extreme care to handle errors correctly.
export fn setgroups(gids: []gid) void = rt::setgroups(gids: []rt::gid_t)!;

// Returns the current process ID.
export fn getpid() pid = rt::getpid();

// Returns the parent process ID.
export fn getppid() pid = rt::getppid();

// Returns the current process group ID.
export fn getpgrp() pid = rt::getpgrp();

// Returns the process group associated with the given pid.
export fn getpgid(pid: pid) (pid | errors::noentry) = {
	match (rt::getpgid(pid)) {
	case let pid: rt::pid_t =>
		return pid;
	case let err: rt::errno =>
		assert(err == rt::ESRCH, "Unexpected getpgid return value");
		return errors::noentry;
	};
};

// Sets the process group ID of the specified process. This function is
// error-prone; see the notes in the POSIX specification for its many caveats.
export fn setpgid(targ: pid, pgid: pid) (void | errors::error) = {
	match (rt::setpgid(targ, pgid)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void =>
		return;
	};
};

// Returns the current process's session ID.
export fn getsid() pid = rt::getsid(0)!;

// Returns the session ID associated with the given process.
export fn getpsid(pid: pid) (pid | errors::noentry | errors::noaccess) = {
	match (rt::getsid(pid)) {
	case let pid: rt::pid_t =>
		return pid;
	case let err: rt::errno =>
		assert(err == rt::ESRCH, "Unexpected getsid return value");
		return errors::noentry;
	};
};

// Creates a new session and sets the current process to the session leader.
// A new process group is also created with its process group ID equal to the
// pid of the current process, and the current process is made the process group
// leader.
//
// Upon return, the new session will have no controlling terminal. To establish
// one, the caller must open a terminal file with [[fs::flag::CTTY]]; this
// opt-in approach differs from the Unix norm where O_NOCTTY is required to
// opt-out of establishing a controlling terminal.
//
// The current process cannot be a process group leader; this is a programmer
// error and will cause a runtime assertion failure.
export fn setsid() void = rt::setsid()!;
