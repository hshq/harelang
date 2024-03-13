// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Converts a [[duration]] to an [[rt::timespec]]. This function is
// non-portable.
export fn duration_to_timespec(n: duration) rt::timespec = rt::timespec {
	tv_sec = n / SECOND,
	tv_nsec = n % SECOND,
};

// Converts a [[duration]] to an [[rt::timeval]]. This function is
// non-portable.
export fn duration_to_timeval(d: duration) rt::timeval = rt::timeval {
	tv_sec = d / SECOND,
	tv_usec = d % SECOND / 1000,
};

// Converts an [[instant]] to an [[rt::timespec]]. This function is
// non-portable.
export fn instant_to_timespec(t: instant) rt::timespec = rt::timespec {
	tv_sec = t.sec,
	tv_nsec = t.nsec,
};

// Converts a [[rt::timespec]] to an [[instant]]. This function is
// non-portable.
export fn timespec_to_instant(ts: rt::timespec) instant = instant {
	sec = ts.tv_sec,
	nsec = ts.tv_nsec,
};

// Yields the process to the kernel and returns after the requested duration.
export fn sleep(d: duration) void = {
	let req = duration_to_timespec(d);

	for (true) {
		let res = rt::timespec { ... };
		match (rt::nanosleep(&req, &res)) {
		case void =>
			return;
		case let err: rt::errno =>
			switch (err) {
			case rt::EINTR =>
				req = res;
			case =>
				abort("Unexpected error from nanosleep");
			};
		};
	};
};

// An enumeration of clocks available on this system. Different clocks represent
// times from different epochs, and have different characteristics with regards
// to leap seconds, NTP adjustments, and so on. All systems provide the REALTIME
// and MONOTONIC clocks at least; use of other clocks is not guaranteed to be
// portable.
export type clock = enum {
	// The current wall-clock time. This may jump forwards or backwards in
	// time to account for leap seconds, NTP adjustments, etc.
	REALTIME = rt::CLOCK_REALTIME,

	// The current monotonic time. This clock measures from some undefined
	// epoch and is not affected by leap seconds, NTP adjustments, and
	// changes to the system time: it always increases by one second per
	// second.
	MONOTONIC = rt::CLOCK_MONOTONIC,

	// The uptime clock. It is the time that has elapsed since the system
	// booted. Begins at zero.
	BOOT = rt::CLOCK_BOOTTIME,

	// The runtime clock. It only advances while the system is not suspended
	// and begins when the system is booted. Begins at zero.
	UPTIME = rt::CLOCK_UPTIME,

	// The process CPU clock. It begins at zero and is advanced while the
	// calling process is running in user or kernel mode.
	PROCESS_CPU = rt::CLOCK_PROCESS_CPUTIME_ID,

	// The thread CPU clock. It begins at zero and is advanced while the
	// calling thread is running in user or kernel mode.
	THREAD_CPU = rt::CLOCK_THREAD_CPUTIME_ID,
};

// Returns the current time for a given clock.
export fn now(clock: clock) instant = {
	let ts = rt::timespec { ... };
	match (rt::clock_gettime(clock, &ts)) {
	case void =>
		return timespec_to_instant(ts);
	case let err: rt::errno =>
		abort("Unexpected error from clock_gettime");
	};
};
