// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use strings;

// All currently supported target architectures. This enum will be extended
// whenever support for a new architecture is added.
export type arch = enum {
	AARCH64,
	RISCV64,
	X86_64,
};

// Returns a portable string for an [[arch]].
export fn arch_name(arch: arch) const str = {
	switch (arch) {
	case arch::AARCH64 =>
		return "aarch64";
	case arch::RISCV64 =>
		return "riscv64";
	case arch::X86_64 =>
		return "x86_64";
	};
};

let envp: []str = [];

@fini fn envp() void = strings::freeall(envp);

// Looks up an environment variable and returns its value, or void if unset.
export fn getenv(name: const str) (str | void) = {
	getenvs(); // populate envp
	for (let ent .. envp) {
		let (key, value) = strings::cut(ent, "=");
		if (key == name) return value;
	};
};

// Looks up an environment variable and returns its value, or a default value if
// unset.
export fn tryenv(name: const str, default: str) str = match (getenv(name)) {
case let s: str => return s;
case void => return default;
};

// Sets an environment variable, overwriting it if it's already set. The name
// may not contain '=' or '\0', and the value may not contain '\0'.
export fn setenv(name: const str, value: const str) (void | errors::invalid) = {
	if (strings::contains(value, '\0')) return errors::invalid;
	unsetenv(name)?;
	append(envp, strings::join("=", name, value));
};

// Unsets an environment variable. Does nothing if the variable isn't set. The
// name may not contain '=' or '\0'.
export fn unsetenv(name: const str) (void | errors::invalid) = {
	if (strings::contains(name, '=', '\0')) return errors::invalid;
	getenvs(); // populate envp
	for (let i = 0z; i < len(envp); i += 1) {
		if (strings::cut(envp[i], "=").0 == name) {
			free(envp[i]);
			delete(envp[i]);
			break;
		};
	};
};
