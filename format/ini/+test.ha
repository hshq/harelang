// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use memio;
use strings;

@test fn simple() void = {
	const buf = memio::fixed(strings::toutf8(
"# This is a comment
[sourcehut.org]
name=Sourcehut
description=The hacker's forge
[harelang.org]
name=Hare
description=The Hare programming language"));
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
	const buf = memio::fixed(strings::toutf8(
"# Equal sign in the value
exec=env VARIABLE=value binary

# Unicode
trademark=™
"));
	const sc = scan(&buf);
	defer finish(&sc);

	ini_test(&sc, "", "exec", "env VARIABLE=value binary");
	ini_test(&sc, "", "trademark", "™");
	assert(next(&sc) is io::EOF);
};


@test fn invalid() void = {
	// Missing equal sign
	const buf = memio::fixed(strings::toutf8("novalue\n"));
	const sc = scan(&buf);
	defer finish(&sc);

	assert(next(&sc) as error as syntaxerr == 1);

	// Unterminated section header
	const buf = memio::fixed(strings::toutf8("[dangling\n"));
	const sc = scan(&buf);
	defer finish(&sc);

	assert(next(&sc) as error as syntaxerr == 1);

	// Line numbering and recovery
	const buf = memio::fixed(strings::toutf8(
"[a]
b=c
d=e
[f]
g=h

i

j=k
"));
	const sc = scan(&buf);
	defer finish(&sc);

	ini_test(&sc, "a", "b", "c");
	ini_test(&sc, "a", "d", "e");
	ini_test(&sc, "f", "g", "h");
	assert(next(&sc) as error as syntaxerr == 7);
	ini_test(&sc, "f", "j", "k");
	assert(next(&sc) is io::EOF);
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
