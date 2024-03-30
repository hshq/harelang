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
		for (let tag .. tags) {
			n += fmt::fprintf(out, "+{}", tag)?;
		};
	case let tags: []tag =>
		for (let tag .. tags) {
			n += fmt::fprintf(
				out,
				if (tag.include) "+{}" else "-{}",
				tag.name)?;
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
	for (let ha .. srcs.ha) {
		n += fmt::fprintln(out, "  ", ha)?;
	};

	n += fmt::fprintln(out, "assembly sources:")?;
	for (let s .. srcs.s) {
		n += fmt::fprintln(out, "  ", s)?;
	};

	n += fmt::fprintln(out, "object sources:")?;
	for (let o .. srcs.o) {
		n += fmt::fprintln(out, "  ", o)?;
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
	for (let (_, ident) .. mod.deps) {
		n += fmt::fprint(out, "  ")?;
		n += unparse::ident(out, ident)?;
		n += fmt::fprintln(out)?;
	};
	return n;
};
