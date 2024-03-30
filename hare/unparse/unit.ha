// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use hare::ast;
use io;

// Unparses a [[hare::ast::subunit]].
export fn subunit(
	out: io::handle,
	syn: *synfunc,
	s: ast::subunit,
) (size | io::error) = {
	let n = 0z;
	for (let imp &.. s.imports) {
		n += import(out, syn, imp)?;
		n += fmt::fprintln(out)?;
	};
	if (len(s.imports) > 0) {
		n += fmt::fprintln(out)?;
	};
	for (let i = 0z; i < len(s.decls); i += 1) {
		n += decl(out, syn, &s.decls[i])?;
		if (i < len(s.decls) - 1) n += fmt::fprintln(out)?;
		n += fmt::fprintln(out)?;
	};
	return n;
};
