// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use io;
use fmt;
use hare::ast;

// Unparses a [[hare::ast::subunit]].
export fn subunit(out: io::handle, s: ast::subunit) (size | io::error) = {
	let n = 0z;
	for (let i = 0z; i < len(s.imports); i += 1) {
		n += import(out, s.imports[i])?;
		n += fmt::fprintln(out)?;
	};
	if (len(s.imports) > 0) {
		n += fmt::fprintln(out)?;
	};
	for (let i = 0z; i < len(s.decls); i += 1) {
		n += decl(out, s.decls[i])?;
		if (i < len(s.decls) - 1) n += fmt::fprintln(out)?;
		n += fmt::fprintln(out)?;
	};
	return n;
};
