// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Represents an error returned from the Linux kernel.
export type errno = !int;

// Checks the return value from a Linux syscall and, if found to be in error,
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
	case ECHRNG =>
		return "Channel number out of range";
	case EL2NSYNC =>
		return "Level 2 not synchronized";
	case EL3HLT =>
		return "Level 3 halted";
	case EL3RST =>
		return "Level 3 reset";
	case ELNRNG =>
		return "Link number out of range";
	case EUNATCH =>
		return "Protocol driver not attached";
	case ENOCSI =>
		return "No CSI structure available";
	case EL2HLT =>
		return "Level 2 halted";
	case EBADE =>
		return "Invalid exchange";
	case EBADR =>
		return "Invalid request descriptor";
	case EXFULL =>
		return "Exchange full";
	case ENOANO =>
		return "No anode";
	case EBADRQC =>
		return "Invalid request code";
	case EBADSLT =>
		return "Invalid slot";
	case EBFONT =>
		return "Bad font file format";
	case ENOSTR =>
		return "Device not a stream";
	case ENODATA =>
		return "No data available";
	case ETIME =>
		return "Timer expired";
	case ENOSR =>
		return "Out of streams resources";
	case ENONET =>
		return "Machine is not on the network";
	case ENOPKG =>
		return "Package not installed";
	case EREMOTE =>
		return "Object is remote";
	case ENOLINK =>
		return "Link has been severed";
	case EADV =>
		return "Advertise error";
	case ESRMNT =>
		return "Srmount error";
	case ECOMM =>
		return "Communication error on send";
	case EPROTO =>
		return "Protocol error";
	case EMULTIHOP =>
		return "Multihop attempted";
	case EDOTDOT =>
		return "RFS specific error";
	case EBADMSG =>
		return "Bad message";
	case EOVERFLOW =>
		return "Value too large for defined data type";
	case ENOTUNIQ =>
		return "Name not unique on network";
	case EBADFD =>
		return "File descriptor in bad state";
	case EREMCHG =>
		return "Remote address changed";
	case ELIBACC =>
		return "Can not access a needed shared library";
	case ELIBBAD =>
		return "Accessing a corrupted shared library";
	case ELIBSCN =>
		return ".lib section in a.out corrupted";
	case ELIBMAX =>
		return "Attempting to link in too many shared libraries";
	case ELIBEXEC =>
		return "Cannot exec a shared library directly";
	case EILSEQ =>
		return "Invalid or incomplete multibyte or wide character";
	case ERESTART =>
		return "Interrupted system call should be restarted";
	case ESTRPIPE =>
		return "Streams pipe error";
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
	case EUCLEAN =>
		return "Structure needs cleaning";
	case ENOTNAM =>
		return "Not a XENIX named type file";
	case ENAVAIL =>
		return "No XENIX semaphores available";
	case EISNAM =>
		return "Is a named type file";
	case EREMOTEIO =>
		return "Remote I/O error";
	case EDQUOT =>
		return "Disk quota exceeded";
	case ENOMEDIUM =>
		return "No medium found";
	case EMEDIUMTYPE =>
		return "Wrong medium type";
	case ECANCELED =>
		return "Operation canceled";
	case ENOKEY =>
		return "Required key not available";
	case EKEYEXPIRED =>
		return "Key has expired";
	case EKEYREVOKED =>
		return "Key has been revoked";
	case EKEYREJECTED =>
		return "Key was rejected by service";
	case EOWNERDEAD =>
		return "Owner died";
	case ENOTRECOVERABLE =>
		return "State not recoverable";
	case ERFKILL =>
		return "Operation not possible due to RF-kill";
	case EHWPOISON =>
		return "Memory page has hardware error";
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
	case ECHRNG =>
		return "ECHRNG";
	case EL2NSYNC =>
		return "EL2NSYNC";
	case EL3HLT =>
		return "EL3HLT";
	case EL3RST =>
		return "EL3RST";
	case ELNRNG =>
		return "ELNRNG";
	case EUNATCH =>
		return "EUNATCH";
	case ENOCSI =>
		return "ENOCSI";
	case EL2HLT =>
		return "EL2HLT";
	case EBADE =>
		return "EBADE";
	case EBADR =>
		return "EBADR";
	case EXFULL =>
		return "EXFULL";
	case ENOANO =>
		return "ENOANO";
	case EBADRQC =>
		return "EBADRQC";
	case EBADSLT =>
		return "EBADSLT";
	case EBFONT =>
		return "EBFONT";
	case ENOSTR =>
		return "ENOSTR";
	case ENODATA =>
		return "ENODATA";
	case ETIME =>
		return "ETIME";
	case ENOSR =>
		return "ENOSR";
	case ENONET =>
		return "ENONET";
	case ENOPKG =>
		return "ENOPKG";
	case EREMOTE =>
		return "EREMOTE";
	case ENOLINK =>
		return "ENOLINK";
	case EADV =>
		return "EADV";
	case ESRMNT =>
		return "ESRMNT";
	case ECOMM =>
		return "ECOMM";
	case EPROTO =>
		return "EPROTO";
	case EMULTIHOP =>
		return "EMULTIHOP";
	case EDOTDOT =>
		return "EDOTDOT";
	case EBADMSG =>
		return "EBADMSG";
	case EOVERFLOW =>
		return "EOVERFLOW";
	case ENOTUNIQ =>
		return "ENOTUNIQ";
	case EBADFD =>
		return "EBADFD";
	case EREMCHG =>
		return "EREMCHG";
	case ELIBACC =>
		return "ELIBACC";
	case ELIBBAD =>
		return "ELIBBAD";
	case ELIBSCN =>
		return "ELIBSCN";
	case ELIBMAX =>
		return "ELIBMAX";
	case ELIBEXEC =>
		return "ELIBEXEC";
	case EILSEQ =>
		return "EILSEQ";
	case ERESTART =>
		return "ERESTART";
	case ESTRPIPE =>
		return "ESTRPIPE";
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
	case EUCLEAN =>
		return "EUCLEAN";
	case ENOTNAM =>
		return "ENOTNAM";
	case ENAVAIL =>
		return "ENAVAIL";
	case EISNAM =>
		return "EISNAM";
	case EREMOTEIO =>
		return "EREMOTEIO";
	case EDQUOT =>
		return "EDQUOT";
	case ENOMEDIUM =>
		return "ENOMEDIUM";
	case EMEDIUMTYPE =>
		return "EMEDIUMTYPE";
	case ECANCELED =>
		return "ECANCELED";
	case ENOKEY =>
		return "ENOKEY";
	case EKEYEXPIRED =>
		return "EKEYEXPIRED";
	case EKEYREVOKED =>
		return "EKEYREVOKED";
	case EKEYREJECTED =>
		return "EKEYREJECTED";
	case EOWNERDEAD =>
		return "EOWNERDEAD";
	case ENOTRECOVERABLE =>
		return "ENOTRECOVERABLE";
	case ERFKILL =>
		return "ERFKILL";
	case EHWPOISON =>
		return "EHWPOISON";
	case =>
		return unknown_errno(err);
	};
};

