// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

fn platform_abort(path: *str, line: u64, col: u64, msg: str) never = {
	const prefix = "Abort: ";
	const sep = ":";
	const sepspace = ": ";
	const linefeed = "\n";
	write(STDERR_FILENO, *(&prefix: **opaque): *const u8, len(prefix)): void;
	write(STDERR_FILENO, *(path: **opaque): *const u8, len(path)): void;
	write(STDERR_FILENO, *(&sep: **opaque): *const u8, len(sep)): void;
	let (line, z) = u64tos(line);
	write(STDERR_FILENO, line, z): void;
	write(STDERR_FILENO, *(&sep: **opaque): *const u8, len(sep)): void;
	let (col, z) = u64tos(col);
	write(STDERR_FILENO, col, z): void;
	write(STDERR_FILENO, *(&sepspace: **opaque): *const u8,
		len(sepspace)): void;
	write(STDERR_FILENO, *(&msg: **opaque): *const u8, len(msg)): void;
	write(STDERR_FILENO, *(&linefeed: **opaque): *const u8, 1): void;
	kill(getpid(), SIGABRT): void;
	for (true) void;
};
