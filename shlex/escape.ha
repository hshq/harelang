// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use encoding::utf8;
use io;
use memio;
use strings;

fn is_safe(s: str) bool = {
	const iter = strings::iter(s);
	for (let rn => strings::next(&iter)) {
		switch (rn) {
		case '@', '%', '+', '=', ':', ',', '.', '/', '-' =>
			void;
		case =>
			if (!ascii::isalnum(rn) || ascii::isspace(rn)) {
				return false;
			};
		};
	};
	return true;
};

// Quotes a shell string and writes it to the provided I/O handle.
export fn quote(sink: io::handle, s: str) (size | io::error) = {
	if (len(s) == 0) {
		return io::writeall(sink, strings::toutf8(`''`))?;
	};
	if (is_safe(s)) {
		return io::writeall(sink, strings::toutf8(s))?;
	};

	let z = io::writeall(sink, ['\''])?;

	const iter = strings::iter(s);
	for (let rn => strings::next(&iter)) {
		if (rn == '\'') {
			z += io::writeall(sink, strings::toutf8(`'"'"'`))?;
		} else {
			z += io::writeall(sink, utf8::encoderune(rn))?;
		};
	};

	z += io::writeall(sink, ['\''])?;
	return z;
};

// Quotes a shell string and returns a new string. The caller must free the
// return value.
export fn quotestr(s: str) str = {
	const sink = memio::dynamic();
	quote(&sink, s)!;
	return memio::string(&sink)!;
};
