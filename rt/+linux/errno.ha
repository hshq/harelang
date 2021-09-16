// Represents an error returned from the Linux kernel.
export type errno = !int;

// Given an integer error number, wraps it in an error type.
export fn wrap_errno(err: int) errno = err: errno;

// Checks the return value from a Linux syscall and, if found to be in error,
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
	return switch (err: int) {
	case EPERM =>
		yield "Operation not permitted";
	case ENOENT =>
		yield "No such file or directory";
	case ESRCH =>
		yield "No such process";
	case EINTR =>
		yield "Interrupted system call";
	case EIO =>
		yield "Input/output error";
	case ENXIO =>
		yield "No such device or address";
	case E2BIG =>
		yield "Argument list too long";
	case ENOEXEC =>
		yield "Exec format error";
	case EBADF =>
		yield "Bad file descriptor";
	case ECHILD =>
		yield "No child processes";
	case EAGAIN =>
		yield "Resource temporarily unavailable";
	case ENOMEM =>
		yield "Cannot allocate memory";
	case EACCES =>
		yield "Permission denied";
	case EFAULT =>
		yield "Bad address";
	case ENOTBLK =>
		yield "Block device required";
	case EBUSY =>
		yield "Device or resource busy";
	case EEXIST =>
		yield "File exists";
	case EXDEV =>
		yield "Invalid cross-device link";
	case ENODEV =>
		yield "No such device";
	case ENOTDIR =>
		yield "Not a directory";
	case EISDIR =>
		yield "Is a directory";
	case EINVAL =>
		yield "Invalid argument";
	case ENFILE =>
		yield "Too many open files in system";
	case EMFILE =>
		yield "Too many open files";
	case ENOTTY =>
		yield "Inappropriate ioctl for device";
	case ETXTBSY =>
		yield "Text file busy";
	case EFBIG =>
		yield "File too large";
	case ENOSPC =>
		yield "No space left on device";
	case ESPIPE =>
		yield "Illegal seek";
	case EROFS =>
		yield "Read-only file system";
	case EMLINK =>
		yield "Too many links";
	case EPIPE =>
		yield "Broken pipe";
	case EDOM =>
		yield "Numerical argument out of domain";
	case ERANGE =>
		yield "Numerical result out of range";
	case EDEADLK =>
		yield "Resource deadlock avoided";
	case ENAMETOOLONG =>
		yield "File name too long";
	case ENOLCK =>
		yield "No locks available";
	case ENOSYS =>
		yield "Function not implemented";
	case ENOTEMPTY =>
		yield "Directory not empty";
	case ELOOP =>
		yield "Too many levels of symbolic links";
	case ENOMSG =>
		yield "No message of desired type";
	case EIDRM =>
		yield "Identifier removed";
	case ECHRNG =>
		yield "Channel number out of range";
	case EL2NSYNC =>
		yield "Level 2 not synchronized";
	case EL3HLT =>
		yield "Level 3 halted";
	case EL3RST =>
		yield "Level 3 reset";
	case ELNRNG =>
		yield "Link number out of range";
	case EUNATCH =>
		yield "Protocol driver not attached";
	case ENOCSI =>
		yield "No CSI structure available";
	case EL2HLT =>
		yield "Level 2 halted";
	case EBADE =>
		yield "Invalid exchange";
	case EBADR =>
		yield "Invalid request descriptor";
	case EXFULL =>
		yield "Exchange full";
	case ENOANO =>
		yield "No anode";
	case EBADRQC =>
		yield "Invalid request code";
	case EBADSLT =>
		yield "Invalid slot";
	case EBFONT =>
		yield "Bad font file format";
	case ENOSTR =>
		yield "Device not a stream";
	case ENODATA =>
		yield "No data available";
	case ETIME =>
		yield "Timer expired";
	case ENOSR =>
		yield "Out of streams resources";
	case ENONET =>
		yield "Machine is not on the network";
	case ENOPKG =>
		yield "Package not installed";
	case EREMOTE =>
		yield "Object is remote";
	case ENOLINK =>
		yield "Link has been severed";
	case EADV =>
		yield "Advertise error";
	case ESRMNT =>
		yield "Srmount error";
	case ECOMM =>
		yield "Communication error on send";
	case EPROTO =>
		yield "Protocol error";
	case EMULTIHOP =>
		yield "Multihop attempted";
	case EDOTDOT =>
		yield "RFS specific error";
	case EBADMSG =>
		yield "Bad message";
	case EOVERFLOW =>
		yield "Value too large for defined data type";
	case ENOTUNIQ =>
		yield "Name not unique on network";
	case EBADFD =>
		yield "File descriptor in bad state";
	case EREMCHG =>
		yield "Remote address changed";
	case ELIBACC =>
		yield "Can not access a needed shared library";
	case ELIBBAD =>
		yield "Accessing a corrupted shared library";
	case ELIBSCN =>
		yield ".lib section in a.out corrupted";
	case ELIBMAX =>
		yield "Attempting to link in too many shared libraries";
	case ELIBEXEC =>
		yield "Cannot exec a shared library directly";
	case EILSEQ =>
		yield "Invalid or incomplete multibyte or wide character";
	case ERESTART =>
		yield "Interrupted system call should be restarted";
	case ESTRPIPE =>
		yield "Streams pipe error";
	case EUSERS =>
		yield "Too many users";
	case ENOTSOCK =>
		yield "Socket operation on non-socket";
	case EDESTADDRREQ =>
		yield "Destination address required";
	case EMSGSIZE =>
		yield "Message too long";
	case EPROTOTYPE =>
		yield "Protocol wrong type for socket";
	case ENOPROTOOPT =>
		yield "Protocol not available";
	case EPROTONOSUPPORT =>
		yield "Protocol not supported";
	case ESOCKTNOSUPPORT =>
		yield "Socket type not supported";
	case EOPNOTSUPP =>
		yield "Operation not supported";
	case EPFNOSUPPORT =>
		yield "Protocol family not supported";
	case EAFNOSUPPORT =>
		yield "Address family not supported by protocol";
	case EADDRINUSE =>
		yield "Address already in use";
	case EADDRNOTAVAIL =>
		yield "Cannot assign requested address";
	case ENETDOWN =>
		yield "Network is down";
	case ENETUNREACH =>
		yield "Network is unreachable";
	case ENETRESET =>
		yield "Network dropped connection on reset";
	case ECONNABORTED =>
		yield "Software caused connection abort";
	case ECONNRESET =>
		yield "Connection reset by peer";
	case ENOBUFS =>
		yield "No buffer space available";
	case EISCONN =>
		yield "Transport endpoint is already connected";
	case ENOTCONN =>
		yield "Transport endpoint is not connected";
	case ESHUTDOWN =>
		yield "Cannot send after transport endpoint shutdown";
	case ETOOMANYREFS =>
		yield "Too many references: cannot splice";
	case ETIMEDOUT =>
		yield "Connection timed out";
	case ECONNREFUSED =>
		yield "Connection refused";
	case EHOSTDOWN =>
		yield "Host is down";
	case EHOSTUNREACH =>
		yield "No route to host";
	case EALREADY =>
		yield "Operation already in progress";
	case EINPROGRESS =>
		yield "Operation now in progress";
	case ESTALE =>
		yield "Stale file handle";
	case EUCLEAN =>
		yield "Structure needs cleaning";
	case ENOTNAM =>
		yield "Not a XENIX named type file";
	case ENAVAIL =>
		yield "No XENIX semaphores available";
	case EISNAM =>
		yield "Is a named type file";
	case EREMOTEIO =>
		yield "Remote I/O error";
	case EDQUOT =>
		yield "Disk quota exceeded";
	case ENOMEDIUM =>
		yield "No medium found";
	case EMEDIUMTYPE =>
		yield "Wrong medium type";
	case ECANCELED =>
		yield "Operation canceled";
	case ENOKEY =>
		yield "Required key not available";
	case EKEYEXPIRED =>
		yield "Key has expired";
	case EKEYREVOKED =>
		yield "Key has been revoked";
	case EKEYREJECTED =>
		yield "Key was rejected by service";
	case EOWNERDEAD =>
		yield "Owner died";
	case ENOTRECOVERABLE =>
		yield "State not recoverable";
	case ERFKILL =>
		yield "Operation not possible due to RF-kill";
	case EHWPOISON =>
		yield "Memory page has hardware error";
	case =>
		yield "Unknown Linux error code"; // TODO: snprintf to add errno?
	};
};

