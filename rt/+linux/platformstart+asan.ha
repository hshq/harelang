// License: MPL-2.0
// (c) 2021 Armin Weigl <tb46305@gmail.com>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>

def HIGH_SHADOW_MIN: uintptr = 0x02008fff7000: uintptr;
def HIGH_SHADOW_MAX: uintptr = 0x10007fff7fff: uintptr;
def LOW_SHADOW_MIN: uintptr  = 0x00007fff8000: uintptr;
def LOW_SHADOW_MAX: uintptr  = 0x00008fff6fff: uintptr;

fn map_shadow(
	addr: nullable *void,
	length: size,
	prot: uint,
	flags: uint,
	fd: int,
	offs: size
) void = {
	// This is a bit of a hack to deal with harec generating ASAN stuff for
	// rt::mmap, which doesn't work before the shadow areas are mapped in
	// the first place. This code is written to carefully avoid generating
	// any ASAN stuff.
	assert(syscall6(SYS_mmap, addr: uintptr: u64, length: u64,
			prot: u64, flags: u64, fd: u64,
			offs: u64) == addr: uintptr: u64);
};

export @noreturn fn start_linux(iv: *[*]uintptr) void = {
	map_shadow(
		HIGH_SHADOW_MIN,
		HIGH_SHADOW_MAX - HIGH_SHADOW_MIN + 1,
		PROT_READ | PROT_WRITE,
		MAP_PRIVATE | MAP_ANON | MAP_FIXED_NOREPLACE | MAP_NORESERVE, -1, 0);
	map_shadow(
		LOW_SHADOW_MIN,
		LOW_SHADOW_MAX - LOW_SHADOW_MIN + 1,
		PROT_READ | PROT_WRITE,
		MAP_PRIVATE | MAP_ANON | MAP_FIXED_NOREPLACE | MAP_NORESERVE, -1, 0);

	argc = iv[0]: size;
	argv = &iv[1]: *[*]*char;
	envp = &argv[argc + 1]: *[*]nullable *char;
	start_ha();
};
