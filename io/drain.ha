// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Reads an entire stream into a []u8. The caller must free the return value.
// Note that this function will never return if the handle is infinite.
export fn drain(in: handle) ([]u8 | error) = {
	let sink: []u8 = [];
	static let buf: [4096]u8 = [0...];

	for (let n => read(in, buf[..])?) {
		append(sink, buf[..n]...);
	};
	return sink;
};
