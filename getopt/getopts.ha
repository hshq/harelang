// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Byron Torres <b@torresjrjr.com>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2021 Jonathan Halmen <slowjo@halmen.xyz>
// (c) 2021 Thomas Bracht Laumann Jespersen <t@laumann.xyz>
use fmt;
use io;
use os;
use strings;

// A flag which does not take a parameter, e.g. "-a".
export type flag = rune;

// An option with an included parameter, e.g. "-a foo".
export type parameter = str;

// A command line option.
export type option = (flag, parameter);

// The result of parsing the set of command line arguments, including any
// options specified and the list of non-option arguments.
export type command = struct {
	opts: []option,
	subcmd: (void | (str, *command)),
	args: []str,
	help: []help,
};

// Help text providing a short, one-line summary of the command; or providing
// the name of an argument.
export type cmd_help = str;

// Help text for a flag, formatted as "-a: help text".
export type flag_help = (flag, str);

// Help text for a parameter, formatted as "-a param: help text" where "param"
// is the first string and "help text" is the second string.
export type parameter_help = (flag, str, str);

// Definition of a named subcommand.
export type subcmd_help = (str, []help);

// Help text for a command or option. [[cmd_help]], [[flag_help]], and
// [[parameter_help]] compose such that the following []help:
//
// 	[
// 		"foo bars in order",
// 		('a', "a help text"),
// 		('b', "b help text"),
// 		('c', "cflag", "c help text"),
// 		('d', "dflag", "d help text"),
// 		"files...",
// 	]
//
// will produce this help text:
//
// 	foo: foo bars in order
//
// 	Usage: foo [-ab] [-c <cflag>] [-d <dflag>] files...
//
// 	-a: a help text
// 	-b: b help text
// 	-c <cflag>: c help text
// 	-d <dflag>: d help text
export type help = (cmd_help | flag_help | parameter_help | subcmd_help);

export type requires_arg = !rune;
export type unknown_option = !rune;
export type unknown_subcmd = !str;
export type error = !(requires_arg | unknown_option | unknown_subcmd);

// A wrapper for [[tryparse]] in which if an error occurs, details are printed
// to [[os::stderr]] and [[os::exit]] is called with a nonzero exit status.
export fn parse(args: []str, help: help...) command = {
	const cmd = args[0];
	match (tryparse(args, help...)) {
	case let c: command => return c;
	case let r: requires_arg =>
		fmt::errorfln("{}: option -{} requires an argument", cmd, r: rune)!;
	case let r: unknown_option =>
		fmt::errorfln("{}: unrecognized option: -{}", cmd, r: rune)!;
	case let s: unknown_subcmd =>
		fmt::errorfln("{}: unrecognized subcommand: {}", cmd, s: str)!;
		printsubcmds(os::stderr, help)!;
	};
	printusage(os::stderr, args[0], help)!;
	os::exit(1);
};

// Parses command line arguments and returns a [[command]], or an [[error]]
// if an error occurs. The argument list must include the command name as
// the first item; [[os::args]] fulfills this criteria.
export fn tryparse(args: []str, help: help...) (command | ...error) = {
	let opts: []option = [];
	let i = 1z;
	for (i < len(args); i += 1) :arg {
		const arg = args[i];
		if (len(arg) == 0 || arg == "-"
				|| !strings::hasprefix(arg, "-")) {
			break;
		};
		if (arg == "--") {
			i += 1;
			break;
		};

		let iter = strings::iter(arg);
		assert(strings::next(&iter) as rune == '-');
		for (true) match (strings::next(&iter)) {
		case void => break;
		case let r: rune =>
			let found = false;
			for (let j = 0z; j < len(help); j += 1) match (help[j]) {
			case let f: flag_help =>
				if (r == f.0) {
					append(opts, (r, ""));
					found = true;
					break;
				};
			case let p: parameter_help =>
				if (r == p.0) {
					let value = strings::iterstr(&iter);
					if (len(value) == 0) {
						if (i == len(args) - 1) {
							free(opts);
							return r: requires_arg;
						};
						i += 1;
						append(opts, (r, args[i]));
					} else {
						append(opts, (r, value));
					};
					continue :arg;
				};
			case =>
				continue;
			};
			if (found) continue;
			if (r =='h') {
				printhelp(os::stderr, args[0], help)!;
				os::exit(0);
			};
			free(opts);
			return r: unknown_option;
		};
	};
	let subcmd: (void | (str, *command)) = void;
	if (i < len(args)) {
		let expects_subcmd = false;
		for (let j = 0z; j < len(help); j += 1) match (help[j]) {
		case let s: subcmd_help =>
			expects_subcmd = true;
			if (s.0 == args[i]) match (tryparse(args[i..], s.1...)) {
			case let c: command =>
				subcmd = (s.0, alloc(c));
			case let e: error =>
				free(opts);
				return e;
			};
		case => continue;
		};
		if (expects_subcmd && subcmd is void) {
			free(opts);
			return args[i]: unknown_subcmd;
		};
	};
	return command {
		opts = opts,
		subcmd = subcmd,
		args = if (subcmd is void) args[i..] else [],
		help = help,
	};
};

// Frees resources associated with the return value of [[parse]].
export fn finish(cmd: *command) void = {
	if (cmd == null) return;
	free(cmd.opts);
	match (cmd.subcmd) {
	case void => void;
	case let s: (str, *command) =>
		finish(s.1);
		free(s.1);
	};
};

