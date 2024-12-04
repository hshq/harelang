// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use io;

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
