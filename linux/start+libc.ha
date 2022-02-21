// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
use rt;
use format::elf;

@init fn init_linux() void = {
	rt::start_linux();

	let i = 0;
	for (rt::envp[i] != null) {
		i += 1;
	};
	auxv = &rt::envp[i + 1]: *[*]elf::auxv64;
};
