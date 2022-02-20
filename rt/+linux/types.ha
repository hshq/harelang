export type off_t = u64;
export type dev_t = u64;
export type ino_t = u64;
export type nlink_t = u64;
export type mode_t = uint;
export type id_t = uint;
export type uid_t = uint;
export type gid_t = uint;
export type time_t = i64;
export type suseconds_t = i64;
export type nfds_t = u64;
export type pid_t = int;
export type timer_t = int;
export type clock_t = i64;
export type si_band_t = i64;

export def NSIG: int = 64;

export type sigset = struct {
	__val: [1]u64,
};

export type timeval = struct {
	tv_sec:  time_t,
	tv_usec: suseconds_t,
};

export type timespec = struct {
	tv_sec:  time_t,
	tv_nsec: i64,
};

export type itimerspec = struct {
	it_interval: timespec,
	it_value: timespec,
};

export def AT_FDCWD: int		= -100;
export def AT_SYMLINK_NOFOLLOW: int	= 0x100;
export def AT_REMOVEDIR: int		= 0x200;
export def AT_SYMLINK_FOLLOW: int	= 0x400;
export def AT_EACCESS: int		= 0x200;
export def AT_NO_AUTOMOUNT: int		= 0x800;
export def AT_EMPTY_PATH: int		= 0x1000;
export def AT_STATX_SYNC_TYPE: int	= 0x6000;
export def AT_STATX_SYNC_AS_STAT: int	= 0x0000;
export def AT_STATX_FORCE_SYNC: int	= 0x2000;
export def AT_STATX_DONT_SYNC: int	= 0x4000;
export def AT_RECURSIVE: int		= 0x8000;

export def S_IFDIR: mode_t = 0o040000;
export def S_IFCHR: mode_t = 0o020000;
export def S_IFBLK: mode_t = 0o060000;
export def S_IFREG: mode_t = 0o100000;
export def S_IFIFO: mode_t = 0o010000;
export def S_IFLNK: mode_t = 0o120000;
export def S_IFSOCK: mode_t = 0o140000;

// O_DIRECTORY is arch specific
export def O_RDONLY: int	= 0o0;
export def O_WRONLY: int	= 0o1;
export def O_RDWR: int		= 0o2;
export def O_CREATE: int	= 0o100;
export def O_EXCLUSIVE: int	= 0o200;
export def O_NOCTTY: int	= 0o400;
export def O_TRUNC: int		= 0o1000;
export def O_APPEND: int	= 0o2000;
export def O_NONBLOCK: int	= 0o4000;
export def O_DSYNC: int		= 0o10000;
export def O_SYNC: int		= 0o4010000;
export def O_RSYNC: int		= 0o4010000;
export def O_NOFOLLOW: int	= 0o400000;
export def O_NOATIME: int	= 0o1000000;
export def O_CLOEXEC: int	= 0o2000000;
export def O_PATH: int		= 0o10000000;
export def O_TMPFILE: int	= 0o20000000;

type statx_timestamp = struct {
	tv_sec:  i64,
	tv_nsec: u32,
};

type stx = struct {
	mask:       u32,
	blksize:    u32,
	attributes: u64,
	nlink:      u32,
	uid:        u32,
	gid:        u32,
	mode:       u16,
	ino:        u64,
	sz:         u64,
	blocks:     u64,
	attr_mask:  u64,
	atime:      statx_timestamp,
	btime:      statx_timestamp,
	ctime:      statx_timestamp,
	mtime:      statx_timestamp,
	rdev_major: u32,
	rdev_minor: u32,
	dev_major:  u32,
	dev_minor:  u32,
	__reserved: [14]u64,
};

// Note: the st type does not match the kernel API. The kernel API has a stat
// buffer which varies from arch to arch, but because we always use statx(2) and
// copy the data from the stx type, we don't have to deal with that nonsense.
export type st = struct {
	dev:    dev_t,
	ino:    ino_t,
	mode:   mode_t,
	nlink:  nlink_t,
	uid:    uid_t,
	gid:    gid_t,
	rdev:   dev_t,
	sz:     u64,
	blksz:  u64,
	blocks: u64,
	atime:  timespec,
	mtime:  timespec,
	ctime:  timespec,
};

