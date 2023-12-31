// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use endian;
use errors;
use io;
use rt;
use time;

// The timer will trigger only once, after the set duration and never after.
export type oneshot = time::duration;

// The timer will trigger once after a configured delay, then periodically at
// the given interval.
export type interval_delayed = (time::duration, time::duration);

// The timer will trigger periodically at the given interval.
export type interval = time::duration;

// The expiration configuration for the timer.
export type expiration = (oneshot | interval | interval_delayed);

const empty_timerspec: rt::itimerspec = rt::itimerspec {
	it_interval = rt::timespec { tv_sec = 0, tv_nsec = 0 },
	it_value = rt::timespec { tv_sec = 0, tv_nsec = 0 },
};

// Flags to use in [[new]]. CLOEXEC is enabled by default, use NOCLOEXEC to
// disable it.
export type new_flag = enum int {
	NONE = 0,
	NONBLOCK = rt::O_NONBLOCK,
	NOCLOEXEC = rt::O_CLOEXEC,
};

// Flags to use in [[set]].
export type set_flag = enum int {
	NONE = 0,
	ABSTIME = 1,
	CANCEL_ON_SET = 2,
};

// Creates a new timerfd. The timer is initially configured without an
// expiration; see [[set]] to configure it.
export fn new(
	clockid: time::clock,
	flags: new_flag,
) (io::file | errors::error) = {
	flags ^= new_flag::NOCLOEXEC;

	match (rt::timerfd_create(clockid, flags)) {
	case let fd: int =>
		return fd;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};

// Sets the expiration configuration for a timerfd, overwriting any
// previously set expiration.
export fn set(
	t: io::file,
	exp: expiration,
	flags: set_flag,
) (void | errors::error) = {
	const timerspec = match (exp) {
	case let o: oneshot =>
		yield rt::itimerspec {
			it_interval = rt::timespec { tv_sec = 0, tv_nsec = 0 },
			it_value = time::duration_to_timespec(o),
		};
	case let i: interval =>
		const interval_timespec = time::duration_to_timespec(i);
		yield rt::itimerspec {
			it_interval = interval_timespec,
			it_value = interval_timespec,
		};
	case let id: interval_delayed =>
		yield rt::itimerspec {
			it_interval = time::duration_to_timespec(id.0),
			it_value = time::duration_to_timespec(id.1),
		};
	};

	match (rt::timerfd_settime(t, flags, &timerspec, null)) {
	case let ok: int =>
		return;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};

// Unsets any expiration that was previously set on the given timer.
export fn unset(
	t: io::file,
) (void | errors::error) = {
	match (rt::timerfd_settime(t, 0, &empty_timerspec, null)) {
	case int =>
		return;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};

// Reading from the timerfd returns the number of times the timer has expired
// since the last call to [[set]] or [[read]]. This call can be blocking or not
// depending on the flags passed to [[new]]. Reading from a blocking unset
// timerfd will block forever.
export fn read(
	t: io::file
) (u64 | errors::error) = {
	let expirations: [8]u8 = [0...];
	match (rt::read(t, &expirations, len(expirations))) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let z: size =>
		assert(z == len(expirations));
	};
	return endian::host.getu64(expirations);
};

@test fn timerfd() void = {
	let blocking_fd = new(time::clock::MONOTONIC, new_flag::NONE)!;

	// one-shot blocking
	// the first read should block and eventually return 1
	// subsequent reads will block indefinitely
	set(blocking_fd, 100: oneshot, set_flag::NONE)!;
	let one = read(blocking_fd)!;
	assert(one == 1);

	// interval blocking
	// the first read should block and eventually return the number of times
	// the timer expired
	// subsequent reads should return instantly with the number of times the
	// timer expired since the last read
	set(blocking_fd, 100: interval, set_flag::NONE)!;
	let first = read(blocking_fd)!;
	let second = read(blocking_fd)!;

	assert(first > 0);
	assert(second > 0);

	// unset blocking timer
	// reading here would block us forever
	unset(blocking_fd)!;

	io::close(blocking_fd)!;
};
