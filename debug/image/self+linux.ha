// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fs;
use io;
use os;

// Opens the executing process's binary image.
export fn self() (image | io::error | fs::error) = {
	const file = match (os::open("/proc/self/exe")) {
	case let file: io::file =>
		yield file;
	case =>
		// procfs may not be available, try fallback
		return self_argv();
	};

	match (open(file)) {
	case let img: image =>
		return img;
	case let err: io::error =>
		return err;
	case errors::invalid =>
		abort("Running program image is not a valid ELF file");
	};
};
