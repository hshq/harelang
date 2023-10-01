// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use ascii;
use dirs;
use errors;
use hare::module;
use os;
use strings;

def HAREPATH: str = ".";

fn merge_tags(current: *[]str, new: str) (void | module::error) = {
	let trimmed = strings::ltrim(new, '^');
	if (trimmed != new) {
		strings::freeall(*current);
		*current = [];
	};
	let newtags = module::parse_tags(trimmed)?;
	for (let i = 0z; i < len(newtags); i += 1) :new {
		for (let j = 0z; j < len(current); j += 1) {
			if (newtags[i].name == current[j]) {
				if (!newtags[i].include) {
					free(current[j]);
					static delete(current[j]);
				};
				continue :new;
			};
		};
		if (newtags[i].include) {
			append(current, strings::dup(newtags[i].name));
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

// result must be freed with strings::freeall
fn default_tags() ([]str | error) = {
	let arch = os::machine();
	let platform = ascii::strlower(os::sysname());
	let tags: []str = alloc([strings::dup(arch), platform]);
	return tags;
};
