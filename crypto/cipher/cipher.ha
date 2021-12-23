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
