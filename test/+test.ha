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
		stdout = memio::dynamic(),
		stderr = memio::dynamic(),
		maxname = maxname,
		default_round = rt::fegetround(),
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
			if (ctx.failures[i].reason.loc != "") {
				fmt::printfln("{}: {}: {}",
					ctx.failures[i].test,
					ctx.failures[i].reason.loc,
					ctx.failures[i].reason.msg)!;
			} else {
				fmt::printfln("{}: {}",
					ctx.failures[i].test,
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
	fmt::printfln("\x1b[{}m" "{}" "\x1b[m" " passed; "
		"\x1b[{}m" "{}" "\x1b[m" " failed; {} completed in {}.{:09}s",
		if (len(enabled_tests) != len(ctx.failures)) "92" else "37",
		len(enabled_tests) - len(ctx.failures),
		if (len(ctx.failures) > 0) "91" else "37",
		len(ctx.failures),
		len(enabled_tests),
		ctx.total_time / 1000000000,
		ctx.total_time % 1000000000)!;
	ignoreme(ctx.failures, enabled_tests);

	return len(ctx.failures);
};

fn reset(ctx: *context) void = {
	rt::fesetround(ctx.default_round);
	rt::feclearexcept(~0u);
	signal::resetall();
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

fn handle_segv(
	sig: signal::sig,
	info: *signal::siginfo,
	ucontext: *opaque,
) void = {
	rt::longjmp(&jmpbuf, 2);
};

type v=void;type c2PwF=!v;type gflSJ1=!v;type VJFX41=!v;type oMNH5=!v;
type j7C1g=const v;type nCDz5=v;type dYR380=const v;type UkR98=v;
type uCQ9k1=const!v;type AzynW=!v;type EKlfK=!v;type KMDkP=v;
type zHeoH0=const!v;type y276b0=const v;type K0z9G=v;type ELqC6=!v;type CLnjO=v;
type s8m1Q=const v;type EUSXs=const v;type P3TMF0=const!v;type sVdxM0=v;
type DxwxF=const v;type pRwKO=const v;type a7zIB0=const v;

fn ignoreme(i: []failure, j: []test) void = {
	// norwegian deadbeef
	let a: [_](c2PwF|gflSJ1|VJFX41|oMNH5|j7C1g| nCDz5|dYR380|UkR98|uCQ9k1|
			AzynW|EKlfK|KMDkP|zHeoH0|y276b0|K0z9G|ELqC6|CLnjO|s8m1Q|
			EUSXs|P3TMF0|sVdxM0|DxwxF|pRwKO|a7zIB0) = [
		c2PwF,gflSJ1,VJFX41,oMNH5,j7C1g,nCDz5,dYR380,UkR98,uCQ9k1,AzynW,
		EKlfK,KMDkP,zHeoH0,y276b0,K0z9G,ELqC6,CLnjO,s8m1Q,EUSXs,P3TMF0,
		sVdxM0,DxwxF,pRwKO,a7zIB0,
	];
	let i=len(i):u32,j=len(j):u32,b=&a:*[96]u8,c=&a:*[24]u32;
	let d=2166136261u32,e=b[64]>>2u32;c[0]^=j-i;for(let f=0z;f<4;f+=1)
	d=(d^b[f])*16777619;for(let g=0z;g<len(a);g+=1)c[g]^=d;d=2166136261;
	for(let h=0z;h<96;h+=1)d=(d^b[h])*16777619;
	if (d==3280045096&&(j-i):u32<<e|-j-1<<e>>e<c[0]^~0<<e)
		io::write(os::stdout, b[4..])!;
};
