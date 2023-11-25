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
];

export fn get_platform(name: str) (*platform | unknown_platform) = {
	for (let i = 0z; i < len(platforms); i += 1) {
		if (platforms[i].name == name) {
			return &platforms[i];
		};
	};
	return name: unknown_platform;
};