def STATX_TYPE: uint		= 0x00000001;
def STATX_MODE: uint		= 0x00000002;
def STATX_NLINK: uint		= 0x00000004;
def STATX_UID: uint		= 0x00000008;
def STATX_GID: uint		= 0x00000010;
def STATX_ATIME: uint		= 0x00000020;
def STATX_MTIME: uint		= 0x00000040;
def STATX_CTIME: uint		= 0x00000080;
def STATX_INO: uint		= 0x00000100;
def STATX_SIZE: uint		= 0x00000200;
def STATX_BLOCKS: uint		= 0x00000400;
def STATX_BASIC_STATS: uint	= 0x000007FF;
def STATX_BTIME: uint		= 0x00000800;
def STATX_MNT_ID: uint		= 0x00001000;

export def SIGHUP: int		= 1;
export def SIGINT: int		= 2;
export def SIGQUIT: int		= 3;
export def SIGILL: int		= 4;
export def SIGTRAP: int		= 5;
export def SIGABRT: int		= 6;
export def SIGBUS: int		= 7;
export def SIGFPE: int		= 8;
export def SIGKILL: int		= 9;
export def SIGUSR1: int		= 10;
export def SIGSEGV: int		= 11;
export def SIGUSR2: int		= 12;
export def SIGPIPE: int		= 13;
export def SIGALRM: int		= 14;
export def SIGTERM: int		= 15;
export def SIGSTKFLT: int	= 16;
export def SIGCHLD: int		= 17;
export def SIGCONT: int		= 18;
export def SIGSTOP: int		= 19;
export def SIGTSTP: int		= 20;
export def SIGTTIN: int		= 21;
export def SIGTTOU: int		= 22;
export def SIGURG: int		= 23;
export def SIGXCPU: int		= 24;
export def SIGXFSZ: int		= 25;
export def SIGVTALRM: int	= 26;
export def SIGPROF: int		= 27;
export def SIGWINCH: int	= 28;
export def SIGIO: int		= 29;
export def SIGPOLL: int		= 29;
export def SIGPWR: int		= 30;
export def SIGSYS: int		= 31;

export def MAP_SHARED: uint		= 0x01;
export def MAP_PRIVATE: uint		= 0x02;
export def MAP_SHARED_VALIDATE: uint	= 0x03;
export def MAP_FIXED: uint		= 0x10;
export def MAP_ANON: uint		= 0x20;
export def MAP_NORESERVE: uint		= 0x4000;
export def MAP_GROWSDOWN: uint		= 0x0100;
export def MAP_DENYWRITE: uint		= 0x0800;
export def MAP_EXECUTABLE: uint		= 0x1000;
export def MAP_LOCKED: uint		= 0x2000;
export def MAP_POPULATE: uint		= 0x8000;
export def MAP_NONBLOCK: uint		= 0x10000;
export def MAP_STACK: uint		= 0x20000;
export def MAP_HUGETLB: uint		= 0x40000;
export def MAP_SYNC: uint		= 0x80000;
export def MAP_FIXED_NOREPLACE: uint	= 0x100000;
export def MAP_FILE: uint		= 0;
export def MAP_HUGE_SHIFT: uint		= 26;
export def MAP_HUGE_MASK: uint		= 0x3F;
export def MAP_HUGE_64KB: uint		= 16 << 26;
export def MAP_HUGE_512KB: uint		= 19 << 26;
export def MAP_HUGE_1MB: uint		= 20 << 26;
export def MAP_HUGE_2MB: uint		= 21 << 26;
export def MAP_HUGE_8MB: uint		= 23 << 26;
export def MAP_HUGE_16MB: uint		= 24 << 26;
export def MAP_HUGE_32MB: uint		= 25 << 26;
export def MAP_HUGE_256MB: uint		= 28 << 26;
export def MAP_HUGE_512MB: uint		= 29 << 26;
export def MAP_HUGE_1GB: uint		= 30 << 26;
export def MAP_HUGE_2GB: uint		= 31 << 26;
export def MAP_HUGE_16GB: uint		= 34 << 26;