// Gets the programmer-friendly name for an [[errno]] (e.g. EPERM).
export fn errname(err: errno) str = {
	return switch (err: int) {
	case EPERM =>
		yield "EPERM";
	case ENOENT =>
		yield "ENOENT";
	case ESRCH =>
		yield "ESRCH";
	case EINTR =>
		yield "EINTR";
	case EIO =>
		yield "EIO";
	case ENXIO =>
		yield "ENXIO";
	case E2BIG =>
		yield "E2BIG";
	case ENOEXEC =>
		yield "ENOEXEC";
	case EBADF =>
		yield "EBADF";
	case ECHILD =>
		yield "ECHILD";
	case EAGAIN =>
		yield "EAGAIN";
	case ENOMEM =>
		yield "ENOMEM";
	case EACCES =>
		yield "EACCES";
	case EFAULT =>
		yield "EFAULT";
	case ENOTBLK =>
		yield "ENOTBLK";
	case EBUSY =>
		yield "EBUSY";
	case EEXIST =>
		yield "EEXIST";
	case EXDEV =>
		yield "EXDEV";
	case ENODEV =>
		yield "ENODEV";
	case ENOTDIR =>
		yield "ENOTDIR";
	case EISDIR =>
		yield "EISDIR";
	case EINVAL =>
		yield "EINVAL";
	case ENFILE =>
		yield "ENFILE";
	case EMFILE =>
		yield "EMFILE";
	case ENOTTY =>
		yield "ENOTTY";
	case ETXTBSY =>
		yield "ETXTBSY";
	case EFBIG =>
		yield "EFBIG";
	case ENOSPC =>
		yield "ENOSPC";
	case ESPIPE =>
		yield "ESPIPE";
	case EROFS =>
		yield "EROFS";
	case EMLINK =>
		yield "EMLINK";
	case EPIPE =>
		yield "EPIPE";
	case EDOM =>
		yield "EDOM";
	case ERANGE =>
		yield "ERANGE";
	case EDEADLK =>
		yield "EDEADLK";
	case ENAMETOOLONG =>
		yield "ENAMETOOLONG";
	case ENOLCK =>
		yield "ENOLCK";
	case ENOSYS =>
		yield "ENOSYS";
	case ENOTEMPTY =>
		yield "ENOTEMPTY";
	case ELOOP =>
		yield "ELOOP";
	case ENOMSG =>
		yield "ENOMSG";
	case EIDRM =>
		yield "EIDRM";
	case ECHRNG =>
		yield "ECHRNG";
	case EL2NSYNC =>
		yield "EL2NSYNC";
	case EL3HLT =>
		yield "EL3HLT";
	case EL3RST =>
		yield "EL3RST";
	case ELNRNG =>
		yield "ELNRNG";
	case EUNATCH =>
		yield "EUNATCH";
	case ENOCSI =>
		yield "ENOCSI";
	case EL2HLT =>
		yield "EL2HLT";
	case EBADE =>
		yield "EBADE";
	case EBADR =>
		yield "EBADR";
	case EXFULL =>
		yield "EXFULL";
	case ENOANO =>
		yield "ENOANO";
	case EBADRQC =>
		yield "EBADRQC";
	case EBADSLT =>
		yield "EBADSLT";
	case EBFONT =>
		yield "EBFONT";
	case ENOSTR =>
		yield "ENOSTR";
	case ENODATA =>
		yield "ENODATA";
	case ETIME =>
		yield "ETIME";
	case ENOSR =>
		yield "ENOSR";
	case ENONET =>
		yield "ENONET";
	case ENOPKG =>
		yield "ENOPKG";
	case EREMOTE =>
		yield "EREMOTE";
	case ENOLINK =>
		yield "ENOLINK";
	case EADV =>
		yield "EADV";
	case ESRMNT =>
		yield "ESRMNT";
	case ECOMM =>
		yield "ECOMM";
	case EPROTO =>
		yield "EPROTO";
	case EMULTIHOP =>
		yield "EMULTIHOP";
	case EDOTDOT =>
		yield "EDOTDOT";
	case EBADMSG =>
		yield "EBADMSG";
	case EOVERFLOW =>
		yield "EOVERFLOW";
	case ENOTUNIQ =>
		yield "ENOTUNIQ";
	case EBADFD =>
		yield "EBADFD";
	case EREMCHG =>
		yield "EREMCHG";
	case ELIBACC =>
		yield "ELIBACC";
	case ELIBBAD =>
		yield "ELIBBAD";
	case ELIBSCN =>
		yield "ELIBSCN";
	case ELIBMAX =>
		yield "ELIBMAX";
	case ELIBEXEC =>
		yield "ELIBEXEC";
	case EILSEQ =>
		yield "EILSEQ";
	case ERESTART =>
		yield "ERESTART";
	case ESTRPIPE =>
		yield "ESTRPIPE";
	case EUSERS =>
		yield "EUSERS";
	case ENOTSOCK =>
		yield "ENOTSOCK";
	case EDESTADDRREQ =>
		yield "EDESTADDRREQ";
	case EMSGSIZE =>
		yield "EMSGSIZE";
	case EPROTOTYPE =>
		yield "EPROTOTYPE";
	case ENOPROTOOPT =>
		yield "ENOPROTOOPT";
	case EPROTONOSUPPORT =>
		yield "EPROTONOSUPPORT";
	case ESOCKTNOSUPPORT =>
		yield "ESOCKTNOSUPPORT";
	case EOPNOTSUPP =>
		yield "EOPNOTSUPP";
	case EPFNOSUPPORT =>
		yield "EPFNOSUPPORT";
	case EAFNOSUPPORT =>
		yield "EAFNOSUPPORT";
	case EADDRINUSE =>
		yield "EADDRINUSE";
	case EADDRNOTAVAIL =>
		yield "EADDRNOTAVAIL";
	case ENETDOWN =>
		yield "ENETDOWN";
	case ENETUNREACH =>
		yield "ENETUNREACH";
	case ENETRESET =>
		yield "ENETRESET";
	case ECONNABORTED =>
		yield "ECONNABORTED";
	case ECONNRESET =>
		yield "ECONNRESET";
	case ENOBUFS =>
		yield "ENOBUFS";
	case EISCONN =>
		yield "EISCONN";
	case ENOTCONN =>
		yield "ENOTCONN";
	case ESHUTDOWN =>
		yield "ESHUTDOWN";
	case ETOOMANYREFS =>
		yield "ETOOMANYREFS";
	case ETIMEDOUT =>
		yield "ETIMEDOUT";
	case ECONNREFUSED =>
		yield "ECONNREFUSED";
	case EHOSTDOWN =>
		yield "EHOSTDOWN";
	case EHOSTUNREACH =>
		yield "EHOSTUNREACH";
	case EALREADY =>
		yield "EALREADY";
	case EINPROGRESS =>
		yield "EINPROGRESS";
	case ESTALE =>
		yield "ESTALE";
	case EUCLEAN =>
		yield "EUCLEAN";
	case ENOTNAM =>
		yield "ENOTNAM";
	case ENAVAIL =>
		yield "ENAVAIL";
	case EISNAM =>
		yield "EISNAM";
	case EREMOTEIO =>
		yield "EREMOTEIO";
	case EDQUOT =>
		yield "EDQUOT";
	case ENOMEDIUM =>
		yield "ENOMEDIUM";
	case EMEDIUMTYPE =>
		yield "EMEDIUMTYPE";
	case ECANCELED =>
		yield "ECANCELED";
	case ENOKEY =>
		yield "ENOKEY";
	case EKEYEXPIRED =>
		yield "EKEYEXPIRED";
	case EKEYREVOKED =>
		yield "EKEYREVOKED";
	case EKEYREJECTED =>
		yield "EKEYREJECTED";
	case EOWNERDEAD =>
		yield "EOWNERDEAD";
	case ENOTRECOVERABLE =>
		yield "ENOTRECOVERABLE";
	case ERFKILL =>
		yield "ERFKILL";
	case EHWPOISON =>
		yield "EHWPOISON";
	case =>
		yield "[unknown errno]"; // TODO: snprintf to add errno?
	};
};

