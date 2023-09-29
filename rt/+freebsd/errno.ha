// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Represents an error returned from the FreeBSD kernel.
export type errno = !int;

// Checks the return value from a FreeBSD syscall and, if found to be in error,
// returns the appropriate error. Otherwise, returns the original value.
fn wrap_return(r: u64) (errno | u64) = {
	if (r > -4096: u64) {
		return (-(r: i64)): errno;
	};
	return r;
};

// Obtains a human-friendly reading of an [[errno]] (e.g. "Operation not
// permitted"). The return value may be statically allocated.
export fn strerror(err: errno) str = {
	switch (err) {
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
	case EAGAIN =>
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
	case EOPNOTSUPP =>
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
		return unknown_errno(err);
	};
};

// Gets the programmer-friendly name for an [[errno]] (e.g. EPERM). The return
// value may be statically allocated.
export fn errname(err: errno) str = {
	switch (err) {
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
		return unknown_errno(err);
	};
};

export def EPERM: errno = 1;
export def ENOENT: errno = 2;
export def ESRCH: errno = 3;
export def EINTR: errno = 4;
export def EIO: errno = 5;
export def ENXIO: errno = 6;
export def E2BIG: errno = 7;
export def ENOEXEC: errno = 8;
export def EBADF: errno = 9;
export def ECHILD: errno = 10;
export def EDEADLK: errno = 11;
export def ENOMEM: errno = 12;
export def EACCES: errno = 13;
export def EFAULT: errno = 14;
export def ENOTBLK: errno = 15;
export def EBUSY: errno = 16;
export def EEXIST: errno = 17;
export def EXDEV: errno = 18;
export def ENODEV: errno = 19;
export def ENOTDIR: errno = 20;
export def EISDIR: errno = 21;
export def EINVAL: errno = 22;
export def ENFILE: errno = 23;
export def EMFILE: errno = 24;
export def ENOTTY: errno = 25;
export def ETXTBSY: errno = 26;
export def EFBIG: errno = 27;
export def ENOSPC: errno = 28;
export def ESPIPE: errno = 29;
export def EROFS: errno = 30;
export def EMLINK: errno = 31;
export def EPIPE: errno = 32;
export def EDOM: errno = 33;
export def ERANGE: errno = 34;
export def EAGAIN: errno = 35;
export def EWOULDBLOCK: errno = EAGAIN;
export def EINPROGRESS: errno = 36;
export def EALREADY: errno = 37;
export def ENOTSOCK: errno = 38;
export def EDESTADDRREQ: errno = 39;
export def EMSGSIZE: errno = 40;
export def EPROTOTYPE: errno = 41;
export def ENOPROTOOPT: errno = 42;
export def EPROTONOSUPPORT: errno = 43;
export def ESOCKTNOSUPPORT: errno = 44;
export def EOPNOTSUPP: errno = 45;
export def ENOTSUP: errno = EOPNOTSUPP;
export def EPFNOSUPPORT: errno = 46;
export def EAFNOSUPPORT: errno = 47;
export def EADDRINUSE: errno = 48;
export def EADDRNOTAVAIL: errno = 49;
export def ENETDOWN: errno = 50;
export def ENETUNREACH: errno = 51;
export def ENETRESET: errno = 52;
export def ECONNABORTED: errno = 53;
export def ECONNRESET: errno = 54;
export def ENOBUFS: errno = 55;
export def EISCONN: errno = 56;
export def ENOTCONN: errno = 57;
export def ESHUTDOWN: errno = 58;
export def ETOOMANYREFS: errno = 59;
export def ETIMEDOUT: errno = 60;
export def ECONNREFUSED: errno = 61;
export def ELOOP: errno = 62;
export def ENAMETOOLONG: errno = 63;
export def EHOSTDOWN: errno = 64;
export def EHOSTUNREACH: errno = 65;
export def ENOTEMPTY: errno = 66;
export def EPROCLIM: errno = 67;
export def EUSERS: errno = 68;
export def EDQUOT: errno = 69;
export def ESTALE: errno = 70;
export def EREMOTE: errno = 71;
export def EBADRPC: errno = 72;
export def ERPCMISMATCH: errno = 73;
export def EPROGUNAVAIL: errno = 74;
export def EPROGMISMATCH: errno = 75;
export def EPROCUNAVAIL: errno = 76;
export def ENOLCK: errno = 77;
export def ENOSYS: errno = 78;
export def EFTYPE: errno = 79;
export def EAUTH: errno = 80;
export def ENEEDAUTH: errno = 81;
export def EIDRM: errno = 82;
export def ENOMSG: errno = 83;
export def EOVERFLOW: errno = 84;
export def ECANCELED: errno = 85;
export def EILSEQ: errno = 86;
export def ENOATTR: errno = 87;
export def EDOOFUS: errno = 88;
export def EBADMSG: errno = 89;
export def EMULTIHOP: errno = 90;
export def ENOLINK: errno = 91;
export def EPROTO: errno = 92;
export def ENOTCAPABLE: errno = 93;
export def ECAPMODE: errno = 94;
export def ENOTRECOVERABLE: errno = 95;
export def EOWNERDEAD: errno = 96;
export def EINTEGRITY: errno = 97;
