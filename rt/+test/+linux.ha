// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>

let start: timespec = timespec { ... };

fn time_start() void = {
	clock_gettime(CLOCK_MONOTONIC, &start) as void;
};

// Returns elapsed time as (seconds, milliseconds)
fn time_stop() (size, size) = {
	let end: timespec = timespec { ... };
	clock_gettime(CLOCK_MONOTONIC, &end) as void;
	let sec_diff = end.tv_sec - start.tv_sec;
	let nsec_diff = end.tv_nsec - start.tv_nsec;
	if (nsec_diff < 0) {
		nsec_diff += 1000000000;
		sec_diff -= 1;
	};
	return (sec_diff: size, nsec_diff: size / 1000000z);
};
