export fn memmove(dest: *void, src: *void, n: size) void = {
	let d = dest: *[*]u8, s = src: *[*]u8;
	if (d: uintptr == s: uintptr) {
		return;
	};

	if (d: uintptr < s: uintptr) {
		for (let i = 0z; i < n; i += 1) {
			d[i] = s[i];
		};
	} else {
		for (let i = 0z; i < n; i += 1) {
			d[n - i - 1] = s[n - i - 1];
		};
	};
};
