// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use strings;

// All possible errors returned from [[date]].
export type error = !(insufficient | invalid | zfunresolved | parsefail);

// Converts an [[error]] into a human-friendly string. The result may be
// statically allocated.
export fn strerror(err: error) const str = {
	match (err) {
	case let lack: insufficient =>
		static let buf: [92]u8 = [0...];
		return strings::rtrim(fmt::bsprint(buf,
			"Insufficient date information, could not calculate:",
			if (lack & insufficient::LOCALITY: u8 == 0) "" else
				"locality",
			if (lack & insufficient::DAYDATE: u8 == 0) "" else
				"daydate",
			if (lack & insufficient::DAYTIME: u8 == 0) "" else
				"time-of-day",
			if (lack & insufficient::ZOFF: u8 == 0) "" else
				"zone-offset",
		));
	case invalid =>
		return "Invalid date information";
	case let lap: zfunresolved =>
		if (lap) {
			return "Failed to resolve zone-offset in a timezone transition overlap";
		} else {
			return "Failed to resolve zone-offset in a timezone transition gap";
		};
	case let pf: parsefail =>
		const (bi, rn) = pf;
		def FMTMSG = "Date parsing failure for layout rune '{}' at byteindex {}";
		static let buf: [len(FMTMSG) + 3]u8 = [0...];
		return fmt::bsprintf(buf, FMTMSG, rn, bi);
	};
};
