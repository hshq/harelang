@test fn limit() void = {
	let buf: [15z]u8 = [0u8...];
	let source_stream = test_stream_open();
	defer close(&source_stream.stream);

	let r_stream = limit_reader(&source_stream.stream, 20z);
	match (write(r_stream, buf)) {
		unsupported => void,
		* => abort(),
	};
	match (read(r_stream, buf)) {
		n: size => assert(n == 15z),
		error => abort(),
	};
	match (read(r_stream, buf)) {
		n: size => assert(n == 5z),
		error => abort(),
	};
	close(r_stream);

	let w_stream = limit_writer(&source_stream.stream, 20z);
	match (read(w_stream, buf)) {
		unsupported => void,
		* => abort(),
	};
	match (write(w_stream, buf)) {
		n: size => assert(n == 15z),
		error => abort(),
	};
	match (write(w_stream, buf)) {
		n: size => assert(n == 5z),
		error => abort(),
	};
	close(w_stream);

};