export def EPERM: int		= 1;
export def ENOENT: int		= 2;
export def ESRCH: int		= 3;
export def EINTR: int		= 4;
export def EIO: int		= 5;
export def ENXIO: int		= 6;
export def E2BIG: int		= 7;
export def ENOEXEC: int		= 8;
export def EBADF: int		= 9;
export def ECHILD: int		= 10;
export def EAGAIN: int		= 11;
export def ENOMEM: int		= 12;
export def EACCES: int		= 13;
export def EFAULT: int		= 14;
export def ENOTBLK: int		= 15;
export def EBUSY: int		= 16;
export def EEXIST: int		= 17;
export def EXDEV: int		= 18;
export def ENODEV: int		= 19;
export def ENOTDIR: int		= 20;
export def EISDIR: int		= 21;
export def EINVAL: int		= 22;
export def ENFILE: int		= 23;
export def EMFILE: int		= 24;
export def ENOTTY: int		= 25;
export def ETXTBSY: int		= 26;
export def EFBIG: int		= 27;
export def ENOSPC: int		= 28;
export def ESPIPE: int		= 29;
export def EROFS: int		= 30;
export def EMLINK: int		= 31;
export def EPIPE: int		= 32;
export def EDOM: int		= 33;
export def ERANGE: int		= 34;
export def EDEADLK: int		= 35;
export def ENAMETOOLONG: int	= 36;
export def ENOLCK: int		= 37;
export def ENOSYS: int		= 38;
export def ENOTEMPTY: int	= 39;
export def ELOOP: int		= 40;
export def ENOMSG: int		= 42;
export def EIDRM: int		= 43;
export def ECHRNG: int		= 44;
export def EL2NSYNC: int	= 45;
export def EL3HLT: int		= 46;
export def EL3RST: int		= 47;
export def ELNRNG: int		= 48;
export def EUNATCH: int		= 49;
export def ENOCSI: int		= 50;
export def EL2HLT: int		= 51;
export def EBADE: int		= 52;
export def EBADR: int		= 53;
export def EXFULL: int		= 54;
export def ENOANO: int		= 55;
export def EBADRQC: int		= 56;
export def EBADSLT: int		= 57;
export def EBFONT: int		= 59;
export def ENOSTR: int		= 60;
export def ENODATA: int		= 61;
export def ETIME: int		= 62;
export def ENOSR: int		= 63;
export def ENONET: int		= 64;
export def ENOPKG: int		= 65;
export def EREMOTE: int		= 66;
export def ENOLINK: int		= 67;
export def EADV: int		= 68;
export def ESRMNT: int		= 69;
export def ECOMM: int		= 70;
export def EPROTO: int		= 71;
export def EMULTIHOP: int	= 72;
export def EDOTDOT: int		= 73;
export def EBADMSG: int		= 74;
export def EOVERFLOW: int	= 75;
export def ENOTUNIQ: int	= 76;
export def EBADFD: int		= 77;
export def EREMCHG: int		= 78;
export def ELIBACC: int		= 79;
export def ELIBBAD: int		= 80;
export def ELIBSCN: int		= 81;
export def ELIBMAX: int		= 82;
export def ELIBEXEC: int	= 83;
export def EILSEQ: int		= 84;
export def ERESTART: int	= 85;
export def ESTRPIPE: int	= 86;
export def EUSERS: int		= 87;
export def ENOTSOCK: int	= 88;
export def EDESTADDRREQ: int	= 89;
export def EMSGSIZE: int	= 90;
export def EPROTOTYPE: int	= 91;
export def ENOPROTOOPT: int	= 92;
export def EPROTONOSUPPORT: int	= 93;
export def ESOCKTNOSUPPORT: int	= 94;
export def EOPNOTSUPP: int	= 95;
export def EPFNOSUPPORT: int	= 96;
export def EAFNOSUPPORT: int	= 97;
export def EADDRINUSE: int	= 98;
export def EADDRNOTAVAIL: int	= 99;
export def ENETDOWN: int	= 100;
export def ENETUNREACH: int	= 101;
export def ENETRESET: int	= 102;
export def ECONNABORTED: int	= 103;
export def ECONNRESET: int	= 104;
export def ENOBUFS: int		= 105;
export def EISCONN: int		= 106;
export def ENOTCONN: int	= 107;
export def ESHUTDOWN: int	= 108;
export def ETOOMANYREFS: int	= 109;
export def ETIMEDOUT: int	= 110;
export def ECONNREFUSED: int	= 111;
export def EHOSTDOWN: int	= 112;
export def EHOSTUNREACH: int	= 113;
export def EALREADY: int	= 114;
export def EINPROGRESS: int	= 115;
export def ESTALE: int		= 116;
export def EUCLEAN: int		= 117;
export def ENOTNAM: int		= 118;
export def ENAVAIL: int		= 119;
export def EISNAM: int		= 120;
export def EREMOTEIO: int	= 121;
export def EDQUOT: int		= 122;
export def ENOMEDIUM: int	= 123;
export def EMEDIUMTYPE: int	= 124;
export def ECANCELED: int	= 125;
export def ENOKEY: int		= 126;
export def EKEYEXPIRED: int	= 127;
export def EKEYREVOKED: int	= 128;
export def EKEYREJECTED: int	= 129;
export def EOWNERDEAD: int	= 130;
export def ENOTRECOVERABLE: int	= 131;
export def ERFKILL: int		= 132;
export def EHWPOISON: int	= 133;