export def PROT_NONE: uint	= 0;
export def PROT_READ: uint 	= 1;
export def PROT_WRITE: uint	= 2;
export def PROT_EXEC: uint	= 4;
export def PROT_GROWSDOWN: uint	= 0x01000000;
export def PROT_GROWSUP: uint	= 0x02000000;

export def F_OK: int = 0;
export def R_OK: int = 4;
export def W_OK: int = 2;
export def X_OK: int = 1;

export def F_DUPFD: int = 0;
export def F_DUPFD_CLOEXEC: int = 1030;
export def F_GETFD: int = 1;
export def F_SETFD: int = 2;
export def F_GETFL: int = 3;
export def F_SETFL: int = 4;
export def F_SETOWN: int = 8;
export def F_GETOWN: int = 9;
export def F_SETSIG: int = 10;
export def F_GETSIG: int = 11;
export def F_GETLK: int = 12;
export def F_SETLK: int = 13;
export def F_SETLKW: int = 14;
export def F_SETOWN_EX: int = 15;
export def F_GETOWN_EX: int = 16;
export def F_GETOWNER_UIDS: int = 17;

export type st_flock = struct {
	l_type: i16,
	l_whence: i16,
	l_start: i64,
	l_len: i64,
	pid: int,
};

export type f_owner_ex = struct {
	_type: int,
	pid: int,
};

export def CLOCK_REALTIME: int			= 0;
export def CLOCK_MONOTONIC: int			= 1;
export def CLOCK_PROCESS_CPUTIME_ID: int	= 2;
export def CLOCK_THREAD_CPUTIME_ID: int		= 3;
export def CLOCK_MONOTONIC_RAW: int		= 4;
export def CLOCK_REALTIME_COARSE: int		= 5;
export def CLOCK_MONOTONIC_COARSE: int		= 6;
export def CLOCK_BOOTTIME: int			= 7;
export def CLOCK_REALTIME_ALARM: int		= 8;
export def CLOCK_BOOTTIME_ALARM: int		= 9;
export def CLOCK_SGI_CYCLE: int			= 10;
export def CLOCK_TAI: int			= 11;

export type open_how = struct {
	flags: u64,
	mode: u64,
	resolve: u64,
};

export def RESOLVE_NO_XDEV: u64		= 0x01;
export def RESOLVE_NO_MAGICLINKS: u64	= 0x02;
export def RESOLVE_NO_SYMLINKS: u64	= 0x04;
export def RESOLVE_BENEATH: u64		= 0x08;
export def RESOLVE_IN_ROOT: u64		= 0x10;

export def DT_UNKNOWN: u8	= 0;
export def DT_FIFO: u8		= 1;
export def DT_CHR: u8		= 2;
export def DT_DIR: u8		= 4;
export def DT_BLK: u8		= 6;
export def DT_REG: u8		= 8;
export def DT_LNK: u8		= 10;
export def DT_SOCK: u8		= 12;

export type dirent64 = struct {
	d_ino: ino_t,
	d_off: off_t,
	d_reclen: u16,
	d_type: u8,
	d_name: [*]char,
};

export def WNOHANG: int		= 1;
export def WUNTRACED: int	= 2;
export def WSTOPPED: int	= 2;
export def WEXITED: int		= 4;
export def WCONTINUED: int	= 8;
export def WNOWAIT: int		= 0x1000000;

export fn wexitstatus(s: int) int = (s & 0xff00) >> 8;
export fn wtermsig(s: int) int = s & 0x7f;
export fn wstopsig(s: int) int = wexitstatus(s);
export fn wcoredump(s: int) int = s & 0x80;
export fn wifexited(s: int) bool = wtermsig(s) <= 0;
export fn wifstopped(s: int) bool = (((s & 0xFFFF) * 0x10001) >> 8) > 0x7f00;
export fn wifsignaled(s: int) bool = (s & 0xFFFF) - 1 < 0xFF;
export fn wifcontinued(s: int) bool = s == 0xFFFF;

