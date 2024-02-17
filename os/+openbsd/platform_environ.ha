// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use math;
use rt;
use strings;
use types::c;

// The command line arguments provided to the program. By convention, the first
// member is usually the name of the program.
export let args: []str = [];

// Statically allocate arg strings if there are few enough arguments, saves a
// syscall if we don't need it.
let args_static: [32]str = [""...];

@init fn args() void = {
	if (rt::argc < len(args_static)) {
		args = args_static[..rt::argc];
		for (let i = 0z; i < rt::argc; i += 1) {
			args[i] = c::tostr(rt::argv[i]: *const c::char)!;
		};
	} else {
		args = alloc([], rt::argc);
		for (let i = 0z; i < rt::argc; i += 1) {
			append(args, c::tostr(rt::argv[i]: *const c::char)!);
		};
	};
};

@fini fn args() void = {
	if (rt::argc >= len(args_static)) {
		free(args);
	};
};

// Returns a slice of the environment strings in form KEY=VALUE.
export fn getenvs() []str = {
	if (len(envp) > 0) {
		return envp;
	};
	for (let i = 0z; rt::envp[i] != null; i += 1) {
		let s = c::tostr(rt::envp[i]: *const c::char)!;
		append(envp, strings::dup(s));
	};
	return envp;
};

// Returns the host kernel name
export fn sysname() const str = {
	let name: [2]int = [rt::CTL_KERN, rt::KERN_OSTYPE];

	static let buf: [32]u8 = [0...];
	let buf_sz = len(buf);

	rt::sysctl(name, len(name): uint, &buf, &buf_sz, null, 0)!;
	return strings::fromutf8(buf[..(buf_sz -1)])!;
};

// Returns the host system hostname
export fn hostname() const str = {
	let name: [2]int = [rt::CTL_KERN, rt::KERN_HOSTNAME];

	static let buf: [rt::MAXHOSTNAMELEN]u8 = [0...];
	let buf_sz = len(buf);

	rt::sysctl(name, len(name): uint, &buf, &buf_sz, null, 0)!;
	return strings::fromutf8(buf[..(buf_sz -1)])!;
};

// Returns the host operating system version
export fn version() const str = {
	let name: [2]int = [rt::CTL_KERN, rt::KERN_OSRELEASE];

	static let buf: [32]u8 = [0...];
	let buf_sz = len(buf);

	rt::sysctl(name, len(name): uint, &buf, &buf_sz, null, 0)!;
	return strings::fromutf8(buf[..(buf_sz -1)])!;
};

// Returns the host CPU architecture, in a platform-specific format. See
// [[architecture]] for a more portable wrapper.
export fn machine() const str = {
	let name: [2]int = [rt::CTL_HW, rt::HW_MACHINE];

	static let buf: [32]u8 = [0...];
	let buf_sz = len(buf);

	rt::sysctl(name, len(name): uint, &buf, &buf_sz, null, 0)!;

	return strings::fromutf8(buf[..(buf_sz - 1)])!;
};

// Returns the host CPU architecture.
export fn architecture() arch = {
	switch (machine()) {
	case "arm64" =>
		return arch::AARCH64;
	case "riscv64" =>
		return arch::RISCV64;
	case "amd64" =>
		return arch::X86_64;
	case => abort(); // unreachable
	};
};

// Returns the number of usable CPUs.
export fn cpucount() (size | errors::error) = {
	let name: [2]int = [rt::CTL_HW, rt::HW_NCPUONLINE];

	let ncpu: int = 0;
	let ncpu_sz = size(int);

	match (rt::sysctl(name, len(name): uint, &ncpu, &ncpu_sz, null, 0)) {
	case void =>
		return ncpu: size;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};
