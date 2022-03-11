// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

// Represents an error returned from the FreeBSD kernel.
export type errno = !int;

// Given an integer error number, wraps it in an error type.
export fn wrap_errno(err: int) errno = err: errno;

// Checks the return value from a FreeBSD syscall and, if found to be in error,
// returns the appropriate error. Otherwise, returns the original value.
fn wrap_return(r: u64) (errno | u64) = {
	if (r > -4096: u64) {
		return (-(r: i64)): int: errno;
	};
	return r;
};

// Obtains a human-friendly reading of an [[errno]] (e.g. "Operation not
// permitted").
export fn strerror(err: errno) str = {
	switch (err: int) {
	case EPERM =>
		return "Operation not permitted";
	case ENOENT =>
		return "No such file or directory";
	case ESRCH =>
		return "No such process";
	case EINTR =>
		return "Interrupted system call";
	case EIO =>
		return "Input/output error";
	case ENXIO =>
		return "No such device or address";
	case E2BIG =>
		return "Argument list too long";
	case ENOEXEC =>
		return "Exec format error";
	case EBADF =>
		return "Bad file descriptor";
	case ECHILD =>
		return "No child processes";
	case EAGAIN, EWOULDBLOCK =>
		return "Resource temporarily unavailable";
	case ENOMEM =>
		return "Cannot allocate memory";
	case EACCES =>
		return "Permission denied";
	case EFAULT =>
		return "Bad address";
	case ENOTBLK =>
		return "Block device required";
	case EBUSY =>
		return "Device or resource busy";
	case EEXIST =>
		return "File exists";
	case EXDEV =>
		return "Invalid cross-device link";
	case ENODEV =>
		return "No such device";
	case ENOTDIR =>
		return "Not a directory";
	case EISDIR =>
		return "Is a directory";
	case EINVAL =>
		return "Invalid argument";
	case ENFILE =>
		return "Too many open files in system";
	case EMFILE =>
		return "Too many open files";
	case ENOTTY =>
		return "Inappropriate ioctl for device";
	case ETXTBSY =>
		return "Text file busy";
	case EFBIG =>
		return "File too large";
	case ENOSPC =>
		return "No space left on device";
	case ESPIPE =>
		return "Illegal seek";
	case EROFS =>
		return "Read-only file system";
	case EMLINK =>
		return "Too many links";
	case EPIPE =>
		return "Broken pipe";
	case EDOM =>
		return "Numerical argument out of domain";
	case ERANGE =>
		return "Numerical result out of range";
	case EDEADLK =>
		return "Resource deadlock avoided";
	case ENAMETOOLONG =>
		return "File name too long";
	case ENOLCK =>
		return "No locks available";
	case ENOSYS =>
		return "Function not implemented";
	case ENOTEMPTY =>
		return "Directory not empty";
	case ELOOP =>
		return "Too many levels of symbolic links";
	case ENOMSG =>
		return "No message of desired type";
	case EIDRM =>
		return "Identifier removed";
	case ETIME =>
		return "Timer expired";
	case EREMOTE =>
		return "Object is remote";
	case ENOLINK =>
		return "Link has been severed";
	case EPROTO =>
		return "Protocol error";
	case EMULTIHOP =>
		return "Multihop attempted";
	case EBADMSG =>
		return "Bad message";
	case EOVERFLOW =>
		return "Value too large for defined data type";
	case EILSEQ =>
		return "Invalid or incomplete multibyte or wide character";
	case EUSERS =>
		return "Too many users";
	case ENOTSOCK =>
		return "Socket operation on non-socket";
	case EDESTADDRREQ =>
		return "Destination address required";
	case EMSGSIZE =>
		return "Message too long";
	case EPROTOTYPE =>
		return "Protocol wrong type for socket";
	case ENOPROTOOPT =>
		return "Protocol not available";
	case EPROTONOSUPPORT =>
		return "Protocol not supported";
	case ESOCKTNOSUPPORT =>
		return "Socket type not supported";
	case ENOTSUP, EOPNOTSUPP =>
		return "Operation not supported";
	case EPFNOSUPPORT =>
		return "Protocol family not supported";
	case EAFNOSUPPORT =>
		return "Address family not supported by protocol";
	case EADDRINUSE =>
		return "Address already in use";
	case EADDRNOTAVAIL =>
		return "Cannot assign requested address";
	case ENETDOWN =>
		return "Network is down";
	case ENETUNREACH =>
		return "Network is unreachable";
	case ENETRESET =>
		return "Network dropped connection on reset";
	case ECONNABORTED =>
		return "Software caused connection abort";
	case ECONNRESET =>
		return "Connection reset by peer";
	case ENOBUFS =>
		return "No buffer space available";
	case EISCONN =>
		return "Transport endpoint is already connected";
	case ENOTCONN =>
		return "Transport endpoint is not connected";
	case ESHUTDOWN =>
		return "Cannot send after transport endpoint shutdown";
	case ETOOMANYREFS =>
		return "Too many references: cannot splice";
	case ETIMEDOUT =>
		return "Connection timed out";
	case ECONNREFUSED =>
		return "Connection refused";
	case EHOSTDOWN =>
		return "Host is down";
	case EHOSTUNREACH =>
		return "No route to host";
	case EALREADY =>
		return "Operation already in progress";
	case EINPROGRESS =>
		return "Operation now in progress";
	case ESTALE =>
		return "Stale file handle";
	case EDQUOT =>
		return "Disk quota exceeded";
	case ECANCELED =>
		return "Operation canceled";
	case EOWNERDEAD =>
		return "Owner died";
	case ENOTRECOVERABLE =>
		return "State not recoverable";
	case EAUTH =>
		return "Authentication error";
	case EBADRPC =>
		return "RPC struct is bad";
	case ECAPMODE =>
		return "Not permitted in capability mode";
	case EDOOFUS =>
		return "Programming error";
	case EINTEGRITY =>
		return "Integrity check failed";
	case ENEEDAUTH =>
		return "Need authenticator";
	case ENOATTR =>
		return "Attribute not found";
	case ENOTCAPABLE =>
		return "Capabilities insufficient";
	case EPROCLIM =>
		return "Too many processes";
	case EPROCUNAVAIL =>
		return "Bad procedure for program";
	case EPROGMISMATCH =>
		return "Program version wrong";
	case EPROGUNAVAIL =>
		return "RPC program not available";
	case ERPCMISMATCH =>
		return "RPC version wrong";
	case =>
		return "[unknown errno]"; // TODO: snprintf to add errno?
	};
};

