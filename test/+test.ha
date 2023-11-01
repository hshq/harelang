// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use encoding::hex;
use encoding::utf8;
use fmt;
use fnmatch;
use io;
use memio;
use os;
use rt;
use strings;
use time;
use unix::signal;
use unix::tty;

type test = struct {
	name: str,
	func: *fn() void,
};

type failure = struct {
	test: str,
	reason: rt::abort_reason,
};

type output = struct {
	test: str,
	stdout: str,
	stderr: str,
};

fn finish_output(output: *output) void = {
	free(output.stdout);
	free(output.stderr);
};

type context = struct {
	stdout: memio::stream,
	stderr: memio::stream,
	failures: []failure,
	output: []output,
	maxname: size,
	total_time: time::duration,
	default_round: uint,
	cwd: str,
};

fn finish_context(ctx: *context) void = {
	io::close(&ctx.stdout)!;
	io::close(&ctx.stderr)!;
	free(ctx.failures);
	for (let i = 0z; i < len(ctx.output); i += 1) {
		finish_output(&ctx.output[i]);
	};
	free(ctx.output);
	free(ctx.cwd);
};

fn colored() bool = {
	return len(os::tryenv("NO_COLOR", "")) == 0
		&& tty::isatty(os::stdout_file);
};

let jmpbuf = rt::jmpbuf { ... };

const @symbol("__test_array_start") test_start: [*]test;
const @symbol("__test_array_end") test_end: [*]test;


export @symbol("__test_main") fn main() size = {
	const ntest = (&test_end: uintptr - &test_start: uintptr): size / size(test);
	const tests = test_start[..ntest];
	let enabled_tests: []test = [];
	defer free(enabled_tests);
	if (len(os::args) == 1) {
		append(enabled_tests, tests...);
	} else for (let i = 0z; i < ntest; i += 1) {
		for (let j = 1z; j < len(os::args); j += 1) {
			if (fnmatch::fnmatch(os::args[j], tests[i].name)) {
				append(enabled_tests, tests[i]);
				break;
			};
		};
	};

	let maxname = 0z;
	for (let i = 0z; i < len(enabled_tests); i += 1) {
		if (len(enabled_tests[i].name) > maxname) {
			maxname = len(enabled_tests[i].name);
		};
	};

	let ctx = context {
		stdout = memio::dynamic(),
		stderr = memio::dynamic(),
		maxname = maxname,
		default_round = rt::fegetround(),
		cwd = strings::dup(os::getcwd()),
		...
	};
	defer finish_context(&ctx);

	fmt::printfln("Running {}/{} tests:\n", len(enabled_tests), ntest)!;
	reset(&ctx);
	for (let i = 0z; i < len(enabled_tests); i += 1) {
		do_test(&ctx, enabled_tests[i]);
	};
	fmt::println()!;

	if (len(ctx.failures) > 0) {
		fmt::println("Failures:")!;
		for (let i = 0z; i < len(ctx.failures); i += 1) {
			match (ctx.failures[i].reason.path) {
			case null =>
				fmt::printfln("{}: {}",
					ctx.failures[i].test,
					ctx.failures[i].reason.msg)!;
			case let path: *str =>
				fmt::printfln("{}: {}:{}:{}: {}",
					ctx.failures[i].test,
					*path,
					ctx.failures[i].reason.line,
					ctx.failures[i].reason.col,
					ctx.failures[i].reason.msg)!;
			};
		};
		fmt::println()!;
	};

	for (let i = 0z; i < len(ctx.output); i += 1) {
		if (ctx.output[i].stdout != "") {
			fmt::println(ctx.output[i].test, "stdout:")!;
			fmt::println(ctx.output[i].stdout)!;
		};
		if (ctx.output[i].stderr != "") {
			fmt::println(ctx.output[i].test, "stderr:")!;
			fmt::println(ctx.output[i].stderr)!;
		};
		if (i == len(ctx.output) - 1) {
			fmt::println()!;
		};
	};

	// XXX: revisit once time::format_duration is implemented
	const passed_cnt = len(enabled_tests) - len(ctx.failures);
	const failed_cnt = len(ctx.failures);
	const total_cnt = len(enabled_tests);
	const elapsed_whole = ctx.total_time / time::SECOND;
	const elapsed_fraction = ctx.total_time % time::SECOND;
	if (colored()) {
		fmt::printfln("\x1b[{}m" "{}" "\x1b[m" " passed; "
			"\x1b[{}m" "{}" "\x1b[m"
			" failed; {} completed in {}.{:09}s",
			if (len(enabled_tests) != len(ctx.failures)) "92" else "37",
			passed_cnt,
			if (len(ctx.failures) > 0) "91" else "37",
			failed_cnt, total_cnt, elapsed_whole, elapsed_fraction)!;
	} else {
		fmt::printfln("{} passed; {} failed; {} completed in {}.{:09}s",
			passed_cnt, failed_cnt, total_cnt, elapsed_whole,
			elapsed_fraction)!;
	};

	easter_egg(ctx.failures, enabled_tests);

	return len(ctx.failures);
};

fn reset(ctx: *context) void = {
	rt::fesetround(ctx.default_round);
	rt::feclearexcept(~0u);
	signal::resetall();
	os::chdir(ctx.cwd)!;
};

