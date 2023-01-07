// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use errors;

// Copies data from one handle into another. If reading from the source file
// returns zero (underread), the copy is terminated and the amount of data
// copied is returned. Note that this function will never return if the source
// handle is infinite.
export fn copy(dest: handle, src: handle) (error | size) = {
	match (dest) {
	case let fd: file =>
		if (src is file) {
			return fd_copy(fd, src as file);
		};
		return copy_fallback(dest, src);
	case let st: *stream =>
		if (!(src is *stream)) {
			return copy_fallback(dest, src);
		};
		return copy_streams(st, src as *stream);
	};
};

fn copy_streams(dest: *stream, src: *stream) (error | size) = {
	match (dest.copier) {
	case null => void;
	case let c: *copier =>
		match (c(dest, src)) {
		case let err: error =>
			match (err) {
			case errors::unsupported => void;
			case =>
				return err;
			};
		case let s: size =>
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
		case let n: size =>
			if (n == 0) {
				break;
			};
			w += writeall(dest, buf[..n])?;
		case EOF =>
			break;
		};
	};
	return w;
};
