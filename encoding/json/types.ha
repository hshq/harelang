// License: MPL-2.0
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use fmt;
use io;

// An invalid JSON token was encountered at this location (line, column).
export type invalid = !(uint, uint);

// The maximum nesting limit was reached.
export type limitreached = !void;

// A tagged union of all possible errors returned from this module.
export type error = !(invalid | limitreached | io::error);

// The JSON null value.
export type _null = void;

// The '[' token, signaling the start of a JSON array.
export type arraystart = void;

// The ']' token, signaling the end of a JSON array.
export type arrayend = void;

// The '{' token, signaling the start of a JSON object.
export type objstart = void;

// The '}' token, signaling the end of a JSON object.
export type objend = void;

// The ':' token.
export type colon = void;

// The ',' token.
export type comma = void;

// All tokens which can be returned from the JSON tokenizer.
export type token = (arraystart | arrayend | objstart |
	objend | colon | comma | str | f64 | bool | _null);

// Converts an [[error]] into a human-friendly string.
export fn strerror(err: error) const str = {
	static let buf: [53]u8 = [0...];
	match (err) {
	case let err: invalid =>
		return fmt::bsprintf(buf,
			"{}:{}: Invalid JSON token encountered", err.0, err.1);
	case let err: io::error =>
		return io::strerror(err);
	};
};
