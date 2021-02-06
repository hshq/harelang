fn test_copier_read(s: *stream, buf: []u8) (size | EOF | error) = {
	let stream = s: *test_stream;
	if (stream.n == 0z) {
		assert(len(buf) > 42z);
		stream.n = 42z;
		return 42z;
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
	stream.n = 62893z;
	return 1337z;
};

fn test_copy_unsupported(a: *stream, b: *stream) (size | error) = unsupported;

@test fn copy() void = {
	let a = test_copier_open(), b = test_copier_open();
	match (copy(&b.stream, &a.stream)) {
		n: size => {
			assert(n == 42z);
			assert(a.n == 42z);
			assert(b.n == 42z);
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
			assert(n == 1337z);
			assert(b.n == 62893z);
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
			assert(n == 42z);
			assert(a.n == 42z);
			assert(b.n == 42z);
		},
		error => abort(),
	};
	close(&a: *stream);
	close(&b: *stream);
};
