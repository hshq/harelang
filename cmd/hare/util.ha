// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use ascii;
use dirs;
use hare::module;
use os;
use strings;

fn merge_tags(current: *[]str, new: str) (void | module::error) = {
	let trimmed = strings::trimprefix(new, "^");
	if (trimmed != new) {
		free(*current);
		*current = [];
	};
	let newtags = module::parse_tags(trimmed)?;
	defer free(newtags);
	for :new (let newtag .. newtags) {
		for (let j = 0z; j < len(current); j += 1) {
			if (newtag.name == current[j]) {
				if (!newtag.include) {
					static delete(current[j]);
				};
				continue :new;
			};
		};
		if (newtag.include) {
			append(current, newtag.name);
		};
	};
};

fn harepath() str = os::tryenv("HAREPATH", HAREPATH);

fn harecache() str = {
	match (os::getenv("HARECACHE")) {
	case let s: str =>
		return s;
	case void =>
		return dirs::cache("hare");
	};
};

// contents of slice shouldn't be freed
fn default_tags() []str = {
	let arch = os::arch_name(os::architecture());
	static let platform: [7]u8 = [0...];
	let platform = ascii::strlower_buf(os::sysname(), platform[..0]);
	let tags: []str = alloc([arch, platform]);
	return tags;
};
