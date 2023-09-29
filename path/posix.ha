// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use strings;

// These functions have been confined here to POSIX jail. They are
// POSIX-compliant, for their sins, but they do not fit in semantically
// with the other stack-paradigm functions. Hence this POSIX-complaint.
// They are based primarily off of `man 1p basename/dirname`, and secondarily
// off of the examples in `man 3p basename`.

// A POSIX-compliant implementation of dirname. See the POSIX specification
// for more information. Note that this function does *not* normalize the
// input. The return value is either borrowed from the input or statically
// allocated; use [[strings::dup]] to extend its lifetime.
export fn dirname(path: const str) const str = {
	let path = strings::toutf8(path);
	if (len(path) == 0) return ".";

	path = bytes::rtrim(path, SEP);
	if (len(path) == 0) return sepstr;

	match (bytes::rindex(path, SEP)) {
	case void => return ".";
	case let z: size => path = path[..z];
	};
	path = bytes::rtrim(path, SEP);

	if (len(path) == 0) return sepstr;
	return strings::fromutf8_unsafe(path);
};

// A POSIX-compliant implementation of basename. See the POSIX specification
// for more information. Note that this function does *not* normalize the
// input. The return value is either borrowed from the input or statically
// allocated; use [[strings::dup]] to extend its lifetime.
export fn basename(path: const str) const str = {
	let path = strings::toutf8(path);
	if (len(path) == 0) return ".";

	path = bytes::rtrim(path, SEP);
	if (len(path) == 0) return sepstr;

	match (bytes::rindex(path, SEP)) {
	case void => void;
	case let z: size => path = path[z+1..];
	};
	return strings::fromutf8_unsafe(path);
};

@test fn dirname_basename() void = {
	const table = [
		// input           , dirname     , basename
		["usr"             , "."         , "usr" ],
		["usr/"            , "."         , "usr" ],
		[""                , "."         , "."   ],
		["/"               , "/"         , "/"   ],
		["//"              , "/"         , "/"   ], // implementation defined
		["///"             , "/"         , "/"   ],
		["/usr/"           , "/"         , "usr" ],
		["/usr/lib"        , "/usr"      , "lib" ],
		["//usr//lib//"    , "//usr"     , "lib" ],
		["/home//dwc//test", "/home//dwc", "test"],
	];
	for (let i = 0z; i < len(table); i += 1) {
		let input: [MAX]u8 = [0...];
		const input = _local(table[i][0], &input);
		assert(dirname(input) == local(table[i][1]));
		assert(basename(input) == local(table[i][2]));
	};
};