export type rusage = struct {
	ru_utime: timeval,
	ru_stime: timeval,
	ru_maxrss: u64,
	ru_ixrss: u64,
	ru_idrss: u64,
	ru_isrss: u64,
	ru_minflt: u64,
	ru_majflt: u64,
	ru_nswap: u64,
	ru_inblock: u64,
	ru_oublock: u64,
	ru_msgsnd: u64,
	ru_msgrcv: u64,
	ru_nsignals: u64,
	ru_nvcsw: u64,
	ru_nivcsw: u64,
	__reserved: [16]u64,
};

export type utsname = struct {
	sysname:    [65]char,
	nodename:   [65]char,
	release:    [65]char,
	version:    [65]char,
	machine:    [65]char,
	domainname: [65]char,
};

export def POLLIN: i16 = 0x001;
export def POLLPRI: i16 = 0x002;
export def POLLOUT: i16 = 0x004;
export def POLLERR: i16 = 0x008;
export def POLLHUP: i16 = 0x010;
export def POLLVAL: i16 = 0x020;

export type pollfd = struct {
	fd: int,
	events: i16,
	revents: i16,
};

export def EPOLL_CLOEXEC: int = O_CLOEXEC;

// Valid opcodes to issue to sys_epoll_ctl()
export def EPOLL_CTL_ADD: int = 1;
export def EPOLL_CTL_DEL: int = 2;
export def EPOLL_CTL_MOD: int = 3;

// Epoll event masks
export def EPOLLIN: u32 = 0x00000001;
export def EPOLLPRI: u32 = 0x00000002;
export def EPOLLOUT: u32 = 0x00000004;
export def EPOLLERR: u32 = 0x00000008;
export def EPOLLHUP: u32 = 0x00000010;
export def EPOLLNVAL: u32 = 0x00000020;
export def EPOLLRDNORM: u32 = 0x00000040;
export def EPOLLRDBAND: u32 = 0x00000080;
export def EPOLLWRNORM: u32 = 0x00000100;
export def EPOLLWRBAND: u32 = 0x00000200;
export def EPOLLMSG: u32 = 0x00000400;
export def EPOLLRDHUP: u32 = 0x00002000;
export def EPOLLWAKEUP: u32 = 1 << 29;
export def EPOLLONESHOT: u32 = 1 << 30;
export def EPOLLET: u32 = 1 << 31;

export type epoll_data = union {
	ptr: *void,
	fd: int,
	u32_: u32,
	u64_: u64,
};

export type epoll_event = struct {
	events: u32,
	@offset(4) data: epoll_data,
};

export def EFD_CLOEXEC: int = O_CLOEXEC;
export def EFD_NONBLOCK: int = O_NONBLOCK;
export def EFD_SEMAPHORE: int = 1;

export def TFD_TIMER_ABSTIME: int = 1;
export def TFD_TIMER_CANCEL_ON_SET: int = 2;

export def SIG_BLOCK: int = 0;
export def SIG_UNBLOCK: int = 1;
export def SIG_SETMASK: int = 2;

def SI_MAX_SIZE: size = 128 / size(u8);

export type sigval = union {
	sival_t: int,
	sival_ptr: *void,
};


//#define __ADDR_BND_PKEY_PAD (__alignof__(void *) < sizeof(short) ? sizeof(short) : __alignof__(void *))
def __ADDR_BND_PKEY_PAD: size = 8;

export type siginfo = union {
	struct {
		si_signo: int,
		si_errno: int,
		si_code: int,

		union {
			// kill()
			struct {
				si_pid: pid_t,
				si_uid: u32,
			},

			// POSIX.1b timers
			struct {
				si_tid: timer_t,
				si_overrun: int,
				_sigval: sigval, // @ signals
				si_sys_private: int,
			},

			// POSIX.1b signals
			struct {
				_sig_pid: pid_t, // @kill
				_sig_uid: u32, // @ kill
				union {
					si_value: sigval,
					si_int: int,
					si_ptr: *void,
				}
			},

			// SIGCHLD
			struct {
				_chld_pid: pid_t, // @ kill
				_chld_uid: u32, // @ kill
				si_status: int,
				si_utime: clock_t,
				si_stime: clock_t,
			},

			// SIGILL, SIGFPE, SIGSEGV, SIGBUS, SIGTRAP, SIGEMT
			struct {
				si_addr: *void,

				union {

					// used when si_code=BUS_MCEERR_AR or
					// used when si_code=BUS_MCEERR_AO
					si_addr_lsb: i16,

					struct {
						_dummy_bnd: [__ADDR_BND_PKEY_PAD]u8,
						si_lower: *void,
						si_upper: *void,
					},

					struct {
						_dummy_pkey: [__ADDR_BND_PKEY_PAD]u8,
						si_pkey: u32,
					},
				},
			},

			// SIGPOLL
			struct {
				si_band: si_band_t,
				si_fd: int,
			},

			// SIGSYS
			struct {
				si_call_addr: *void,
				si_syscall: int,
				si_arch: uint,
			},

		},
	},
	_si_pad: [SI_MAX_SIZE - 3 * size(int)]u8,
};

