use hare::module;
use hare::module::{tag_mode};

type target = struct {
	name: str,
	ar_cmd: str,
	as_cmd: str,
	cc_cmd: str,
	ld_cmd: str,
	qbe_target: str,
	tags: []module::tag,
};

fn default_target() *target = {
	let default = get_target(ARCH);
	match (default) {
	case void =>
		abort("Build configuration error - unknown default target");
	case let t: *target =>
		return t;
	};
};

fn get_target(name: str) (*target | void) = {
	for (let i = 0z; i < len(targets); i += 1) {
		if (targets[i].name == name) {
			return &targets[i];
		};
	};
};

// TODO:
// - Implement cross compiling to other kernels (e.g. Linux => FreeBSD)
// - sysroots
const targets: [_]target = [
	target {
		name = "aarch64",
		ar_cmd = AARCH64_AR,
		as_cmd = AARCH64_AS,
		cc_cmd = AARCH64_CC,
		ld_cmd = AARCH64_LD,
		qbe_target = "arm64_apple",
		tags = [module::tag {
			name = "aarch64",
			mode = tag_mode::INCLUSIVE,
		}, module::tag {
			name = PLATFORM,
			mode = module::tag_mode::INCLUSIVE,
		}],
	},
	target {
		name = "riscv64",
		ar_cmd = RISCV64_AR,
		as_cmd = RISCV64_AS,
		cc_cmd = RISCV64_CC,
		ld_cmd = RISCV64_LD,
		qbe_target = "rv64",
		tags = [module::tag {
			name = "riscv64",
			mode = tag_mode::INCLUSIVE,
		}, module::tag {
			name = PLATFORM,
			mode = module::tag_mode::INCLUSIVE,
		}],
	},
	target {
		name = "x86_64",
		ar_cmd = X86_64_AR,
		as_cmd = X86_64_AS,
		cc_cmd = X86_64_CC,
		ld_cmd = X86_64_LD,
		qbe_target = "amd64_apple",
		tags = [module::tag {
			name = "x86_64",
			mode = tag_mode::INCLUSIVE,
		}, module::tag {
			name = PLATFORM,
			mode = module::tag_mode::INCLUSIVE,
		}],
	},
];
