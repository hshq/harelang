// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use hare::unparse;
use io;
use time::chrono;
use time::date;

// Formats a set of tags to an [[io::handle]] in "+tag1-tag2" format.
export fn format_tags(
	out: io::handle,
	tags: ([]str | []tag),
) (size | io::error) = {
	let n = 0z;
	match (tags) {
	case let tags: []str =>
		for (let i = 0z; i < len(tags); i += 1) {
			n += fmt::fprintf(out, "+{}", tags[i])?;
		};
	case let tags: []tag =>
		for (let i = 0z; i < len(tags); i += 1) {
			n += fmt::fprintf(
				out,
				if (tags[i].include) "+{}" else "-{}",
				tags[i].name)?;
		};
	};
	return n;
};

// Formats a [[srcset]] to an [[io::handle]].
export fn format_srcset(out: io::handle, srcs: *srcset) (size | io::error) = {
	let n = 0z;
	n += fmt::fprint(out, "relevant tags: ")?;
	n += format_tags(out, srcs.seentags)?;
	n += fmt::fprintln(out)?;
	const dt = date::from_instant(chrono::LOCAL, srcs.mtime);
	n += date::format(out, "last change to source list: %F %T\n", &dt)?;
	n += fmt::fprintln(out, "hare sources:")?;
	for (let i = 0z; i < len(srcs.ha); i += 1) {
		n += fmt::fprintln(out, "  ", srcs.ha[i])?;
	};
	n += fmt::fprintln(out, "assembly sources:")?;
	for (let i = 0z; i < len(srcs.s); i += 1) {
		n += fmt::fprintln(out, "  ", srcs.s[i])?;
	};
	n += fmt::fprintln(out, "object sources:")?;
	for (let i = 0z; i < len(srcs.o); i += 1) {
		n += fmt::fprintln(out, "  ", srcs.o[i])?;
	};
	return n;
};

// Formats a [[module]] to an [[io::handle]].
export fn format(out: io::handle, mod: *module) (size | io::error) = {
	let n = 0z;
	n += fmt::fprintln(out, "module:", mod.name)?;
	n += fmt::fprintln(out, "path:", mod.path)?;
	n += format_srcset(out, &mod.srcs)?;
	n += fmt::fprintln(out, "dependencies:")?;
	for (let i = 0z; i < len(mod.deps); i += 1) {
		n += fmt::fprint(out, "  ")?;
		n += unparse::ident(out, mod.deps[i].1)?;
		n += fmt::fprintln(out)?;
	};
	return n;
};