export def SA_NOCLDSTOP: u64 = 0x00000001;
export def SA_NOCLDWAIT: u64 = 0x00000002;
export def SA_SIGINFO: u64 = 0x00000004;
export def SA_ONSTACK: u64 = 0x08000000;
export def SA_RESTART: u64 = 0x10000000;
export def SA_NODEFER: u64 = 0x40000000;
export def SA_RESETHAND: u64 = 0x80000000;
export def SA_NOMASK: u64 = SA_NODEFER;
export def SA_ONESHOT: u64 = SA_RESETHAND;
export def SA_RESTORER: u64 = 0x04000000;

export type sigact = struct {
	union {
		sa_handler: *fn (_: int) void,
		sa_sigaction: *fn (_: int, _: *siginfo, _: *void) void,
	},
	sa_flags: u64,
	sa_restorer: *fn () void,
	sa_mask: sigset,
};

export def SFD_NONBLOCK: int = O_NONBLOCK;
export def SFD_CLOEXEC: int = O_CLOEXEC;

export type signalfd_siginfo = struct {
	ssi_signo: u32,
	ssi_errno: i32,
	ssi_code: i32,
	ssi_pid: u32,
	ssi_uid: u32,
	ssi_fd: i32 ,
	ssi_tid: u32,
	ssi_band: u32,
	ssi_overrun: u32,
	ssi_trapno: u32,
	ssi_status: i32,
	ssi_int: i32,
	ssi_ptr: u64,
	ssi_utime: u64,
	ssi_stime: u64,
	ssi_addr: u64,
	ssi_addr_lsb: u16,
	__pad2: u16,
	ssi_syscall: i32,
	ssi_call_addr: u64,
	ssi_arch: u32,

	__pad: [28]u8, // pad to 128 bytes
};

export type iovec = struct {
	iov_base: *void,
	iov_len: size
};

export def PRIO_PROCESS: int = 0;
export def PRIO_PGRP: int = 1;
export def PRIO_USER: int = 2;

export type winsize = struct {
	ws_row: u16,
	ws_col: u16,
	ws_xpixel: u16,
	ws_ypixel: u16,
};

export type termios = struct {
	c_iflag: tcflag,
	c_oflag: tcflag,
	c_cflag: tcflag,
	c_lflag: tcflag,
	c_line: cc,
	c_cc: [NCCS]cc,
};

export def NCCS: size = 19;

// TODO: change this back to char when harec starts to work with it
export type cc = enum u8 {
	VINTR    = 0,
	VQUIT    = 1,
	VERASE   = 2,
	VKILL    = 3,
	VEOF     = 4,
	VTIME    = 5,
	VMIN     = 6,
	VSWTC    = 7,
	VSTART   = 8,
	VSTOP    = 9,
	VSUSP    = 10,
	VEOL     = 11,
	VREPRINT = 12,
	VDISCARD = 13,
	VWERASE  = 14,
	VLNEXT   = 15,
	VEOL2    = 16,
};

