use ascii;
use bufio;
use fmt;
use getopt;
use os;
use strings;
use unix::tty;

fn version(name: str, cmd: *getopt::command) (void | error) = {
	let verbose = false;
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		const opt = cmd.opts[i];
		switch (opt.0) {
		case 'v' =>
			verbose = true;
		case => abort();
		};
	};

	fmt::printfln("hare {}", VERSION)!;
	if (!verbose) {
		return;
	};

	let build_arch = get_arch(os::machine())?;
	let build_platform = ascii::strlower(os::sysname());

	if (!tty::isatty(os::stdout_file)) {
		fmt::printfln("build tags\t+{}+{}\nHAREPATH\t{}",
			build_arch.name, build_platform, harepath())?;
		return;
	};

	fmt::printfln("build tags:\n\t+{}\n\t+{}\nHAREPATH{}:",
		build_arch.name, build_platform,
		if (os::getenv("HAREPATH") is str) " (from environment)" else "")?;

	let tok = strings::tokenize(harepath(), ":");
	for (true) match (strings::next_token(&tok)) {
	case void =>
		break;
	case let s: str =>
		fmt::printfln("\t{}", s)?;
	};
};
