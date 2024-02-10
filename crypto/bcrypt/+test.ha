// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use strings;

@test fn bcrypt() void = {
	const pass = strings::toutf8("hare is cool");
	const hash = generate(pass, DEFAULT_COST);
	defer free(hash);
	assert(compare(hash, pass)!);
	const notpass = strings::toutf8("hare is lame");
	assert(!compare(hash, notpass)!);
};

@test fn hash() void = {
	const pass = strings::toutf8("allmine");
	const salt = strings::toutf8("XajjQvNhvvRt5GSeFk1xFe");
	const expect = "$2a$10$XajjQvNhvvRt5GSeFk1xFeyqRrsxkhBkUiQeg0dt.wU1qD4aFDcga";

	const hash = strings::fromutf8(bcrypt(pass, salt, 10)!)!;
	defer free(hash);
	assert(strings::hassuffix(expect, hash));
};