export type tcflag = enum uint {
	// c_iflag bit meaning
	IGNBRK  = 0o00001,
	BRKINT  = 0o00002,
	IGNPAR  = 0o00004,
	PARMRK  = 0o00010,
	INPCK   = 0o00020,
	ISTRIP  = 0o00040,
	INLCR   = 0o00100,
	IGNCR   = 0o00200,
	ICRNL   = 0o00400,
	IUCLC   = 0o01000,
	IXON    = 0o02000,
	IXANY   = 0o04000,
	IXOFF   = 0o10000,
	IMAXBEL = 0o20000,
	IUTF8   = 0o40000,

	// c_oflag bit meaning
	OPOST  = 0o000001,
	OLCUC  = 0o000002,
	ONLCR  = 0o000004,
	OCRNL  = 0o000010,
	ONOCR  = 0o000020,
	ONLRET = 0o000040,
	OFILL  = 0o000100,
	OFDEL  = 0o000200,
	NLDLY  = 0o000400,
	NL0    = 0o000000,
	NL1    = 0o000400,
	CRDLY  = 0o003000,
	CR0    = 0o000000,
	CR1    = 0o001000,
	CR2    = 0o002000,
	CR3    = 0o003000,
	TABDLY = 0o014000,
	TAB0   = 0o000000,
	TAB1   = 0o004000,
	TAB2   = 0o010000,
	TAB3   = 0o014000,
	XTABS  = 0o014000,
	BSDLY  = 0o020000,
	BS0    = 0o000000,
	BS1    = 0o020000,
	VTDLY  = 0o040000,
	VT0    = 0o000000,
	VT1    = 0o040000,
	FFDLY  = 0o100000,
	FF0    = 0o000000,
	FF1    = 0o100000,

	// c_cflag bit meaning
	CBAUD    = 0o010017,
	B0       = 0o000000,
	B50      = 0o000001,
	B75      = 0o000002,
	B110     = 0o000003,
	B134     = 0o000004,
	B150     = 0o000005,
	B200     = 0o000006,
	B300     = 0o000007,
	B600     = 0o000010,
	B1200    = 0o000011,
	B1800    = 0o000012,
	B2400    = 0o000013,
	B4800    = 0o000014,
	B9600    = 0o000015,
	B19200   = 0o000016,
	B38400   = 0o000017,
	EXTA     = B19200,
	EXTB     = B38400,
	CSIZE    = 0o000060,
	CS5      = 0o000000,
	CS6      = 0o000020,
	CS7      = 0o000040,
	CS8      = 0o000060,
	CSTOPB   = 0o000100,
	CREAD    = 0o000200,
	PARENB   = 0o000400,
	PARODD   = 0o001000,
	HUPCL    = 0o002000,
	CLOCAL   = 0o004000,
	CBAUDEX  = 0o010000,
	BOTHER   = 0o010000,
	B57600   = 0o010001,
	B115200  = 0o010002,
	B230400  = 0o010003,
	B460800  = 0o010004,
	B500000  = 0o010005,
	B576000  = 0o010006,
	B921600  = 0o010007,
	B1000000 = 0o010010,
	B1152000 = 0o010011,
	B1500000 = 0o010012,
	B2000000 = 0o010013,
	B2500000 = 0o010014,
	B3000000 = 0o010015,
	B3500000 = 0o010016,
	B4000000 = 0o010017,
	CIBAUD   = 0o02003600000,
	CMSPAR   = 0o10000000000,
	CRTSCTS  = 0o20000000000,

	// c_lflag bit meaning
	ISIG    = 0o000001,
	ICANON  = 0o000002,
	XCASE   = 0o000004,
	ECHO    = 0o000010,
	ECHOE   = 0o000020,
	ECHOK   = 0o000040,
	ECHONL  = 0o000100,
	NOFLSH  = 0o000200,
	TOSTOP  = 0o000400,
	ECHOCTL = 0o001000,
	ECHOPRT = 0o002000,
	ECHOKE  = 0o004000,
	FLUSHO  = 0o010000,
	PENDIN  = 0o040000,
	IEXTEN  = 0o100000,
	EXTPROC = 0o200000,
};


export def TIOCGWINSZ: u64 = 0x5413;
export def TCGETS: u64 = 0x5401;
export def TCSETS: u64 = 0x5402;

export def MLOCK_ONFAULT: uint = 0x01;

export def MCL_CURRENT: int = 1;
export def MCL_FUTURE: int = 2;
export def MCL_ONFAULT: int = 4;
