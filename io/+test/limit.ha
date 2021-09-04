use errors;

@test fn limit() void = {
	let buf: [15z]u8 = [0...];
	let source = teststream_open();

	let rlimit = limitreader(&source, 20);
	match (write(&rlimit, buf)) {
		errors::unsupported => void,
		* => abort(),
	};
	match (read(&rlimit, buf)) {
		n: size => assert(n == 15),
		error => abort(),
	};
	match (read(&rlimit, buf)) {
		n: size => assert(n == 5),
		error => abort(),
	};

	let wlimit = limitwriter(&source, 20);
	match (read(&wlimit, buf)) {
		errors::unsupported => void,
		* => abort(),
	};
	match (write(&wlimit, buf)) {
		n: size => assert(n == 15),
		error => abort(),
	};
	match (write(&wlimit, buf)) {
		n: size => assert(n == 5),
		error => abort(),
	};
};
