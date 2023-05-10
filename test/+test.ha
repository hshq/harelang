use bufio;
use encoding::hex;
use encoding::utf8;
use fmt;
use fnmatch;
use io;
use os;
use rt;
use strings;
use strio;
use time;
use unix::signal;

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
	stdout: bufio::memstream,
	stderr: bufio::memstream,
	failures: []failure,
	output: []output,
	maxname: size,
	total_time: time::duration,
	default_round: uint,
};

fn finish_context(ctx: *context) void = {
	io::close(&ctx.stdout)!;
	io::close(&ctx.stderr)!;
	free(ctx.failures);
	for (let i = 0z; i < len(ctx.output); i += 1) {
		finish_output(&ctx.output[i]);
	};
	free(ctx.output);
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
		stdout = bufio::dynamic(io::mode::WRITE),
		stderr = bufio::dynamic(io::mode::WRITE),
		maxname = maxname,
		default_round = rt::fegetround(),
		...
	};
	defer finish_context(&ctx);

	fmt::printfln("Running {}/{} tests:\n", len(enabled_tests), ntest)!;
	for (let i = 0z; i < len(enabled_tests); i += 1) {
		do_test(&ctx, enabled_tests[i]);
	};
	fmt::println()!;

	if (len(ctx.failures) > 0) {
		fmt::println("Failures:")!;
		for (let i = 0z; i < len(ctx.failures); i += 1) {
			fmt::printfln("{}: {}", ctx.failures[i].test,
				ctx.failures[i].reason.msg)!;
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
	fmt::printfln("\x1b[{}m" "{}" "\x1b[m" " passed; "
		"\x1b[{}m" "{}" "\x1b[m" " failed; {} completed in {}.{:09}s",
		if (len(enabled_tests) != len(ctx.failures)) "92" else "37",
		len(enabled_tests) - len(ctx.failures),
		if (len(ctx.failures) > 0) "91" else "37",
		len(ctx.failures),
		len(enabled_tests),
		ctx.total_time / 1000000000,
		ctx.total_time % 1000000000)!;

	return len(ctx.failures);
};

fn do_test(ctx: *context, test: test) void = {
	signal::handle(signal::SIGSEGV, &handle_segv, signal::flags::NODEFER);
	bufio::reset(&ctx.stdout);
	bufio::reset(&ctx.stderr);

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

	const stdout = bufio::buffer(&ctx.stdout);
	const stdout = match (strings::fromutf8(stdout)) {
	case let s: str =>
		yield strings::dup(s);
	case utf8::invalid =>
		let s = strio::dynamic();
		hex::dump(&s, stdout)!;
		yield strio::string(&s);
	};
	const stderr = bufio::buffer(&ctx.stderr);
	const stderr = match (strings::fromutf8(stderr)) {
	case let s: str =>
		yield strings::dup(s);
	case utf8::invalid =>
		let s = strio::dynamic();
		hex::dump(&s, stderr)!;
		yield strio::string(&s);
	};
	if (failed && (stdout != "" || stderr != "")) {
		append(ctx.output, output {
			test = test.name,
			stdout = stdout,
			stderr = stderr,
		});
	};

	rt::fesetround(ctx.default_round);
	rt::feclearexcept(~0u);
	signal::resetall();
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
	fmt::print("\x1b[92m" "PASS" "\x1b[m")!;
};

fn fail(test: test, n: int) failure = {
	fmt::print("\x1b[91m" "FAIL" "\x1b[m")!;
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
				loc = "",
				msg = "Segmentation fault",
			},
		};
	case =>
		// unrecognized failure
		return failure {
			test = test.name,
			reason = rt::abort_reason {
				loc = "",
				msg = "Reason unknown",
			},
		};
	};
};

fn dots(n: size) void = {
	for (let i = 0z; i < n; i += 1) {
		fmt::print(".")!;
	};
};

fn handle_segv(sig: int, info: *signal::siginfo, ucontext: *void) void = {
	rt::longjmp(&jmpbuf, 2);
};
