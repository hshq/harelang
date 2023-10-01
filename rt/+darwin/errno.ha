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

fn get_c_errno() errno;
fn set_c_errno(err: errno) void;

fn wrap_errno_return(r: i64) (errno | i64) = {
	return if (r == -1) get_c_errno() else r;
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
		return "Device not configured";
	case E2BIG =>
		return "Argument list too long";
	case ENOEXEC =>
		return "Exec format error";
	case EBADF =>
		return "Bad file descriptor";
	case ECHILD =>
		return "No child processes";
	case EDEADLK =>
		return "Resource deadlock avoided";
	case ENOMEM =>
		return "Cannot allocate memory";
	case EACCES =>
		return "Permission denied";
	case EFAULT =>
		return "Bad address";
	case ENOTBLK =>
		return "Block device required";
	case EBUSY =>
		return "Device / Resource busy";
	case EEXIST =>
		return "File exists";
	case EXDEV =>
		return "Cross-device link";
	case ENODEV =>
		return "Operation not supported by device";
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
		return "Result too large";
	case EAGAIN =>
		return "Resource temporarily unavailable";
	// case EWOULDBLOCK =>
	// 	return "Operation would block";
	case EINPROGRESS =>
		return "Operation now in progress";
	case EALREADY =>
		return "Operation already in progress";
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
	case ENOTSUP =>
		return "Operation not supported";
	// case EOPNOTSUPP =>
	// 	return "Operation not supported on socket";
	case EPFNOSUPPORT =>
		return "Protocol family not supported";
	case EAFNOSUPPORT =>
		return "Address family not supported by protocol family";
	case EADDRINUSE =>
		return "Address already in use";
	case EADDRNOTAVAIL =>
		return "Can't assign requested address";
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
		return "Socket is already connected";
	case ENOTCONN =>
		return "Socket is not connected";
	case ESHUTDOWN =>
		return "Can't send after socket shutdown";
	case ETOOMANYREFS =>
		return "Too many references: can't splice";
	case ETIMEDOUT =>
		return "Operation timed out";
	case ECONNREFUSED =>
		return "Connection refused";
	case ELOOP =>
		return "Too many levels of symbolic links";
	case ENAMETOOLONG =>
		return "File name too long";
	case EHOSTDOWN =>
		return "Host is down";
	case EHOSTUNREACH =>
		return "No route to host";
	case ENOTEMPTY =>
		return "Directory not empty";
	case EPROCLIM =>
		return "Too many processes";
	case EUSERS =>
		return "Too many users";
	case EDQUOT =>
		return "Disc quota exceeded";
	case ESTALE =>
		return "Stale NFS file handle";
	case EREMOTE =>
		return "Too many levels of remote in path";
	case EBADRPC =>
		return "RPC struct is bad";
	case ERPCMISMATCH =>
		return "RPC version wrong";
	case EPROGUNAVAIL =>
		return "RPC prog. not avail";
	case EPROGMISMATCH =>
		return "Program version wrong";
	case EPROCUNAVAIL =>
		return "Bad procedure for program";
	case ENOLCK =>
		return "No locks available";
	case ENOSYS =>
		return "Function not implemented";
	case EFTYPE =>
		return "Inappropriate file type or format";
	case EAUTH =>
		return "Authentication error";
	case ENEEDAUTH =>
		return "Need authenticator";
	case EPWROFF =>
		return "Device power is off";
	case EDEVERR =>
		return "Device error, e.g. paper out";
	case EOVERFLOW =>
		return "Value too large to be stored in data type";
	case EBADEXEC =>
		return "Bad executable";
	case EBADARCH =>
		return "Bad CPU type in executable";
	case ESHLIBVERS =>
		return "Shared library version mismatch";
	case EBADMACHO =>
		return "Malformed Macho file";
	case ECANCELED =>
		return "Operation canceled";
	case EIDRM =>
		return "Identifier removed";
	case ENOMSG =>
		return "No message of desired type";
	case EILSEQ =>
		return "Illegal byte sequence";
	case ENOATTR =>
		return "Attribute not found";
	case EBADMSG =>
		return "Bad message";
	case EMULTIHOP =>
		return "Reserved";
	case ENODATA =>
		return "No message available on STREAM";
	case ENOLINK =>
		return "Reserved";
	case ENOSR =>
		return "No STREAM resources";
	case ENOSTR =>
		return "Not a STREAM";
	case EPROTO =>
		return "Protocol error";
	case ETIME =>
		return "STREAM ioctl timeout";
	case EOPNOTSUPP =>
		return "Operation not supported on socket";
	case ENOPOLICY =>
		return "No such policy registered";
	case ENOTRECOVERABLE =>
		return "State not recoverable";
	case EOWNERDEAD =>
		return "Previous owner died";
	case EQFULL =>
		return "Interface output queue is full";
	// case ELAST =>
	// 	return "Must be equal largest errno";
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
	case EDEADLK =>
		return "EDEADLK";
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
	case EAGAIN =>
		return "EAGAIN";
	// case EWOULDBLOCK =>
	// 	return "EWOULDBLOCK";
	case EINPROGRESS =>
		return "EINPROGRESS";
	case EALREADY =>
		return "EALREADY";
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
	// case EOPNOTSUPP =>
	// 	return "EOPNOTSUPP";
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
	case ELOOP =>
		return "ELOOP";
	case ENAMETOOLONG =>
		return "ENAMETOOLONG";
	case EHOSTDOWN =>
		return "EHOSTDOWN";
	case EHOSTUNREACH =>
		return "EHOSTUNREACH";
	case ENOTEMPTY =>
		return "ENOTEMPTY";
	case EPROCLIM =>
		return "EPROCLIM";
	case EUSERS =>
		return "EUSERS";
	case EDQUOT =>
		return "EDQUOT";
	case ESTALE =>
		return "ESTALE";
	case EREMOTE =>
		return "EREMOTE";
	case EBADRPC =>
		return "EBADRPC";
	case ERPCMISMATCH =>
		return "ERPCMISMATCH";
	case EPROGUNAVAIL =>
		return "EPROGUNAVAIL";
	case EPROGMISMATCH =>
		return "EPROGMISMATCH";
	case EPROCUNAVAIL =>
		return "EPROCUNAVAIL";
	case ENOLCK =>
		return "ENOLCK";
	case ENOSYS =>
		return "ENOSYS";
	case EFTYPE =>
		return "EFTYPE";
	case EAUTH =>
		return "EAUTH";
	case ENEEDAUTH =>
		return "ENEEDAUTH";
	case EPWROFF =>
		return "EPWROFF";
	case EDEVERR =>
		return "EDEVERR";
	case EOVERFLOW =>
		return "EOVERFLOW";
	case EBADEXEC =>
		return "EBADEXEC";
	case EBADARCH =>
		return "EBADARCH";
	case ESHLIBVERS =>
		return "ESHLIBVERS";
	case EBADMACHO =>
		return "EBADMACHO";
	case ECANCELED =>
		return "ECANCELED";
	case EIDRM =>
		return "EIDRM";
	case ENOMSG =>
		return "ENOMSG";
	case EILSEQ =>
		return "EILSEQ";
	case ENOATTR =>
		return "ENOATTR";
	case EBADMSG =>
		return "EBADMSG";
	case EMULTIHOP =>
		return "EMULTIHOP";
	case ENODATA =>
		return "ENODATA";
	case ENOLINK =>
		return "ENOLINK";
	case ENOSR =>
		return "ENOSR";
	case ENOSTR =>
		return "ENOSTR";
	case EPROTO =>
		return "EPROTO";
	case ETIME =>
		return "ETIME";
	case EOPNOTSUPP =>
		return "EOPNOTSUPP";
	case ENOPOLICY =>
		return "ENOPOLICY";
	case ENOTRECOVERABLE =>
		return "ENOTRECOVERABLE";
	case EOWNERDEAD =>
		return "EOWNERDEAD";
	case EQFULL =>
		return "EQFULL";
	// case ELAST =>
	// 	return "ELAST";
	case =>
		return unknown_errno(err);
	};
};

