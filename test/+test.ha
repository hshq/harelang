// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
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

// RETURN and ABORT must be 0 and 1 respectively
type status = enum {
	RETURN = 0,
	ABORT = 1,
	SKIP,
	SEGV,
};

type failure = struct {
	test: str,
	reason: rt::abort_reason,
};

type skipped = struct {
	test: str,
	reason: str,
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
	skipped: []skipped,
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
	free(ctx.skipped);
	for (let out &.. ctx.output) {
		finish_output(out);
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
		for (let arg .. os::args) {
			if (fnmatch::fnmatch(arg, tests[i].name)) {
				append(enabled_tests, tests[i]);
				break;
			};
		};
	};
	if (len(enabled_tests) == 0) {
		fmt::println("No tests run")!;
		return 0;
	};

	let maxname = 0z;
	for (let test .. enabled_tests) {
		if (len(test.name) > maxname) {
			maxname = len(test.name);
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
	for (let test .. enabled_tests) {
		do_test(&ctx, test);
	};
	fmt::println()!;

	for (let skipped .. ctx.skipped) {
		fmt::printfln("Skipped {}: {}", skipped.test, skipped.reason)!;
	};
	if (len(ctx.skipped) > 0) {
		fmt::println()!;
	};

	if (len(ctx.failures) > 0) {
		fmt::println("Failures:")!;
		for (let failure .. ctx.failures) {
			match (failure.reason.path) {
			case null =>
				fmt::printfln("{}: {}",
					failure.test,
					failure.reason.msg)!;
			case let path: *str =>
				fmt::printfln("{}: {}:{}:{}: {}",
					failure.test,
					*path,
					failure.reason.line,
					failure.reason.col,
					failure.reason.msg)!;
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
	const total_cnt = len(enabled_tests);
	const failed_cnt = len(ctx.failures);
	const skipped_cnt = len(ctx.skipped);
	const passed_cnt = total_cnt - failed_cnt - skipped_cnt;
	const elapsed_whole = ctx.total_time / time::SECOND;
	const elapsed_fraction = ctx.total_time % time::SECOND;
	styled_print(if (passed_cnt > 0) 92 else 37, passed_cnt);
	fmt::print(" passed; ")!;
	styled_print(if (len(ctx.failures) > 0) 91 else 37, failed_cnt);
	fmt::print(" failed; ")!;
	if (len(ctx.skipped) > 0) {
		fmt::print(len(ctx.skipped), "skipped; ")!;
	};
	fmt::printfln("{} completed in {}.{:.9}s", total_cnt,
		elapsed_whole, elapsed_fraction)!;

	easter_egg(ctx.failures, enabled_tests);

	return len(ctx.failures);
};

fn reset(ctx: *context) void = {
	rt::fesetround(ctx.default_round);
	rt::feclearexcept(~0u);
	signal::resetall();
	os::chdir(ctx.cwd)!;
	want_abort = false;
};

fn do_test(ctx: *context, test: test) void = {
	signal::handle(signal::sig::SEGV, &handle_segv, signal::flag::NODEFER);
	memio::reset(&ctx.stdout);
	memio::reset(&ctx.stderr);

	const start_time = time::now(time::clock::MONOTONIC);
	const status = run_test(ctx, test);
	const end_time = time::now(time::clock::MONOTONIC);

	const failed = interpret_status(ctx, test.name, status);
	const time_diff = time::diff(start_time, end_time);
	assert(time_diff >= 0);
	ctx.total_time += time_diff;
	fmt::printfln(" in {}.{:.9}s",
		time_diff / 1000000000,
		time_diff % 1000000000)!;

	const stdout = printable(memio::buffer(&ctx.stdout));
	const stderr = printable(memio::buffer(&ctx.stderr));
	if (failed && (stdout != "" || stderr != "")) {
		append(ctx.output, output {
			test = test.name,
			stdout = stdout,
			stderr = stderr,
		});
	};

	reset(ctx);
};

fn run_test(ctx: *context, test: test) status = {
	fmt::print(test.name)!;
	dots(ctx.maxname - len(test.name) + 3);
	bufio::flush(os::stdout)!; // write test name before test runs

	let orig_stdout = os::stdout;
	let orig_stderr = os::stderr;
	os::stdout = &ctx.stdout;
	os::stderr = &ctx.stderr;
	defer rt::jmp = null;
	const n = rt::setjmp(&jmpbuf): status;
	if (n == status::RETURN) {
		rt::jmp = &jmpbuf;
		test.func();
	};

	os::stdout = orig_stdout;
	os::stderr = orig_stderr;
	return n;
};

fn printable(buf: []u8) str = {
	match (strings::fromutf8(buf)) {
	case let s: str =>
		let it = strings::iter(s);
		for (true) match (strings::next(&it)) {
		case done =>
			return strings::dup(s);
		case let r: rune =>
			if (ascii::valid(r) && !ascii::isprint(r)
					&& r != '\t' && r != '\n') {
				break;
			};
		};
	case utf8::invalid => void;
	};

	let s = memio::dynamic();
	hex::dump(&s, buf)!;
	return memio::string(&s)!;
};

fn dots(n: size) void = {
	for (let i = 0z; i < n; i += 1) {
		fmt::print(".")!;
	};
};

// returns true if test failed, false if it passed or was skipped
fn interpret_status(ctx: *context, test: str, status: status) bool = {
	switch (status) {
	case status::RETURN =>
		if (want_abort) {
			styled_print(91, "FAIL");
			append(ctx.failures, failure {
				test = test,
				reason = rt::abort_reason {
					msg = "Expected test to abort",
					...
				},
			});
			return true;
		} else {
			styled_print(92, "PASS");
			return false;
		};
	case status::ABORT =>
		if (want_abort) {
			styled_print(92, "PASS");
			return false;
		} else {
			styled_print(91, "FAIL");
			append(ctx.failures, failure {
				test = test,
				reason = rt::reason,
			});
			return true;
		};
	case status::SKIP =>
		styled_print(37, "SKIP");
		append(ctx.skipped, skipped {
			test = test,
			reason = rt::reason.msg,
		});
		return false;
	case status::SEGV =>
		styled_print(91, "FAIL");
		append(ctx.failures, failure {
			test = test,
			reason = rt::abort_reason {
				msg = "Segmentation fault",
				...
			},
		});
		return true;
	};
};

fn styled_print(color: int, result: fmt::formattable) void = {
	if (colored()) {
		fmt::printf("\x1b[{}m" "{}" "\x1b[m", color, result)!;
	} else {
		fmt::print(result)!;
	};
};

fn handle_segv(
	sig: signal::sig,
	info: *signal::siginfo,
	ucontext: *opaque,
) void = {
	rt::longjmp(&jmpbuf, status::SEGV);
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
