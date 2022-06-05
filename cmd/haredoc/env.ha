// License: GPL-3.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2022 Haelwenn (lanodan) Monnier <contact@hacktivis.me>
use hare::module;
use os::exec;
use os;
use strings;

def PLATFORM: str = "unknown";

fn default_tags() []module::tag = {
	// TODO: Once os::exec can handle pipes, we should read the default tags
	// from $(hare version).
	return alloc([module::tag {
		name = strings::dup(PLATFORM),
		mode = module::tag_mode::INCLUSIVE,
	}, module::tag {
		name = strings::dup(os::machine()),
		mode = module::tag_mode::INCLUSIVE,
	}]);
};

fn addtags(tags: []module::tag, in: str) ([]module::tag | void) = {
	let in = match (module::parsetags(in)) {
	case void =>
		return void;
	case let t: []module::tag =>
		yield t;
	};
	defer free(in);
	append(tags, in...);
	return tags;
};

fn deltags(tags: []module::tag, in: str) ([]module::tag | void) = {
	if (in == "^") {
		module::tags_free(tags);
		return [];
	};
	let in = match (module::parsetags(in)) {
	case void =>
		return void;
	case let t: []module::tag =>
		yield t;
	};
	defer free(in);
	for (let i = 0z; i < len(tags); i += 1) {
		for (let j = 0z; j < len(in); j += 1) {
			if (tags[i].name == in[j].name
					&& tags[i].mode == in[j].mode) {
				free(tags[i].name);
				i -= 1;
			};
		};
	};
	return tags;
};

fn default_harepath() str = {
	return HAREPATH;
};
