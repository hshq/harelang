// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

export type platform = struct {
	name: str,
	// Do we always need to link with libc? (and use cc instead of ld)
	need_libc: bool,
	// Additional default flags for this platform.
	default_flags: [NSTAGES][]str,
};

const platforms: [_]platform = [
	platform {
		name = "Linux",
		...
	},
	platform {
		name = "FreeBSD",
		...
	},
	platform {
		name = "OpenBSD",
		need_libc = true,
		default_flags = [
			[],
			[],
			[],
			[],
			// IBT/BTI is a CPU feature that prevents ROP-attacks.
			// Since this is enforced by default on OpenBSD but not
			// implemented by QBE, we need to disable the
			// enforcement.  ld.lld(1) can do this for us by
			// creating a custom segment.
			["-z", "nobtcfi"],
		],
	},
];

export fn get_platform(name: str) (*platform | unknown_platform) = {
	for (let platform &.. platforms) {
		if (platform.name == name) {
			return platform;
		};
	};
	return name: unknown_platform;
};