// Gets the programmer-friendly name for an [[errno]] (e.g. EPERM).
export fn errname(err: errno) str = {
	switch (err: int) {
	case EPERM =>
		return "EPERM";
	case ENOENT =>
		return "ENOENT";
	case ESRCH =>
		return "ESRCH";
	case EINTR =>
		return "EINTR";
	case EIO =>
		return "EIO";
	case ENXIO =>
		return "ENXIO";
	case E2BIG =>
		return "E2BIG";
	case ENOEXEC =>
		return "ENOEXEC";
	case EBADF =>
		return "EBADF";
	case ECHILD =>
		return "ECHILD";
	case EAGAIN =>
		return "EAGAIN";
	case EWOULDBLOCK =>
		return "EWOULDBLOCK";
	case ENOMEM =>
		return "ENOMEM";
	case EACCES =>
		return "EACCES";
	case EFAULT =>
		return "EFAULT";
	case ENOTBLK =>
		return "ENOTBLK";
	case EBUSY =>
		return "EBUSY";
	case EEXIST =>
		return "EEXIST";
	case EXDEV =>
		return "EXDEV";
	case ENODEV =>
		return "ENODEV";
	case ENOTDIR =>
		return "ENOTDIR";
	case EISDIR =>
		return "EISDIR";
	case EINVAL =>
		return "EINVAL";
	case ENFILE =>
		return "ENFILE";
	case EMFILE =>
		return "EMFILE";
	case ENOTTY =>
		return "ENOTTY";
	case ETXTBSY =>
		return "ETXTBSY";
	case EFBIG =>
		return "EFBIG";
	case ENOSPC =>
		return "ENOSPC";
	case ESPIPE =>
		return "ESPIPE";
	case EROFS =>
		return "EROFS";
	case EMLINK =>
		return "EMLINK";
	case EPIPE =>
		return "EPIPE";
	case EDOM =>
		return "EDOM";
	case ERANGE =>
		return "ERANGE";
	case EDEADLK =>
		return "EDEADLK";
	case ENAMETOOLONG =>
		return "ENAMETOOLONG";
	case ENOLCK =>
		return "ENOLCK";
	case ENOSYS =>
		return "ENOSYS";
	case ENOTEMPTY =>
		return "ENOTEMPTY";
	case ELOOP =>
		return "ELOOP";
	case ENOMSG =>
		return "ENOMSG";
	case EIDRM =>
		return "EIDRM";
	case ETIME =>
		return "ETIME";
	case EREMOTE =>
		return "EREMOTE";
	case ENOLINK =>
		return "ENOLINK";
	case EPROTO =>
		return "EPROTO";
	case EMULTIHOP =>
		return "EMULTIHOP";
	case EBADMSG =>
		return "EBADMSG";
	case EOVERFLOW =>
		return "EOVERFLOW";
	case EILSEQ =>
		return "EILSEQ";
	case EUSERS =>
		return "EUSERS";
	case ENOTSOCK =>
		return "ENOTSOCK";
	case EDESTADDRREQ =>
		return "EDESTADDRREQ";
	case EMSGSIZE =>
		return "EMSGSIZE";
	case EPROTOTYPE =>
		return "EPROTOTYPE";
	case ENOPROTOOPT =>
		return "ENOPROTOOPT";
	case EPROTONOSUPPORT =>
		return "EPROTONOSUPPORT";
	case ESOCKTNOSUPPORT =>
		return "ESOCKTNOSUPPORT";
	case ENOTSUP =>
		return "ENOTSUP";
	case EOPNOTSUPP =>
		return "EOPNOTSUPP";
	case EPFNOSUPPORT =>
		return "EPFNOSUPPORT";
	case EAFNOSUPPORT =>
		return "EAFNOSUPPORT";
	case EADDRINUSE =>
		return "EADDRINUSE";
	case EADDRNOTAVAIL =>
		return "EADDRNOTAVAIL";
	case ENETDOWN =>
		return "ENETDOWN";
	case ENETUNREACH =>
		return "ENETUNREACH";
	case ENETRESET =>
		return "ENETRESET";
	case ECONNABORTED =>
		return "ECONNABORTED";
	case ECONNRESET =>
		return "ECONNRESET";
	case ENOBUFS =>
		return "ENOBUFS";
	case EISCONN =>
		return "EISCONN";
	case ENOTCONN =>
		return "ENOTCONN";
	case ESHUTDOWN =>
		return "ESHUTDOWN";
	case ETOOMANYREFS =>
		return "ETOOMANYREFS";
	case ETIMEDOUT =>
		return "ETIMEDOUT";
	case ECONNREFUSED =>
		return "ECONNREFUSED";
	case EHOSTDOWN =>
		return "EHOSTDOWN";
	case EHOSTUNREACH =>
		return "EHOSTUNREACH";
	case EALREADY =>
		return "EALREADY";
	case EINPROGRESS =>
		return "EINPROGRESS";
	case ESTALE =>
		return "ESTALE";
	case EDQUOT =>
		return "EDQUOT";
	case ECANCELED =>
		return "ECANCELED";
	case EOWNERDEAD =>
		return "EOWNERDEAD";
	case ENOTRECOVERABLE =>
		return "ENOTRECOVERABLE";
	case EAUTH =>
		return "EAUTH";
	case EBADRPC =>
		return "EBADRPC";
	case ECAPMODE =>
		return "ECAPMODE";
	case EDOOFUS =>
		return "EDOOFUS";
	case EINTEGRITY =>
		return "EINTEGRITY";
	case ENEEDAUTH =>
		return "ENEEDAUTH";
	case ENOATTR =>
		return "ENOATTR";
	case ENOTCAPABLE =>
		return "ENOTCAPABLE";
	case EPROCLIM =>
		return "EPROCLIM";
	case EPROCUNAVAIL =>
		return "EPROCUNAVAIL";
	case EPROGMISMATCH =>
		return "EPROGMISMATCH";
	case EPROGUNAVAIL =>
		return "EPROGUNAVAIL";
	case ERPCMISMATCH =>
		return "ERPCMISMATCH";
	case =>
		return "[unknown errno]"; // TODO: snprintf to add errno?
	};
};

