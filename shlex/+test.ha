// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use memio;
use strings;

@test fn split() void = {
	const s = split(`hello\ world`)!;
	defer strings::freeall(s);
	assert(len(s) == 1);
	assert(s[0] == "hello world");

	const s = split(`'hello\ world'`)!;
	defer strings::freeall(s);
	assert(len(s) == 1);
	assert(s[0] == `hello\ world`);

	const s = split(`"hello\\world"`)!;
	defer strings::freeall(s);
	assert(len(s) == 1);
	assert(s[0] == `hello\world`);

	const s = split(`"hello "'"'"world"'"'`)!;
	defer strings::freeall(s);
	assert(len(s) == 1);
	assert(s[0] == `hello "world"`);

	const s = split("hello '' world")!;
	defer strings::freeall(s);
	assert(len(s) == 3);
	assert(s[0] == "hello");
	assert(s[1] == "");
	assert(s[2] == "world");

	const s = split("Empty ''")!;
	defer strings::freeall(s);
	assert(len(s) == 2);
	assert(s[0] == "Empty");
	assert(s[1] == "");

	const s = split("   Leading spaces")!;
	defer strings::freeall(s);
	assert(len(s) == 2);
	assert(s[0] == "Leading");
	assert(s[1] == "spaces");

	const s = split(`with\ backslashes 'single quoted' "double quoted"`)!;
	defer strings::freeall(s);
	assert(len(s) == 3);
	assert(s[0] == "with backslashes");
	assert(s[1] == "single quoted");
	assert(s[2] == "double quoted");

	const s = split("'multiple spaces'      42")!;
	defer strings::freeall(s);
	assert(len(s) == 2);
	assert(s[0] == "multiple spaces");
	assert(s[1] == "42");

	// Invalid
	assert(split(`"dangling double quote`) is syntaxerr);
	assert(split("'dangling single quote") is syntaxerr);
	assert(split(`unterminated\ backslash \`) is syntaxerr);
};

fn testquote(sink: *memio::stream, s: str, expected: str) void = {
	assert(quote(sink, s)! == len(expected));
	assert(memio::string(sink)! == expected);
	memio::reset(sink);
};

@test fn quote() void = {
	const sink = memio::dynamic();
	defer io::close(&sink)!;
	testquote(&sink, `hello`, `hello`);
	testquote(&sink, `hello world`, `'hello world'`);
	testquote(&sink, `'hello' "world"`, `''"'"'hello'"'"' "world"'`);
	testquote(&sink, `hello\world`, `'hello\world'`);
};
