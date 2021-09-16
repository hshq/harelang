use errors;

// Copies data from one stream into another. Note that this function will never
// return if the source stream is infinite.
export fn copy(dest: *stream, src: *stream) (error | size) = {
	match (dest.copier) {
		case null => void;
		case c: *copier =>
			match (c(dest, src)) {
			case err: error =>
				match (err) {
				case errors::unsupported => void; // Use fallback
				case =>
					return err;
				};
			case s: size =>
				return s;
			};
	};

	let w = 0z;
	static let buf: [4096]u8 = [0...];
	for (true) {
		match (read(src, buf[..])?) {
		case n: size =>
			for (let i = 0z; i < n) {
				let r = write(dest, buf[i..n])?;
				w += r;
				i += r;
			};
		case EOF =>
			break;
		};
	};
	return w;
};
