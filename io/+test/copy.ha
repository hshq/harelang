// License: MPL-2.0
// (c) 2021 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use errors;

fn test_copier_read(s: *stream, buf: []u8) (size | EOF | error) = {
	let stream = s: *teststream;
	if (stream.r == 0) {
		assert(len(buf) > 42);
		stream.nreads += 1;
		stream.r = 42;
		return 42;
	} else {
		return EOF;
	};
};

fn test_copier_open() teststream = {
	let stream = teststream_open();
	stream.reader = &test_copier_read;
	return stream;
};

fn test_copier_copy(a: *stream, b: *stream) (size | error) = {
	assert(a != b);
	assert(a.reader == &test_copier_read && b.reader == &test_copier_read);
	let stream = a: *teststream;
	stream.w = 62893;
	return 1337;
};

fn test_copy_unsupported(a: *stream, b: *stream) (size | error) =
	errors::unsupported;

@test fn copy() void = {
	let a = test_copier_open(), b = test_copier_open();
	match (copy(&b, &a)) {
	case let n: size =>
		assert(n == 42);
		assert(a.r == 42);
		assert(b.w == 42);
	case error =>
		abort();
	};
	close(&a: *stream);
	close(&b: *stream);

	a = test_copier_open();
	b = test_copier_open();
	a.copier = &test_copier_copy;
	b.copier = &test_copier_copy;
	match (copy(&b, &a)) {
	case let n: size =>
		assert(n == 1337);
		assert(b.w == 62893);
	case error =>
		abort();
	};
	close(&a: *stream);
	close(&b: *stream);

	// Fallback
	a = test_copier_open();
	b = test_copier_open();
	a.copier = &test_copy_unsupported;
	b.copier = &test_copy_unsupported;
	match (copy(&b, &a)) {
	case let n: size =>
		assert(n == 42);
		assert(a.r == 42);
		assert(b.w == 42);
	case error =>
		abort();
	};

	// Fallback (+short writes)
	a = test_copier_open();
	b = test_copier_open();
	a.copier = &test_copy_unsupported;
	b.copier = &test_copy_unsupported;
	b.writer = &teststream_write_short;
	match (copy(&b, &a)) {
	case let n: size =>
		assert(n == 42);
		assert(a.r == 42);
		assert(a.nreads == 1);
		assert(b.w == 42);
		assert(b.nwrites > 1);
	case error =>
		abort();
	};
};
