// License: GPL-3.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2022 Haelwenn (lanodan) Monnier <contact@hacktivis.me>
use bufio;
use fmt;
use hare::module;
use io;
use os::exec;
use os;
use strings;

def PLATFORM: str = "unknown";

fn default_tags() ([]module::tag | error) = {
	let cmd = match (exec::cmd("hare", "version", "-v")) {
	case let cmd: exec::command =>
		yield cmd;
	case exec::nocmd =>
		let platform = strings::dup(PLATFORM);
		let machine = strings::dup(os::machine());
		fmt::errorln("Couldn't find hare binary in PATH")?;
		fmt::errorfln("Build tags defaulting to +{}+{}",
			platform, machine)?;

		return alloc([module::tag {
			name = platform,
			mode = module::tag_mode::INCLUSIVE,
		}, module::tag {
			name = machine,
			mode = module::tag_mode::INCLUSIVE,
		}]);
	case let err: exec::error =>
		return err;
	};

	let pipe = exec::pipe();
	exec::addfile(&cmd, os::stdout_file, pipe.1);
	let proc = exec::start(&cmd)?;
	io::close(pipe.1)?;

	let tags: []module::tag = [];
	for (true) match (bufio::scanline(pipe.0)?) {
	case let b: []u8 =>
		defer free(b);
		const (k, v) = strings::cut(strings::fromutf8(b)!, "\t");
		if (k == "Build tags") {
			tags = module::parsetags(v) as []module::tag;
			break;
		};
	case io::EOF =>
		// process exited with failure; handled below
		break;
	};

	io::close(pipe.0)?;
	let status = exec::wait(&proc)?;
	match (exec::check(&status)) {
	case void =>
		assert(len(tags) > 0);
	case let status: !exec::exit_status =>
		fmt::fatal("Error: hare:", exec::exitstr(status));
	};
	return tags;
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
