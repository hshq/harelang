use io;
use rt;

// An [io::stream] which returns cryptographically random data on reads. Be
// aware, it may return less than you asked for!
export let stream: *io::stream = null: *io::stream;

@init fn init() void = {
	static let s = io::stream {
		name = "<random>",
		...
	};
	// TODO: Globals referencing other globals
	s.reader = &rand_reader;
	stream = &s;
};

@test fn buffer() void = {
	let buf: [4096]u8 = [0...];
	buffer(buf[..]);

	let sum = 0z;
	for (let i = 0z; i < len(buf); i += 1) {
		sum += buf[i];
	};
	let avg = sum / len(buf);
	assert(avg < 0xA0 && avg > 0x60);
};

@test fn reader() void = {
	let buf: [4096]u8 = [0...];
	let test: []u8 = [];
	match (io::read(stream, buf[..])) {
		(io::error | io::EOF) => abort(),
		n: size => test = buf[..n],
	};

	assert(len(test) > 0);

	let sum = 0z;
	for (let i = 0z; i < len(test); i += 1) {
		sum += test[i];
	};
	let avg = sum / len(test);
	assert(avg < 0xA0 && avg > 0x60);
};
