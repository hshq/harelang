use rt;

fn duration_to_timespec(n: duration, ts: *rt::timespec) void = {
	ts.tv_sec = n / SECOND;
	ts.tv_nsec = n % SECOND;
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
