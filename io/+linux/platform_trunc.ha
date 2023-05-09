// License: MPL-2.0
use errors;
use rt;

 fn platform_trunc(fd: file, ln: size) (void | error) = {
 	match (rt::ftruncate(fd: int, ln: rt::off_t)) {
 	case void => void;
 	case let e: rt::errno => return errors::errno(e);
 	};
 };
