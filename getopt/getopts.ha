// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use io;
use os;
use strings;

// The result of parsing the set of command line arguments, including any
// options specified and the list of non-option arguments. If a subcommand
// is present in the help passed to [[parse]], then there will be no args.
export type command = struct {
	opts: [](rune, str),
	subcmd: (void | (str, *command)),
	args: []str,
	help: []help,
};

// Help text providing a short, one-line summary of the command; or providing
// the name of an argument.
export type cmd_help = str;

// Help text for a flag, formatted as "-a: help text".
export type flag_help = (rune, str);

// Help text for a parameter, formatted as "-a param: help text" where "param"
// is the first string and "help text" is the second string.
export type parameter_help = (rune, str, str);

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

export type requires_arg = rune;
export type unknown_option = rune;
export type unknown_subcmd = str;
export type error = !(
	str, []help,
	(requires_arg | unknown_option | unknown_subcmd),
);

// Converts a parsing error into a human-friendly string. The result may be
// statically allocated.
export fn strerror(err: error) str = {
	static let buf: [1024]u8 = [0...];
	match (err.2) {
	case let r: requires_arg =>
		return fmt::bsprintf(buf, "{}: option -{} requires an argument",
			err.0, r: rune);
	case let r: unknown_option =>
		return fmt::bsprintf(buf, "{}: unrecognized option: -{}",
			err.0, r: rune);
	case let s: unknown_subcmd =>
		return fmt::bsprintf(buf, "{}: unrecognized subcommand: {}",
			err.0, s: str);
	};
};

// A wrapper for [[tryparse]] in which if an error occurs, details are printed
// to [[os::stderr]] (as in [[printusage]]), and [[os::exit]] is called with
// [[os::status::FAILURE]].
export fn parse(args: []str, help: help...) command = {
	match (tryparse(args, help...)) {
	case let c: command => return c;
	case let e: error =>
		fmt::errorln(strerror(e))!;
		if (e.2 is unknown_subcmd) {
			printsubcmds(os::stderr, e.1)!;
			fmt::errorln()!;
		};
		printusage(os::stderr, e.0, e.1)!;
		os::exit(os::status::FAILURE);
	};
};

// Parses command line arguments and returns a [[command]], or an [[error]]
// if an error occurs. The argument list must include the command name as
// the first item; [[os::args]] fulfills this criteria.
export fn tryparse(args: []str, help: help...) (command | error) = {
	let opts: [](rune, str) = [];
	let i = 1z;
	for :arg (i < len(args); i += 1) {
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
		for (let r => strings::next(&iter)) {
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
							return (args[0], help, r: requires_arg): error;
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
				os::exit(os::status::SUCCESS);
			};
			free(opts);
			return (args[0], help, r: unknown_option): error;
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
			return (args[0], help, args[i]: unknown_subcmd): error;
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
	free(cmd.opts);
	match (cmd.subcmd) {
	case void => void;
	case let s: (str, *command) =>
		finish(s.1);
		free(s.1);
	};
};

// Prints command usage to the provided stream.
export fn printusage(
	out: io::handle,
	name: str,
	help: []help
) (void | io::error) = {
	let h = contains_h(help);
	let z = _printusage(io::empty, name, false, h, help)?;
	_printusage(out, name, if (z > 72) true else false, h, help)?;
};

fn _printusage(
	out: io::handle,
	name: str,
	indent: bool,
	contains_h: bool,
	help: []help,
) (size | io::error) = {
	let z = fmt::fprint(out, "Usage:", name)?;

	let started_flags = false;
	if (!contains_h) {
		z += fmt::fprint(out, " [-h")?;
		started_flags = true;
	};
	for (let h .. help) {
		match (h) {
		case let h: flag_help =>
			if (!started_flags) {
				z += fmt::fprint(out, " [-")?;
				started_flags = true;
			};
			z += fmt::fprint(out, h.0)?;
		case => void;
		};
	};
	if (started_flags) {
		z += fmt::fprint(out, "]")?;
	};

	for (let h .. help) {
		match (h) {
		case let h: parameter_help =>
			if (indent) {
				z += fmt::fprintf(out, "\n\t")?;
			};
			z += fmt::fprintf(out, " [-{} <{}>]", h.0, h.1)?;
		case => void;
		};
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

fn contains_h(help: []help) bool = {
	for (let h .. help) {
		const r = match (h) {
		case let h: flag_help => yield h.0;
		case let h: parameter_help => yield h.0;
		case => continue;
		};
		if (r == 'h') {
			return true;
		};
	};
	return false;
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

	let contains_h = contains_h(help);
	let z = _printusage(io::empty, name, false, contains_h, help)?;
	_printusage(out, name, if (z > 72) true else false, contains_h, help)?;

	fmt::fprint(out, "\n")?;
	if (!contains_h) {
		fmt::fprintln(out, "-h: print this help text")?;
	};
	for (let h .. help) {
		match (h) {
		case let f: flag_help =>
			fmt::fprintfln(out, "-{}: {}", f.0, f.1)?;
		case let p: parameter_help =>
			fmt::fprintfln(out, "-{} <{}>: {}", p.0, p.1, p.2)?;
		case => void;
		};
	};

	printsubcmds(out, help)?;
};

fn printsubcmds(out: io::handle, help: []help) (void | io::error) = {
	let first = true;
	for (let h .. help) {
		match (h) {
		case let s: subcmd_help =>
			// Only print this if there are subcommands to show
			if (first) {
				fmt::fprintln(out, "\nSubcommands:")?;
				first = false;
			};
			if (len(s.1) == 0 || !(s.1[0] is cmd_help)) {
				fmt::fprintfln(out, "  {}", s.0)?;
			} else {
				fmt::fprintfln(out, "  {}: {}", s.0,
					s.1[0] as cmd_help: str)?;
			};
		case => void;
		};
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
