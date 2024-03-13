// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use linux::vdso;
use rt;

// Converts a [[duration]] to an [[rt::timespec]]. This function is
// non-portable.
export fn duration_to_timespec(d: duration) rt::timespec = rt::timespec {
	tv_sec = d / SECOND,
	tv_nsec = d % SECOND,
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

// Converts a [[rt::timespec]] to an [[instant]]. This function is non-portable.
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
	REALTIME = 0,

	// The current monotonic time. This clock measures from some undefined
	// epoch and is not affected by leap seconds, NTP adjustments, and
	// changes to the system time: it always increases by one second per
	// second.
	MONOTONIC = 1,

	// Measures CPU time consumed by the calling process.
	PROCESS_CPU = 2,

	// Time since the system was booted. Increases monotonically and, unlike
	// [[MONOTONIC]], continues to tick while the system is suspended.
	BOOT = 7,

	// This clock is like [[REALTIME]], but will wake the system if it is suspended.
	REALTIME_ALARM = 8,
	// This clock is like [[BOOT]], but will wake the system if it is suspended.
	BOOT_ALARM = 9,

	// A system-wide clock derived from wall-clock time but ignoring leap seconds.
	TAI = 11,
};

fn cgt_vdso() nullable *fn(int, *rt::timespec) int = {
	static let vdso_checked: bool = false;
	static let cgt_vdso: nullable *fn(int, *rt::timespec) int = null;
	if (vdso_checked) {
		return cgt_vdso;
	};
	vdso_checked = true;
	cgt_vdso = vdso::getsym(VDSO_CGT_SYM, VDSO_CGT_VER):
		nullable *fn(int, *rt::timespec) int;
	return cgt_vdso;
};

fn now_vdso(clock: clock, tp: *rt::timespec) (void | rt::errno) = {
	const vfn = match (cgt_vdso()) {
	case null =>
		return rt::ENOSYS;
	case let vfn: *fn(int, *rt::timespec) int =>
		yield vfn;
	};
	const ret = vfn(clock, tp);
	if (ret == 0) {
		return;
	};
	return ret;
};

// Returns the current time for a given clock.
export fn now(clock: clock) instant = {
	let tp = rt::timespec { ... };
	let err = match (now_vdso(clock, &tp)) {
	case void =>
		return timespec_to_instant(tp);
	case let err: rt::errno =>
		yield err;
	};
	if (err != rt::ENOSYS) {
		abort("Unexpected error from clock_gettime");
	};
	match (rt::clock_gettime(clock, &tp)) {
	case void =>
		return timespec_to_instant(tp);
	case let err: rt::errno =>
		abort("Unexpected error from clock_gettime");
	};
};