export def EPERM: errno           = 1;       // Operation not permitted
export def ENOENT: errno          = 2;       // No such file or directory
export def ESRCH: errno           = 3;       // No such process
export def EINTR: errno           = 4;       // Interrupted system call
export def EIO: errno             = 5;       // Input/output error
export def ENXIO: errno           = 6;       // Device not configured
export def E2BIG: errno           = 7;       // Argument list too long
export def ENOEXEC: errno         = 8;       // Exec format error
export def EBADF: errno           = 9;       // Bad file descriptor
export def ECHILD: errno          = 10;      // No child processes
export def EDEADLK: errno         = 11;      // Resource deadlock avoided
            // 11 was EAGAIN
export def ENOMEM: errno          = 12;      // Cannot allocate memory
export def EACCES: errno          = 13;      // Permission denied
export def EFAULT: errno          = 14;      // Bad address
export def ENOTBLK: errno         = 15;      // Block device required
export def EBUSY: errno           = 16;      // Device / Resource busy
export def EEXIST: errno          = 17;      // File exists
export def EXDEV: errno           = 18;      // Cross-device link
export def ENODEV: errno          = 19;      // Operation not supported by device
export def ENOTDIR: errno         = 20;      // Not a directory
export def EISDIR: errno          = 21;      // Is a directory
export def EINVAL: errno          = 22;      // Invalid argument
export def ENFILE: errno          = 23;      // Too many open files in system
export def EMFILE: errno          = 24;      // Too many open files
export def ENOTTY: errno          = 25;      // Inappropriate ioctl for device
export def ETXTBSY: errno         = 26;      // Text file busy
export def EFBIG: errno           = 27;      // File too large
export def ENOSPC: errno          = 28;      // No space left on device
export def ESPIPE: errno          = 29;      // Illegal seek
export def EROFS: errno           = 30;      // Read-only file system
export def EMLINK: errno          = 31;      // Too many links
export def EPIPE: errno           = 32;      // Broken pipe

