use io;

// An invalid JSON token was encountered.
export type invalid = !void;

// A tagged union of all possible errors returned from this module.
export type error = !(invalid | io::error);

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
