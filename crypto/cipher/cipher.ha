// License: MPL-2.0
// (c) 2021 Armin Preiml <apreiml@strohwolke.at>

// Discards any state associated with a block or a stream cipher algorithm,
// securely erasing secret data from memory.
export fn finish(a: (*block | *stream)) void = {
	match (a) {
	case let a: *block =>
		a.finish(a);
	case let a: *stream =>
		a.finish(a);
	};
};
