use rt;

fn duration_to_timespec(n: duration, ts: *rt::timespec) void = {
	ts.tv_sec = n / SECOND;
	ts.tv_nsec = n % SECOND;
};

fn time_to_timespec(t: time, ts: *rt::timespec) void = {
	ts.tv_sec = t.sec;
	ts.tv_nsec = t.nsec;
};

fn timespec_to_time(ts: rt::timespec) time = time {
	sec = ts.tv_sec,
	nsec = ts.tv_nsec,
};

// Yields the process to the kernel and returns after the requested duration.
export fn sleep(n: duration) void = {
	let in = rt::timespec { ... };
	duration_to_timespec(n, &in);
	let req = &in;

	for (true) {
		let res = rt::timespec { ... };
		match (rt::nanosleep(req, &res)) {
			void => return,
			err: rt::errno => switch (err) {
				rt::EINTR => {
					req = &res;
				},
				* => abort("Unexpected error from nanosleep"),
			},
		};
	};
};

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

	// Time since the system was booted. Increases monotonically and,
	// unlike [MONOTONIC], continues to tick while the system is suspended.
	BOOT = 7,
};

// Returns the current time for a given clock.
export fn now(clock: clock) time = {
	let tp = rt::timespec { ... };
	return match (rt::clock_gettime(clock, &tp)) {
		void => timespec_to_time(tp),
		err: rt::errno => abort("Unexpected error from clock_gettime"),
	};
};