fn _printusage(
	out: io::handle,
	name: str,
	indent: bool,
	help: []help,
) (size | io::error) = {
	let z = fmt::fprint(out, "Usage:", name)?;

	let started_flags = false;
	for (let i = 0z; i < len(help); i += 1) if (help[i] is flag_help) {
		if (!started_flags) {
			z += fmt::fprint(out, " [-")?;
			started_flags = true;
		};
		const help = help[i] as flag_help;
		z += fmt::fprint(out, help.0: rune)?;
	};
	if (started_flags) {
		z += fmt::fprint(out, "]")?;
	};

	for (let i = 0z; i < len(help); i += 1) if (help[i] is parameter_help) {
		const help = help[i] as parameter_help;
		if (indent) {
			z += fmt::fprintf(out, "\n\t")?;
		};
		z += fmt::fprintf(out, " [-{} <{}>]", help.0: rune, help.1)?;
	};
	let first_arg = true;
	for (let i = 1z; i < len(help); i += 1) if (help[i] is cmd_help) {
		if (first_arg) {
			if (indent) {
				z += fmt::fprintf(out, "\n\t")?;
			};
			first_arg = false;
		};
		z += fmt::fprintf(out, " {}", help[i] as cmd_help: str)?;
	};

	return z + fmt::fprint(out, "\n")?;
};

// Prints command usage to the provided stream.
export fn printusage(
	out: io::handle,
	name: str,
	help: []help
) (void | io::error) = {
	let z = _printusage(io::empty, name, false, help)?;
	_printusage(out, name, if (z > 72) true else false, help)?;
};

// Prints command help to the provided stream.
export fn printhelp(
	out: io::handle,
	name: str,
	help: []help
) (void | io::error) = {
	if (len(help) == 0) {
		return;
	};

	if (help[0] is cmd_help) {
		fmt::fprintfln(out, "{}: {}\n", name, help[0] as cmd_help: str)?;
	};

	printusage(out, name, help)?;

	for (let i = 0z; i < len(help); i += 1) match (help[i]) {
	case (flag_help | parameter_help) =>
		// Only print this if there are flags to show
		fmt::fprint(out, "\n")?;
		break;
	case => void;
	};

	for (let i = 0z; i < len(help); i += 1) match (help[i]) {
	case let f: flag_help =>
		fmt::fprintfln(out, "-{}: {}", f.0: rune, f.1)?;
	case let p: parameter_help =>
		fmt::fprintfln(out, "-{} <{}>: {}", p.0: rune, p.1, p.2)?;
	case => void;
	};

	printsubcmds(out, help)?;
};

fn printsubcmds(out: io::handle, help: []help) (void | io::error) = {
	let first_subcmd = true;
	for (let i = 0z; i < len(help); i += 1) match (help[i]) {
	case let s: subcmd_help =>
		// Only print this if there are subcommands to show
		if (first_subcmd) {
			fmt::fprintln(out, "\nSubcommands:")?;
			first_subcmd = false;
		};
		if (len(s.1) == 0 || !(s.1[0] is cmd_help)) {
			fmt::fprintfln(out, "  {}", s.0)?;
		} else {
			fmt::fprintfln(out, "  {}: {}", s.0, s.1[0] as cmd_help: str)?;
		};
	case => void;
	};
};

@test fn parse() void = {
	let args: []str = ["cat", "-v", "a.out"];
	let cat = parse(args,
		"concatenate files",
		('v', "cause Rob Pike to make a USENIX presentation"),
		"files...",
	);
	defer finish(&cat);
	assert(len(cat.args) == 1 && cat.args[0] == "a.out");
	assert(len(cat.opts) == 1 && cat.opts[0].0 == 'v' && cat.opts[0].1 == "");

	args = ["ls", "-Fahs", "--", "-j"];
	let ls = parse(args,
		"list files",
		('F', "Do some stuff"),
		('h', "Do some other stuff"),
		('s', "Do a third type of stuff"),
		('a', "Do a fourth type of stuff"),
		"files...",
	);
	defer finish(&ls);
	assert(len(ls.args) == 1 && ls.args[0] == "-j");
	assert(len(ls.opts) == 4);
	assert(ls.opts[0].0 == 'F' && ls.opts[0].1 == "");
	assert(ls.opts[1].0 == 'a' && ls.opts[1].1 == "");
	assert(ls.opts[2].0 == 'h' && ls.opts[2].1 == "");
	assert(ls.opts[3].0 == 's' && ls.opts[3].1 == "");

	args = ["sed", "-e", "s/C++//g", "-f/tmp/turing.sed", "-"];
	let sed = parse(args,
		"edit streams",
		('e', "script", "Add the editing commands specified by the "
			"script option to the end of the script of editing "
			"commands"),
		('f', "script_file", "Add the editing commands in the file "
			"script_file to the end of the script of editing "
			"commands"),
		"files...",
	);
	defer finish(&sed);
	assert(len(sed.args) == 1 && sed.args[0] == "-");
	assert(len(sed.opts) == 2);
	assert(sed.opts[0].0 == 'e' && sed.opts[0].1 == "s/C++//g");
	assert(sed.opts[1].0 == 'f' && sed.opts[1].1 == "/tmp/turing.sed");
};
