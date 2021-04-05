use errors;

fn test_copier_read(s: *stream, buf: []u8) (size | EOF | error) = {
	let stream = s: *test_stream;
	if (stream.r == 0) {
		assert(len(buf) > 42);
		stream.nreads += 1;
		stream.r = 42;
		return 42;
	} else {
		return EOF;
	};
};

fn test_copier_open() test_stream = {
	let stream = test_stream_open();
	stream.stream.reader = &test_copier_read;
	return stream;
};

fn test_copier_copy(a: *stream, b: *stream) (size | error) = {
	assert(a != b);
	assert(a.reader == &test_copier_read && b.reader == &test_copier_read);
	let stream = a: *test_stream;
	stream.w = 62893;
	return 1337;
};

fn test_copy_unsupported(a: *stream, b: *stream) (size | error) =
	errors::unsupported;

fn io::println(msg: str) void;
fn strconv::ztos(z: size) str;

@test fn copy() void = {
	let a = test_copier_open(), b = test_copier_open();
	match (copy(&b.stream, &a.stream)) {
		n: size => {
			assert(n == 42);
			assert(a.r == 42);
			assert(b.w == 42);
		},
		error => abort(),
	};
	close(&a: *stream);
	close(&b: *stream);

	a = test_copier_open();
	b = test_copier_open();
	a.stream.copier = &test_copier_copy;
	b.stream.copier = &test_copier_copy;
	match (copy(&b.stream, &a.stream)) {
		n: size => {
			assert(n == 1337);
			assert(b.w == 62893);
		},
		error => abort(),
	};
	close(&a: *stream);
	close(&b: *stream);

	// Fallback
	a = test_copier_open();
	b = test_copier_open();
	a.stream.copier = &test_copy_unsupported;
	b.stream.copier = &test_copy_unsupported;
	match (copy(&b.stream, &a.stream)) {
		n: size => {
			assert(n == 42);
			assert(a.r == 42);
			assert(b.w == 42);
		},
		error => abort(),
	};
	close(&a: *stream);
	close(&b: *stream);

	// Fallback (+short writes)
	a = test_copier_open();
	b = test_copier_open();
	a.stream.copier = &test_copy_unsupported;
	b.stream.copier = &test_copy_unsupported;
	b.stream.writer = &test_stream_write_short;
	match (copy(&b.stream, &a.stream)) {
		n: size => {
			assert(n == 42);
			assert(a.r == 42);
			assert(a.nreads == 1);
			assert(b.w == 42);
			assert(b.nwrites > 1);
		},
		error => abort(),
	};
	close(&a: *stream);
	close(&b: *stream);
};