// math software
export def EDOM: errno            = 33;      // Numerical argument out of domain
export def ERANGE: errno          = 34;      // Result too large

// non-blocking and interrupt i/o
export def EAGAIN: errno          = 35;      // Resource temporarily unavailable
export def EWOULDBLOCK: errno     = EAGAIN;  // Operation would block
export def EINPROGRESS: errno     = 36;      // Operation now in progress
export def EALREADY: errno        = 37;      // Operation already in progress

// ipc/network software -- argument errors
export def ENOTSOCK: errno        = 38;      // Socket operation on non-socket
export def EDESTADDRREQ: errno    = 39;      // Destination address required
export def EMSGSIZE: errno        = 40;      // Message too long
export def EPROTOTYPE: errno      = 41;      // Protocol wrong type for socket
export def ENOPROTOOPT: errno     = 42;      // Protocol not available
export def EPROTONOSUPPORT: errno = 43;      // Protocol not supported
export def ESOCKTNOSUPPORT: errno = 44;      // Socket type not supported
export def ENOTSUP: errno         = 45;      // Operation not supported
// export def EOPNOTSUPP: errno      = ENOTSUP; // Operation not supported on socket

export def EPFNOSUPPORT: errno    = 46;      // Protocol family not supported
export def EAFNOSUPPORT: errno    = 47;      // Address family not supported by protocol family
export def EADDRINUSE: errno      = 48;      // Address already in use
export def EADDRNOTAVAIL: errno   = 49;      // Can't assign requested address

