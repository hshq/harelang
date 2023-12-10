// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use ascii;
use dirs;
use hare::module;
use os;
use strings;

def HAREPATH: str = ".";

fn merge_tags(current: *[]str, new: str) (void | module::error) = {
	let trimmed = strings::ltrim(new, '^');
	if (trimmed != new) {
		free(*current);
		*current = [];
	};
	let newtags = module::parse_tags(trimmed)?;
	defer free(newtags);
	for :new (let i = 0z; i < len(newtags); i += 1) {
		for (let j = 0z; j < len(current); j += 1) {
			if (newtags[i].name == current[j]) {
				if (!newtags[i].include) {
					static delete(current[j]);
				};
				continue :new;
			};
		};
		if (newtags[i].include) {
			append(current, newtags[i].name);
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
