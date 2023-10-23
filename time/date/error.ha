// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;

// All possible errors returned from [[date]].
export type error = !(insufficient | invalid | parsefail);

// Converts an [[error]] into a human-friendly string. The result may be
// statically allocated.
export fn strerror(err: error) const str = {
	match (err) {
	case insufficient =>
		return "Insufficient date information";
	case invalid =>
		return "Invalid date information";
	case let rn: parsefail =>
		if (rn == '\0') {
			return "Date parsing error";
		};
		def FMTMSG = "Invalid date format for specifier '{}'";
		static let buf: [len(FMTMSG) + 2]u8 = [0...];
		return fmt::bsprintf(buf, FMTMSG, rn);
	};
};
