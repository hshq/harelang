// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use strings;

// Converts a symbol name to a Hare identifier. The return value is statically
// allocated.
export fn symname_to_ident(name: str) const str = {
	static let buf: [MAX_SYMNAME * 2]u8 = [0...];
	let slice = buf[..0];

	const iter = strings::iter(name);
	for (const rn => strings::next(&iter)) {
		if (rn == '.') {
			static append(slice, ':');
			static append(slice, ':');
		} else {
			static append(slice, utf8::encoderune(rn)...);
		};
	};

	return strings::fromutf8(slice)!;
};
