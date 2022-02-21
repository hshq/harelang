// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use bytes;
use rt;
use strings;
use types;

// The command line arguments provided to the program. By convention, the first
// member is usually the name of the program.
export let args: []str = [];

// Statically allocate arg strings if there are few enough arguments, saves a
// syscall if we don't need it.
let args_static: [32]str = [""...];

@init fn init_environ() void = {
	if (rt::argc < len(args_static)) {
		args = args_static[..rt::argc];
		for (let i = 0z; i < rt::argc; i += 1) {
			args[i] = strings::fromc(rt::argv[i]);
		};
	} else {
		args = alloc([], rt::argc);
		for (let i = 0z; i < rt::argc; i += 1) {
			append(args, strings::fromc(rt::argv[i]));
		};
	};

};

@fini fn fini_environ() void = {
	if (rt::argc >= len(args_static)) {
		free(args);
	};
};

// Looks up an environment variable and returns its value, or void if unset.
export fn getenv(name: const str) (str | void) = {
	const name_b = strings::toutf8(name);
	for (let i = 0z; rt::envp[i] != null; i += 1) {
		const item = rt::envp[i]: *[*]u8;
		const ln = strings::cstrlen(item: *char);
		const eq: size = match (bytes::index(item[..ln], '=': u8)) {
		case void =>
			abort("Environment violates System-V invariants");
		case let i: size =>
			yield i;
		};
		if (bytes::equal(name_b, item[..eq])) {
			const ln = strings::cstrlen(item: *const char);
			return strings::fromutf8(item[eq+1..ln]);
		};
	};
};

// Looks up an environment variable and returns its value, or a default value if
// unset.
export fn tryenv(name: const str, default: str) str = match (getenv(name)) {
case let s: str =>
	yield s;
case void =>
	yield default;
};

let envp: []str = [];

// Returns a slice of the environment strings in the form KEY=VALUE.
export fn getenvs() []str = {
	if (len(envp) != 0) {
		return envp;
	};
	for (let i = 0z; rt::envp[i] != null; i += 1) {
		append(envp, strings::fromc(rt::envp[i]: *const char));
	};
	return envp;
};

// Returns the host kernel name
export fn sysname() const str = {
	static let buf: [512]u8 = [0...];
	let sz: size = len(buf);
	rt::sysctlbyname("kern.ostype", &buf, &sz, null, 0)!;
	return strings::fromutf8(buf[..(sz - 1)]);
};

// Returns the host system hostname
export fn hostname() const str = {
	static let buf: [512]u8 = [0...];
	let sz: size = len(buf);
	rt::sysctlbyname("kern.hostname", &buf, &sz, null, 0)!;
	return strings::fromutf8(buf[..(sz - 1)]);
};

// Returns the host kernel version
export fn release() const str = {
	static let buf: [512]u8 = [0...];
	let sz: size = len(buf);
	rt::sysctlbyname("kern.osrelease", &buf, &sz, null, 0)!;
	return strings::fromutf8(buf[..(sz - 1)]);
};

// Returns the host operating system version
export fn version() const str = {
	static let buf: [512]u8 = [0...];
	let sz: size = len(buf);
	rt::sysctlbyname("kern.version", &buf, &sz, null, 0)!;
	return strings::fromutf8(buf[..(sz - 1)]);
};

// Returns the host CPU architecture
export fn machine() const str = {
	static let buf: [512]u8 = [0...];
	let sz: size = len(buf);
	rt::sysctlbyname("hw.machine", &buf, &sz, null, 0)!;
	const mach = strings::fromutf8(buf[..(sz - 1)]);
	// Translate to Hare names
	switch (mach) {
	case "amd64" =>
		return "x86_64";
	case =>
		return mach;
	};
};
