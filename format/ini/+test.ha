// License: MPL-2.0
// (c) 2021-2022 Alexey Yerin <yyp@disroot.org>
use bufio;
use io;
use strings;

@test fn simple() void = {
	const buf = bufio::fixed(strings::toutf8(
"# This is a comment
[sourcehut.org]
name=Sourcehut
description=The hacker's forge
[harelang.org]
name=Hare
description=The Hare programming language"), io::mode::READ);
	const sc = scan(&buf);
	defer finish(&sc);

	// [sourcehut.org]
	ini_test(&sc, "sourcehut.org", "name", "Sourcehut");
	ini_test(&sc, "sourcehut.org", "description", "The hacker's forge");
	// [harelang.org]
	ini_test(&sc, "harelang.org", "name", "Hare");
	ini_test(&sc, "harelang.org", "description",
		"The Hare programming language");
	assert(next(&sc) is io::EOF);
};

@test fn extended() void = {
	// TODO: expand?
	const buf = bufio::fixed(strings::toutf8(
"# Equal sign in the value
exec=env VARIABLE=value binary

# Unicode
trademark=™
"), io::mode::READ);
	const sc = scan(&buf);
	defer finish(&sc);

	ini_test(&sc, "", "exec", "env VARIABLE=value binary");
	ini_test(&sc, "", "trademark", "™");
	assert(next(&sc) is io::EOF);
};


@test fn invalid() void = {
	// Missing equal sign
	const buf = bufio::fixed(strings::toutf8("novalue\n"), io::mode::READ);
	const sc = scan(&buf);
	defer finish(&sc);

	assert(next(&sc) as error is syntaxerr); // TODO: test line numbering?

	// Unterminated section header
	const buf = bufio::fixed(strings::toutf8("[dangling\n"), io::mode::READ);
	const sc = scan(&buf);
	defer finish(&sc);

	assert(next(&sc) as error is syntaxerr);
};

fn ini_test(
	sc: *scanner,
	section: const str,
	key: const str,
	value: const str,
) void = {
	const ent = next(sc)! as entry;
	assert(ent.0 == section);
	assert(ent.1 == key);
	assert(ent.2 == value);
};
