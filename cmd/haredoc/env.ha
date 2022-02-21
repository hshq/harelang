use hare::module;
use os::exec;
use os;
use strings;

fn default_tags() []module::tag = {
	// TODO: Once os::exec can handle pipes, we should read the default tags
	// from $(hare version).
	return alloc([module::tag {
		name = strings::dup("linux"),
		mode = module::tag_mode::INCLUSIVE,
	}, module::tag {
		name = strings::dup(os::machine()),
		mode = module::tag_mode::INCLUSIVE,
	}]);
};

fn default_harepath() str = {
	return HAREPATH;
};
