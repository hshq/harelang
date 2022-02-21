// License: MPL-2.0
// (c) 2021-2022 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use errors;

@test fn limit() void = {
	let buf: [15z]u8 = [0...];
	let source = teststream_open();

	let rlimit = limitreader(&source, 20);
	match (write(&rlimit, buf)) {
	case errors::unsupported => void;
	case =>
		abort();
	};
	match (read(&rlimit, buf)) {
	case let n: size =>
		assert(n == 15);
	case error =>
		abort();
	};
	match (read(&rlimit, buf)) {
	case let n: size =>
		assert(n == 5);
	case error =>
		abort();
	};
	assert(read(&rlimit, buf) is EOF);

	let wlimit = limitwriter(&source, 20);
	match (read(&wlimit, buf)) {
	case errors::unsupported => void;
	case =>
		abort();
	};
	match (write(&wlimit, buf)) {
	case let n: size =>
		assert(n == 15);
	case error =>
		abort();
	};
	match (write(&wlimit, buf)) {
	case let n: size =>
		assert(n == 5);
	case error =>
		abort();
	};
	assert(write(&wlimit, buf) as size == 0z);
};
