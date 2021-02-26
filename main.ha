use fmt;
use hare::module;
use os;

export fn main() void = {
	if (len(os::args) == 1) {
		fmt::fatal("Usage: {} <path>", os::args[0]);
	};

	let ctx = module::context_init([]);
	let ver = match (module::scan(&ctx, os::args[1])) {
		ver: module::version => ver,
		err: module::error => fmt::fatal("Error scanning module: {}",
			module::errstr(err)),
	};
	for (let i = 0z; i < len(ver.inputs); i += 1) {
		fmt::println("in: {}\t{}", ver.inputs[i].path as str,
			ver.inputs[i].hash);
	};
};
