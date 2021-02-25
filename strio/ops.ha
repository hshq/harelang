use io;
use strings;

// Appends zero or more strings to an [io::stream]. The stream needn't be a
// strio stream, but it's often efficient if it is.
export fn concat(st: *io::stream, strs: str...) (size | io::error) = {
	let n = 0z;
	for (let i = 0z; i < len(strs); i += 1) {
		let q = 0z;
		let buf = strings::to_utf8(strs[i]);
		for (q < len(buf)) {
			let w = io::write(st, buf[q..])?;
			n += w;
			q -= w;
		};
	};
	return n;
};

@test fn concat() void = {
	let st = dynamic();
	defer io::close(st);
	concat(st, "hello");
	concat(st, " ", "world");
	assert(string(st) == "hello world");
};
