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
	fmt::printfln("{}: {}", hash, os::args[1]);
	fmt::println(len(ver.inputs), "inputs");
	for (let i = 0z; i < len(ver.inputs); i += 1) {
		let hash = hex::encode(ver.inputs[i].hash);
		defer free(hash);
		fmt::printfln("\t{} {}", hash, ver.inputs[i].path as str);
	};

	fmt::println(len(ver.depends), "dependencies");
	for (let i = 0z; i < len(ver.depends); i += 1) {
		let ident = ver.depends[i];
		fmt::print("\t");
		for (let j = 0z; j < len(ident); j += 1) {
			fmt::printf("{}{}", ident[j],
				if (j + 1 < len(ident)) "::"
				else "\n");
		};
	};
};
