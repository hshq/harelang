// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fs;
use io;
use os;
use path;
use rt;
use types::c;

// Opens the executing process's binary image.
export fn self() (image | io::error | fs::error) = {
	// 1: sysctl
	let buf: [path::MAX * 2 + 1]u8 = [0...];
	let pathsz = len(buf);
	match (rt::sysctlbyname("kern.proc.pathname",
			&buf[0], &pathsz, null, 0)) {
	case rt::errno => void;
	case void =>
		const file = os::open(c::tostr(&buf[0]: *const c::char)!)?;
		match (open(file)) {
		case let img: image =>
			return img;
		case let err: io::error =>
			return err;
		case errors::invalid =>
			abort("Running program image is not a valid ELF file");
		};
	};

	// 2. procfs (not mounted by default, but better than step 3)
	match (os::open("/proc/curproc/exe")) {
	case let file: io::file =>
		match (open(file)) {
		case let img: image =>
			return img;
		case let err: io::error =>
			return err;
		case errors::invalid =>
			abort("Running program image is not a valid ELF file");
		};
	case => void;
	};

	// 3. Fallback (os::args[0])
	return self_argv();
};
