// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>

export @symbol("main") fn main() int = {
	const nfail = tests_main();
	return if (nfail > 0) 1 else 0;
};