fn do_test(ctx: *context, test: test) void = {
	signal::handle(signal::sig::SEGV, &handle_segv, signal::flag::NODEFER);
	memio::reset(&ctx.stdout);
	memio::reset(&ctx.stderr);

	const start_time = time::now(time::clock::MONOTONIC);

	const failed = match (run_test(ctx, test)) {
	case void =>
		yield false;
	case let f: failure =>
		append(ctx.failures, f);
		yield true;
	};

	const end_time = time::now(time::clock::MONOTONIC);
	const time_diff = time::diff(start_time, end_time);
	assert(time_diff >= 0);
	ctx.total_time += time_diff;
	fmt::printfln(" in {}.{:09}s",
		time_diff / 1000000000,
		time_diff % 1000000000)!;

	const stdout = memio::buffer(&ctx.stdout);
	const stdout = match (strings::fromutf8(stdout)) {
	case let s: str =>
		yield strings::dup(s);
	case utf8::invalid =>
		let s = memio::dynamic();
		hex::dump(&s, stdout)!;
		yield memio::string(&s)!;
	};
	const stderr = memio::buffer(&ctx.stderr);
	const stderr = match (strings::fromutf8(stderr)) {
	case let s: str =>
		yield strings::dup(s);
	case utf8::invalid =>
		let s = memio::dynamic();
		hex::dump(&s, stderr)!;
		yield memio::string(&s)!;
	};
	if (failed && (stdout != "" || stderr != "")) {
		append(ctx.output, output {
			test = test.name,
			stdout = stdout,
			stderr = stderr,
		});
	};

	reset(ctx);
};

fn run_test(ctx: *context, test: test) (void | failure) = {
	fmt::print(test.name)!;
	dots(ctx.maxname - len(test.name) + 3);
	bufio::flush(os::stdout)!; // write test name before test runs

	let orig_stdout = os::stdout;
	let orig_stderr = os::stderr;
	os::stdout = &ctx.stdout;
	os::stderr = &ctx.stderr;
	defer rt::jmp = null;
	const n = rt::setjmp(&jmpbuf);
	if (n != 0) {
		os::stdout = orig_stdout;
		os::stderr = orig_stderr;
		if (n == 1 && want_abort) {
			want_abort = false;
			pass();
			return;
		};
		return fail(test, n);
	};
	rt::jmp = &jmpbuf;

	test.func();
	os::stdout = orig_stdout;
	os::stderr = orig_stderr;
	if (want_abort) {
		want_abort = false;
		return fail(test, 1);
	};
	pass();
};

fn pass() void = {
	if (colored()) {
		fmt::print("\x1b[92m" "PASS" "\x1b[m")!;
	} else {
		fmt::print("PASS")!;
	};
};

fn fail(test: test, n: int) failure = {
	if (colored()) {
		fmt::print("\x1b[91m" "FAIL" "\x1b[m")!;
	} else {
		fmt::print("FAIL")!;
	};
	switch (n) {
	case 1 =>
		// assertion failed
		return failure {
			test = test.name,
			reason = rt::reason,
		};
	case 2 =>
		// segmentation fault
		return failure {
			test = test.name,
			reason = rt::abort_reason {
				msg = "Segmentation fault",
				...
			},
		};
	case =>
		// unrecognized failure
		return failure {
			test = test.name,
			reason = rt::abort_reason {
				msg = "Reason unknown",
				...
			},
		};
	};
};

fn dots(n: size) void = {
	for (let i = 0z; i < n; i += 1) {
		fmt::print(".")!;
	};
};

fn handle_segv(
	sig: signal::sig,
	info: *signal::siginfo,
	ucontext: *opaque,
) void = {
	rt::longjmp(&jmpbuf, 2);
};

fn easter_egg(fails: []failure, tests: []test) void = {
	// norwegian deadbeef
	let blob: [_]u8 = [
		0xe1, 0x41, 0xf2, 0x21, 0x3f, 0x9e, 0x2d, 0xfe, 0x3f, 0x9e,
		0x22, 0xfc, 0x43, 0xc2, 0x2f, 0x82, 0x15, 0xd1, 0x62, 0xae,
		0x6c, 0x9e, 0x71, 0xfe, 0x33, 0xc2, 0x71, 0xfe, 0x63, 0xb4,
		0x2d, 0xfe, 0x3f, 0xe1, 0x52, 0xf2, 0x43, 0xc6, 0x2d, 0xf9,
		0x3d, 0x90, 0x07, 0xfe, 0x33, 0x9c, 0x2d, 0xfe, 0x3f, 0x96,
		0x2d, 0x8f, 0x3f, 0x9e, 0x64, 0xd4, 0x33, 0x9c, 0x21, 0xfe,
		0x3f, 0x9e, 0x2d, 0x82, 0x40, 0x9e, 0x54, 0xf9, 0x15, 0x99,
		0x30, 0xfe, 0x3f, 0x92, 0x2d, 0xfe, 0x31, 0x9e, 0x2d, 0xfe,
		0x38, 0xb4, 0x2d, 0xf9, 0x22, 0x83, 0x52, 0xf9, 0x40, 0xe1,
		0x30, 0xe3, 0x38, 0x9e, 0x2d, 0xd4,
	];
	let words = &blob: *[24]u32;

	// doesn't currently work on big-endian, would need to re-find the
	// constants and use a different blob there
	if (words[0]: u8 != 0xe1) return;

	words[0] ^= len(tests): u32;

	let hash = 2166136261u32;
	for (let i = 0z; i < size(u32); i += 1) {
		hash = (hash ^ blob[i]) * 16777619;
	};

	for (let i = 0z; i < len(words); i += 1) {
		words[i] ^= hash;
	};

	if (-len(fails): u32 == words[0]) {
		io::write(os::stdout, blob[size(u32)..])!;
	};
};