// ipc/network software -- operational errors
export def ENETDOWN: errno        = 50;      // Network is down
export def ENETUNREACH: errno     = 51;      // Network is unreachable
export def ENETRESET: errno       = 52;      // Network dropped connection on reset
export def ECONNABORTED: errno    = 53;      // Software caused connection abort
export def ECONNRESET: errno      = 54;      // Connection reset by peer
export def ENOBUFS: errno         = 55;      // No buffer space available
export def EISCONN: errno         = 56;      // Socket is already connected
export def ENOTCONN: errno        = 57;      // Socket is not connected
export def ESHUTDOWN: errno       = 58;      // Can't send after socket shutdown
export def ETOOMANYREFS: errno    = 59;      // Too many references: can't splice
export def ETIMEDOUT: errno       = 60;      // Operation timed out
export def ECONNREFUSED: errno    = 61;      // Connection refused

export def ELOOP: errno           = 62;      // Too many levels of symbolic links
export def ENAMETOOLONG: errno    = 63;      // File name too long

// should be rearranged
export def EHOSTDOWN: errno       = 64;      // Host is down
export def EHOSTUNREACH: errno    = 65;      // No route to host
export def ENOTEMPTY: errno       = 66;      // Directory not empty

// quotas & mush
export def EPROCLIM: errno        = 67;      // Too many processes
export def EUSERS: errno          = 68;      // Too many users
export def EDQUOT: errno          = 69;      // Disc quota exceeded

// Network File System
export def ESTALE: errno          = 70;      // Stale NFS file handle
export def EREMOTE: errno         = 71;      // Too many levels of remote in path
export def EBADRPC: errno         = 72;      // RPC struct is bad
export def ERPCMISMATCH: errno    = 73;      // RPC version wrong
export def EPROGUNAVAIL: errno    = 74;      // RPC prog. not avail
export def EPROGMISMATCH: errno   = 75;      // Program version wrong
export def EPROCUNAVAIL: errno    = 76;      // Bad procedure for program

export def ENOLCK: errno          = 77;      // No locks available
export def ENOSYS: errno          = 78;      // Function not implemented

export def EFTYPE: errno          = 79;      // Inappropriate file type or format
export def EAUTH: errno           = 80;      // Authentication error
export def ENEEDAUTH: errno       = 81;      // Need authenticator

// Intelligent device errors
export def EPWROFF: errno         = 82;      // Device power is off
export def EDEVERR: errno         = 83;      // Device error, e.g. paper out

export def EOVERFLOW: errno       = 84;      // Value too large to be stored in data type

// Program loading errors
export def EBADEXEC: errno        = 85;      // Bad executable
export def EBADARCH: errno        = 86;      // Bad CPU type in executable
export def ESHLIBVERS: errno      = 87;      // Shared library version mismatch
export def EBADMACHO: errno       = 88;      // Malformed Macho file

export def ECANCELED: errno       = 89;      // Operation canceled

export def EIDRM: errno           = 90;      // Identifier removed
export def ENOMSG: errno          = 91;      // No message of desired type
export def EILSEQ: errno          = 92;      // Illegal byte sequence
export def ENOATTR: errno         = 93;      // Attribute not found

export def EBADMSG: errno         = 94;      // Bad message
export def EMULTIHOP: errno       = 95;      // Reserved
export def ENODATA: errno         = 96;      // No message available on STREAM
export def ENOLINK: errno         = 97;      // Reserved
export def ENOSR: errno           = 98;      // No STREAM resources
export def ENOSTR: errno          = 99;      // Not a STREAM
export def EPROTO: errno          = 100;     // Protocol error
export def ETIME: errno           = 101;     // STREAM ioctl timeout

export def EOPNOTSUPP: errno      = 102;     // Operation not supported on socket

export def ENOPOLICY: errno       = 103;     // No such policy registered

export def ENOTRECOVERABLE: errno = 104;     // State not recoverable
export def EOWNERDEAD: errno      = 105;     // Previous owner died

export def EQFULL: errno          = 106;     // Interface output queue is full
export def ELAST: errno           = 106;     // Must be equal largest errno
