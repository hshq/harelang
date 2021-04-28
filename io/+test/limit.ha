use errors;

@test fn limit() void = {
	let buf: [15z]u8 = [0...];
	let source_stream = test_stream_open();
	defer close(&source_stream.stream);

	let r_stream = limitreader(&source_stream.stream, 20);
	match (write(r_stream, buf)) {
		errors::unsupported => void,
		* => abort(),
	};
	match (read(r_stream, buf)) {
		n: size => assert(n == 15),
		error => abort(),
	};
	match (read(r_stream, buf)) {
		n: size => assert(n == 5),
		error => abort(),
	};
	close(r_stream);

	let w_stream = limitwriter(&source_stream.stream, 20);
	match (read(w_stream, buf)) {
		errors::unsupported => void,
		* => abort(),
	};
	match (write(w_stream, buf)) {
		n: size => assert(n == 15),
		error => abort(),
	};
	match (write(w_stream, buf)) {
		n: size => assert(n == 5),
		error => abort(),
	};
	close(w_stream);

};
