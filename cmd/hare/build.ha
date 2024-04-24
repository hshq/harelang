// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use bufio;
use cmd::hare::build;
use errors;
use fmt;
use fs;
use getopt;
use hare::ast;
use hare::lex;
use hare::module;
use hare::parse;
use io;
use memio;
use os;
use os::exec;
use path;
use strconv;
use strings;
use unix::tty;

fn build(name: str, cmd: *getopt::command) (void | error) = {
	let arch = get_arch(os::arch_name(os::architecture()))!;
	let output = "";
	let ctx = build::context {
		ctx = module::context {
			harepath = harepath(),
			harecache = harecache(),
			tags = default_tags(),
		},
		goal = build::stage::BIN,
		jobs = match (os::cpucount()) {
		case errors::error =>
			yield 1z;
		case let ncpu: size =>
			yield ncpu;
		},
		version = build::get_version(os::tryenv("HAREC", "harec"))?,
		arch = arch,
		platform = build::get_platform(os::sysname())?,
		...
	};
	defer build::ctx_finish(&ctx);

	if (name == "test") {
		ctx.test = true;
		ctx.submods = len(cmd.args) == 0;
		merge_tags(&ctx.ctx.tags, "+test")?;
	};

	if (!tty::isatty(os::stderr_file)) {
		ctx.mode = build::output::SILENT;
	};

	for (let opt .. cmd.opts) {
		switch (opt.0) {
		case 'a' =>
			arch = get_arch(opt.1)?;
			ctx.arch = arch;
		case 'D' =>
			let buf = memio::fixed(strings::toutf8(opt.1));
			let sc = bufio::newscanner(&buf, len(opt.1));
			defer bufio::finish(&sc);
			let lexer = lex::init(&sc, "<-D argument>");
			append(ctx.defines, parse::define(&lexer)?);
		case 'F' =>
			ctx.freestanding = true;
		case 'j' =>
			match (strconv::stoz(opt.1)) {
			case let z: size =>
				ctx.jobs = z;
			case strconv::invalid =>
				fmt::fatal("Number of jobs must be an integer");
			case strconv::overflow =>
				if (strings::hasprefix(opt.1, '-')) {
					fmt::fatal("Number of jobs must be positive");
				} else {
					fmt::fatal("Number of jobs is too large");
				};
			};
			if (ctx.jobs == 0) {
				fmt::fatal("Number of jobs must be non-zero");
			};
		case 'L' =>
			append(ctx.libdirs, opt.1);
		case 'l' =>
			append(ctx.libs, opt.1);
		case 'N' =>
			ast::ident_free(ctx.ns);
			ctx.ns = [];
			match (parse::identstr(opt.1)) {
			case let id: ast::ident =>
				ctx.ns = id;
			case lex::syntax =>
				return opt.1: invalid_namespace;
			case let e: parse::error =>
				return e;
			};
		case 'o' =>
			output = opt.1;
		case 'q' =>
			ctx.mode = build::output::SILENT;
		case 'R' =>
			ctx.release = true;
		case 'T' =>
			merge_tags(&ctx.ctx.tags, opt.1)?;
		case 't' =>
			switch (opt.1) {
			case "td" =>
				// intentionally undocumented
				ctx.goal = build::stage::TD;
			case "ssa" =>
				// intentionally undocumented
				ctx.goal = build::stage::SSA;
			case "s" =>
				ctx.goal = build::stage::S;
			case "o" =>
				ctx.goal = build::stage::O;
			case "bin" =>
				ctx.goal = build::stage::BIN;
			case =>
				return opt.1: unknown_type;
			};
		case 'v' =>
			if (ctx.mode == build::output::VERBOSE) {
				ctx.mode = build::output::VVERBOSE;
			} else if (ctx.mode != build::output::VVERBOSE) {
				ctx.mode = build::output::VERBOSE;
			} else {
				fmt::fatal("Number of verbose levels must be <= 2");
			};
		case =>
			abort();
		};
	};

	if (name == "build" && len(cmd.args) > 1) {
		getopt::printusage(os::stderr, name, cmd.help)!;
		os::exit(os::status::FAILURE);
	};

	set_arch_tags(&ctx.ctx.tags, arch);

	ctx.cmds = ["",
		os::tryenv("HAREC", "harec"),
		os::tryenv("QBE", "qbe"),
		os::tryenv("AS", arch.as_cmd),
		os::tryenv("LD", arch.ld_cmd),
	];
	if (!ctx.freestanding && (len(ctx.libs) > 0 || ctx.platform.need_libc)) {
		ctx.libc = true;
		merge_tags(&ctx.ctx.tags, "+libc")?;
		ctx.cmds[build::stage::BIN] = os::tryenv("CC", arch.cc_cmd);
	};

	const input = if (len(cmd.args) == 0) os::getcwd() else cmd.args[0];

	ctx.mods = build::gather(&ctx, os::realpath(input)?)?;
	append(ctx.hashes, [[void...]...], len(ctx.mods));

	let built = build::execute(&ctx)?;
	defer free(built);

	if (output == "") {
		if (name != "build") {
			return run(input, built, cmd.args);
		};
		output = get_output(ctx.goal, input)?;
	};

	let dest = os::stdout_file;
	if (output != "-") {
		let mode: fs::mode = 0o644;
		if (ctx.goal == build::stage::BIN) {
			mode |= 0o111;
		};
		// in the case that we are outputting to a binary that is
		// currently beeing executed, we need to remove it first or
		// otherwise os::create() will fail
		os::remove(output): void;
		dest = match (os::create(output, mode)) {
		case let f: io::file =>
			yield f;
		case let e: fs::error =>
			return (output, e): output_failed;
		};
	};
	defer io::close(dest)!;

	let src = os::open(built)?;
	defer io::close(src)!;
	io::copy(dest, src)?;
};

fn run(name: str, path: str, args: []str) error = {
	const args: []str = if (len(args) != 0) args[1..] else [];
	let cmd = match(exec::cmd(path, args...)) {
	case exec::nocmd =>
		fmt::fatalf("Error: Command not found: {}", path);
	case let e: exec::error =>
		return e;
	case let c: exec::command =>
		yield c;
	};
	exec::setname(&cmd, name);
	exec::exec(&cmd);
};

fn get_output(goal: build::stage, input: str) (str | error) = {
	static let buf = path::buffer { ... };
	let stat = os::stat(input)?;
	path::set(&buf, os::realpath(input)?)?;
	if (!fs::isdir(stat.mode)) {
		path::pop_ext(&buf);
	};
	// don't add the .bin extension if the goal is to create a binary
	if (goal != build::stage::BIN) {
		path::push_ext(&buf, build::stage_ext[goal])?;
	};

	const output = match (path::peek(&buf)) {
	case let s: str =>
		yield s;
	case void =>
		return unknown_output;
	};
	stat = match (os::stat(output)) {
	case let s: fs::filestat =>
		yield s;
	case errors::noentry =>
		return output;
	case fs::error =>
		// XXX: double cast here (and below) shouldn't be necessary
		return output: output_exists: error;
	};
	if (!fs::isfile(stat.mode)
			|| fs::mode_perm(stat.mode) & fs::mode::USER_X == 0) {
		return output: output_exists: error;
	};
	return output;
};
