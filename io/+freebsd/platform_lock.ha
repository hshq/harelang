// License: MPL-2.0
use errors;
use rt;

fn platform_lock(fd: file, flags: int) (bool | error) = {
	match (rt::flock(fd: int, flags)) {
	case void => return true;
	case let e: rt::errno =>
		if (e == rt::EWOULDBLOCK: rt::errno) {
			return false;
		} else {
			return errors::errno(e);
		};
	};
};
