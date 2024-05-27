// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

fn strvec(s: str) iovec = {
	return iovec {
		iov_base = *(&s: **opaque),
		iov_len = len(s),
	};
};

fn platform_abort(path: *str, line: u64, col: u64, msg: str) never = {
	let linebuf: [U64_BUFSZ]u8 = [0...];
	let colbuf: [U64_BUFSZ]u8 = [0...];

	const iov = [
		strvec("Abort: "),
		strvec(*path),
		strvec(":"),
		strvec(u64tos(linebuf, line)),
		strvec(":"),
		strvec(u64tos(colbuf, col)),
		strvec(": "),
		strvec(msg),
		strvec("\n"),
	];
	writev(STDERR_FILENO, &iov, len(iov): int): void;

	for (true) {
		kill(getpid(), SIGABRT): void;
	};
};