export def EPERM: errno			= 1;
export def ENOENT: errno		= 2;
export def ESRCH: errno			= 3;
export def EINTR: errno			= 4;
export def EIO: errno			= 5;
export def ENXIO: errno			= 6;
export def E2BIG: errno			= 7;
export def ENOEXEC: errno		= 8;
export def EBADF: errno			= 9;
export def ECHILD: errno		= 10;
export def EAGAIN: errno		= 11;
export def EWOULDBLOCK: errno		= EAGAIN;
export def ENOMEM: errno		= 12;
export def EACCES: errno		= 13;
export def EFAULT: errno		= 14;
export def ENOTBLK: errno		= 15;
export def EBUSY: errno			= 16;
export def EEXIST: errno		= 17;
export def EXDEV: errno			= 18;
export def ENODEV: errno		= 19;
export def ENOTDIR: errno		= 20;
export def EISDIR: errno		= 21;
export def EINVAL: errno		= 22;
export def ENFILE: errno		= 23;
export def EMFILE: errno		= 24;
export def ENOTTY: errno		= 25;
export def ETXTBSY: errno		= 26;
export def EFBIG: errno			= 27;
export def ENOSPC: errno		= 28;
export def ESPIPE: errno		= 29;
export def EROFS: errno			= 30;
export def EMLINK: errno		= 31;
export def EPIPE: errno			= 32;
export def EDOM: errno			= 33;
export def ERANGE: errno		= 34;
export def EDEADLK: errno		= 35;
export def ENAMETOOLONG: errno		= 36;
export def ENOLCK: errno		= 37;
export def ENOSYS: errno		= 38;
export def ENOTEMPTY: errno		= 39;
export def ELOOP: errno			= 40;
export def ENOMSG: errno		= 42;
export def EIDRM: errno			= 43;
export def ECHRNG: errno		= 44;
export def EL2NSYNC: errno		= 45;
export def EL3HLT: errno		= 46;
export def EL3RST: errno		= 47;
export def ELNRNG: errno		= 48;
export def EUNATCH: errno		= 49;
export def ENOCSI: errno		= 50;
export def EL2HLT: errno		= 51;
export def EBADE: errno			= 52;
export def EBADR: errno			= 53;
export def EXFULL: errno		= 54;
export def ENOANO: errno		= 55;
export def EBADRQC: errno		= 56;
export def EBADSLT: errno		= 57;
export def EBFONT: errno		= 59;
export def ENOSTR: errno		= 60;
export def ENODATA: errno		= 61;
export def ETIME: errno			= 62;
export def ENOSR: errno			= 63;
export def ENONET: errno		= 64;
export def ENOPKG: errno		= 65;
export def EREMOTE: errno		= 66;
export def ENOLINK: errno		= 67;
export def EADV: errno			= 68;
export def ESRMNT: errno		= 69;
export def ECOMM: errno			= 70;
export def EPROTO: errno		= 71;
export def EMULTIHOP: errno		= 72;
export def EDOTDOT: errno		= 73;
export def EBADMSG: errno		= 74;
export def EOVERFLOW: errno		= 75;
export def ENOTUNIQ: errno		= 76;
export def EBADFD: errno		= 77;
export def EREMCHG: errno		= 78;
export def ELIBACC: errno		= 79;
export def ELIBBAD: errno		= 80;
export def ELIBSCN: errno		= 81;
export def ELIBMAX: errno		= 82;
export def ELIBEXEC: errno		= 83;
export def EILSEQ: errno		= 84;
export def ERESTART: errno		= 85;
export def ESTRPIPE: errno		= 86;
export def EUSERS: errno		= 87;
export def ENOTSOCK: errno		= 88;
export def EDESTADDRREQ: errno		= 89;
export def EMSGSIZE: errno		= 90;
export def EPROTOTYPE: errno		= 91;
export def ENOPROTOOPT: errno		= 92;
export def EPROTONOSUPPORT: errno	= 93;
export def ESOCKTNOSUPPORT: errno	= 94;
export def EOPNOTSUPP: errno		= 95;
export def ENOTSUP: errno		= EOPNOTSUPP;
export def EPFNOSUPPORT: errno		= 96;
export def EAFNOSUPPORT: errno		= 97;
export def EADDRINUSE: errno		= 98;
export def EADDRNOTAVAIL: errno		= 99;
export def ENETDOWN: errno		= 100;
export def ENETUNREACH: errno		= 101;
export def ENETRESET: errno		= 102;
export def ECONNABORTED: errno		= 103;
export def ECONNRESET: errno		= 104;
export def ENOBUFS: errno		= 105;
export def EISCONN: errno		= 106;
export def ENOTCONN: errno		= 107;
export def ESHUTDOWN: errno		= 108;
export def ETOOMANYREFS: errno		= 109;
export def ETIMEDOUT: errno		= 110;
export def ECONNREFUSED: errno		= 111;
export def EHOSTDOWN: errno		= 112;
export def EHOSTUNREACH: errno		= 113;
export def EALREADY: errno		= 114;
export def EINPROGRESS: errno		= 115;
export def ESTALE: errno		= 116;
export def EUCLEAN: errno		= 117;
export def ENOTNAM: errno		= 118;
export def ENAVAIL: errno		= 119;
export def EISNAM: errno		= 120;
export def EREMOTEIO: errno		= 121;
export def EDQUOT: errno		= 122;
export def ENOMEDIUM: errno		= 123;
export def EMEDIUMTYPE: errno		= 124;
export def ECANCELED: errno		= 125;
export def ENOKEY: errno		= 126;
export def EKEYEXPIRED: errno		= 127;
export def EKEYREVOKED: errno		= 128;
export def EKEYREJECTED: errno		= 129;
export def EOWNERDEAD: errno		= 130;
export def ENOTRECOVERABLE: errno	= 131;
export def ERFKILL: errno		= 132;
export def EHWPOISON: errno		= 133;
