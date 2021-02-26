use encoding::hex;
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
	let hash = hex::encode(ver.hash);
	fmt::println("{}: {}", hash, os::args[1]);
	for (let i = 0z; i < len(ver.inputs); i += 1) {
		let hash = hex::encode(ver.inputs[i].hash);
		defer free(hash);
		fmt::println("\t {} {}", hash, ver.inputs[i].path as str);
	};
};
