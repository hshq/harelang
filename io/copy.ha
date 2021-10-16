use errors;

// Copies data from one handle into another. Note that this function will never
// return if the source handle is infinite.
export fn copy(dest: handle, src: handle) (error | size) = {
	match (dest) {
	case fd: file =>
		if (src is file) {
			return fd_copy(fd, src as file);
		};
		return copy_fallback(dest, src);
	case st: *stream =>
		if (!(src is *stream)) {
			return copy_fallback(dest, src);
		};
		return copy_streams(st, src as *stream);
	};
};

fn copy_streams(dest: *stream, src: *stream) (error | size) = {
	match (dest.copier) {
		case null => void;
		case c: *copier =>
			match (c(dest, src)) {
			case err: error =>
				match (err) {
				case errors::unsupported => void;
				case =>
					return err;
				};
			case s: size =>
				return s;
			};
	};
	return copy_fallback(dest, src);
};

fn copy_fallback(dest: handle, src: handle) (error | size) = {
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
