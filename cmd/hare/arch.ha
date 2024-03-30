// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use cmd::hare::build;

// When building the bootstrap toolchain, these values will get overwritten to
// equal the values in config.mk
def AARCH64_AS = "as";
def AARCH64_CC = "cc";
def AARCH64_LD = "ld";
def RISCV64_AS = "as";
def RISCV64_CC = "cc";
def RISCV64_LD = "ld";
def X86_64_AS  = "as";
def X86_64_CC  = "cc";
def X86_64_LD  = "ld";

// TODO: implement cross compiling to other kernels (e.g. linux => freebsd)
// TODO: sysroots
const arches: [_]build::arch = [
	build::arch {
		name = "aarch64",
		qbe_name = "arm64",
		as_cmd = AARCH64_AS,
		cc_cmd = AARCH64_CC,
		ld_cmd = AARCH64_LD,
	},
	build::arch {
		name = "riscv64",
		qbe_name = "rv64",
		as_cmd = RISCV64_AS,
		cc_cmd = RISCV64_CC,
		ld_cmd = RISCV64_LD,
	},
	build::arch {
		name = "x86_64",
		qbe_name = "amd64_sysv",
		as_cmd = X86_64_AS,
		cc_cmd = X86_64_CC,
		ld_cmd = X86_64_LD,
	},
];

fn set_arch_tags(tags: *[]str, a: *build::arch) void = {
	merge_tags(tags, "-aarch64-riscv64-x86_64")!;
	append(tags, a.name);
};

fn get_arch(name: str) (*build::arch | unknown_arch) = {
	for (let arch &.. arches) {
		if (arch.name == name) {
			return arch;
		};
	};
	return name: unknown_arch;
};
