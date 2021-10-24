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
	// TODO
	switch (err: int) {
	case =>
		return "[unknown errno]"; // TODO: snprintf to add errno?
	};
};

// Gets the programmer-friendly name for an [[errno]] (e.g. EPERM).
export fn errname(err: errno) str = {
	// TODO
	switch (err: int) {
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
