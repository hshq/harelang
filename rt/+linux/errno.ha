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
		return "[unknown errno]"; // TODO: snprintf to add errno?
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
