// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use io;
use fmt;

fn newline(out: io::handle, indent: size) (size | io::error) = {
	let n = 0z;
	n += fmt::fprint(out, "\n")?;
	for (let i = 0z; i < indent; i += 1) {
		n += fmt::fprint(out, "\t")?;
	};
	return n;
};