export def EPERM: int = 1;
export def ENOENT: int = 2;
export def ESRCH: int = 3;
export def EINTR: int = 4;
export def EIO: int = 5;
export def ENXIO: int = 6;
export def E2BIG: int = 7;
export def ENOEXEC: int = 8;
export def EBADF: int = 9;
export def ECHILD: int = 10;
export def EDEADLK: int = 11;
export def ENOMEM: int = 12;
export def EACCES: int = 13;
export def EFAULT: int = 14;
export def ENOTBLK: int = 15;
export def EBUSY: int = 16;
export def EEXIST: int = 17;
export def EXDEV: int = 18;
export def ENODEV: int = 19;
export def ENOTDIR: int = 20;
export def EISDIR: int = 21;
export def EINVAL: int = 22;
export def ENFILE: int = 23;
export def EMFILE: int = 24;
export def ENOTTY: int = 25;
export def ETXTBSY: int = 26;
export def EFBIG: int = 27;
export def ENOSPC: int = 28;
export def ESPIPE: int = 29;
export def EROFS: int = 30;
export def EMLINK: int = 31;
export def EPIPE: int = 32;
export def EDOM: int = 33;
export def ERANGE: int = 34;
export def EAGAIN: int = 35;
export def EWOULDBLOCK: int = EAGAIN;
export def EINPROGRESS: int = 36;
export def EALREADY: int = 37;
export def ENOTSOCK: int = 38;
export def EDESTADDRREQ: int = 39;
export def EMSGSIZE: int = 40;
export def EPROTOTYPE: int = 41;
export def ENOPROTOOPT: int = 42;
export def EPROTONOSUPPORT: int = 43;
export def ESOCKTNOSUPPORT: int = 44;
export def EOPNOTSUPP: int = 45;
export def ENOTSUP: int = EOPNOTSUPP;
export def EPFNOSUPPORT: int = 46;
export def EAFNOSUPPORT: int = 47;
export def EADDRINUSE: int = 48;
export def EADDRNOTAVAIL: int = 49;
export def ENETDOWN: int = 50;
export def ENETUNREACH: int = 51;
export def ENETRESET: int = 52;
export def ECONNABORTED: int = 53;
export def ECONNRESET: int = 54;
export def ENOBUFS: int = 55;
export def EISCONN: int = 56;
export def ENOTCONN: int = 57;
export def ESHUTDOWN: int = 58;
export def ETOOMANYREFS: int = 59;
export def ETIMEDOUT: int = 60;
export def ETIME: int = ETIMEDOUT;
export def ECONNREFUSED: int = 61;
export def ELOOP: int = 62;
export def ENAMETOOLONG: int = 63;
export def EHOSTDOWN: int = 64;
export def EHOSTUNREACH: int = 65;
export def ENOTEMPTY: int = 66;
export def EPROCLIM: int = 67;
export def EUSERS: int = 68;
export def EDQUOT: int = 69;
export def ESTALE: int = 70;
export def EREMOTE: int = 71;
export def EBADRPC: int = 72;
export def ERPCMISMATCH: int = 73;
export def EPROGUNAVAIL: int = 74;
export def EPROGMISMATCH: int = 75;
export def EPROCUNAVAIL: int = 76;
export def ENOLCK: int = 77;
export def ENOSYS: int = 78;
export def EFTYPE: int = 79;
export def EAUTH: int = 80;
export def ENEEDAUTH: int = 81;
export def EIDRM: int = 82;
export def ENOMSG: int = 83;
export def EOVERFLOW: int = 84;
export def ECANCELED: int = 85;
export def EILSEQ: int = 86;
export def ENOATTR: int = 87;
export def EDOOFUS: int = 88;
export def EBADMSG: int = 89;
export def EMULTIHOP: int = 90;
export def ENOLINK: int = 91;
export def EPROTO: int = 92;
export def ENOTCAPABLE: int = 93;
export def ECAPMODE: int = 94;
export def ENOTRECOVERABLE: int = 95;
export def EOWNERDEAD: int = 96;
export def EINTEGRITY: int = 97;
