// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type time_t = i64;
export type clock_t = i64;
export type clockid_t = i32;
export type suseconds_t = i64;
export type dev_t = i32;
export type ino_t = u64;
export type nlink_t = u32;
export type id_t = u32;
export type pid_t = i32;
export type uid_t = u32;
export type gid_t = u32;
export type off_t = i64;
export type blkcnt_t = i64;
export type blksize_t = i32;
export type nfds_t = uint;
export type mode_t = u32;
export type sigset = uint;

// Passing this to a pledge() promise specifies to not change the current value.
export type nullpromise = void;

// Maximum length of a file path including the NUL terminator.
export def PATH_MAX: size = 1024;

export def NAME_MAX: size = 255;

export def PATH_PTMDEV: str = "/dev/ptm";
export def PTMGET: u64 = 0x40287401;

export type ptmget = struct {
	cfd: int,
	sfd: int,
	cn: [16]u8,
	sn: [16]u8
};

export def S_ISUID: mode_t = 0o4000;
export def S_ISGID: mode_t = 0o2000;
export def S_ISTXT: mode_t = 0o1000;
export def S_IRWXU: mode_t = 0o700;
export def S_IRUSR: mode_t = 0o400;
export def S_IWUSR: mode_t = 0o200;
export def S_IXUSR: mode_t = 0o100;
export def S_IRWXG: mode_t = 0o070;
export def S_IRGRP: mode_t = 0o040;
export def S_IWGRP: mode_t = 0o020;
export def S_IXGRP: mode_t = 0o010;
export def S_IRWXO: mode_t = 0o007;
export def S_IROTH: mode_t = 0o004;
export def S_IWOTH: mode_t = 0o002;
export def S_IXOTH: mode_t = 0o001;
export def S_IFMT: mode_t = 0o170000;
export def S_IFIFO: mode_t = 0o010000;
export def S_IFCHR: mode_t = 0o020000;
export def S_IFDIR: mode_t = 0o040000;
export def S_IFBLK: mode_t = 0o060000;
export def S_IFREG: mode_t = 0o100000;
export def S_IFLNK: mode_t = 0o120000;
export def S_IFSOCK: mode_t = 0o140000;
export def S_ISVTX: mode_t = 0o001000;

export def O_RDONLY: int = 0x0;
export def O_WRONLY: int = 0x1;
export def O_RDWR: int = 0x2;
export def O_ACCMODE: int = 0x3;
export def O_NONBLOCK: int = 0x4;
export def O_APPEND: int = 0x8;
export def O_SHLOCK: int = 0x10;
export def O_EXLOCK: int = 0x20;
export def O_ASYNC: int = 0x40;
export def O_FSYNC: int = 0x80;
export def O_SYNC: int = 0x80;
export def O_NOFOLLOW: int = 0x100;
export def O_CREAT: int = 0x200;
export def O_TRUNC: int = 0x400;
export def O_EXCL: int = 0x800;
export def O_DSYNC: int = O_SYNC;
export def O_RSYNC: int = O_SYNC;
export def O_NOCTTY: int = 0x8000;
export def O_CLOEXEC: int = 0x10000;
export def O_DIRECTORY: int = 0x20000;

export def WAIT_ANY: pid_t = -1;
export def WAIT_MYPGRP: pid_t = 0;

export def WNOHANG: int = 0x1;
export def WUNTRACED: int = 0x2;
export def WSTOPPED: int = WUNTRACED;
export def WEXITED: int = 0x4;
export def WCONTINUED: int = 0x8;
export def WNOWAIT: int = 0x10;
export def WTRAPPED: int = 0x20;

export fn wtermsig(status: int) int = status & 0o177;

export fn wifexited(status: int) bool = wtermsig(status) == 0;
export fn wexitstatus(status: int) int = (status >> 8) & 0xff;

export fn wifsignaled(status: int) bool =
	wtermsig(status) != 0o177 && wtermsig(status) != 0;

export type rusage = struct {
	ru_utime: timeval,
	ru_stime: timeval,
	ru_maxrss: i64,
	ru_ixrss: i64,
	ru_idrss: i64,
	ru_isrss: i64,
	ru_minflt: i64,
	ru_majflt: i64,
	ru_nswap: i64,
	ru_inblock: i64,
	ru_oublock: i64,
	ru_msgsnd: i64,
	ru_msgrcv: i64,
	ru_nsignals: i64,
	ru_nvcsw: i64,
	ru_nivcsw: i64,
};

export def RUSAGE_SELF: int = 0;
export def RUSAGE_CHILDREN: int = -1;
export def RUSAGE_THREAD: int = 1;

export def F_OK: int = 0;
export def X_OK: int = 0x1;
export def W_OK: int = 0x2;
export def R_OK: int = 0x4;

export def AT_FDCWD: int = -100;
export def AT_EACCESS: int = 0x1;
export def AT_SYMLINK_NOFOLLOW: int = 0x2;
export def AT_SYMLINK_FOLLOW: int = 0x4;
export def AT_REMOVEDIR: int = 0x8;

export def PROT_NONE: int = 0x0;
export def PROT_READ: int = 0x1;
export def PROT_WRITE: int = 0x2;
export def PROT_EXEC: int = 0x4;

export def MAP_SHARED: int = 0x1;
export def MAP_PRIVATE: int = 0x2;
export def MAP_FIXED: int = 0x10;
export def __MAP_NOREPLACE: int = 0x800;
export def MAP_ANON: int = 0x1000;
export def __MAP_NOFAULT: int = 0x2000;
export def MAP_STACK: int = 0x4000;
export def MAP_CONCEAL: int = 0x8000;

export def MAP_FLAGMASK: int = 0xfff7;

export def RB_AUTOBOOT: int = 0x0;
export def RB_ASKNAME: int = 0x1;
export def RB_SINGLE: int = 0x2;
export def RB_NOSYNC: int = 0x4;
export def RB_HALT: int = 0x8;
export def RB_INITNAME: int = 0x10;
export def RB_DFLTROOT: int = 0x20;
export def RB_KDB: int = 0x40;
export def RB_RDONLY: int = 0x80;
export def RB_DUMP: int = 0x100;
export def RB_MINIROOT: int = 0x200;
export def RB_CONFIG: int = 0x400;
export def RB_TIMEBAD: int = 0x800;
export def RB_POWERDOWN: int = 0x1000;
export def RB_SERCONS: int = 0x2000;
export def RB_USERREQ: int = 0x4000;
export def RB_RESET: int = 0x8000;
export def RB_GOODRANDOM: int = 0x10000;
export def RB_UNHIBERNATE: int = 0x20000;

export def NGROUPS_MAX: size = 16;

export type timespec = struct {
	tv_sec: time_t,
	tv_nsec: i64,
};

export def UTIME_OMIT = -0x1;

export def CLOCK_REALTIME: clockid_t = 0;
export def CLOCK_PROCESS_CPUTIME_ID: clockid_t = 2;
export def CLOCK_MONOTONIC: clockid_t = 3;
export def CLOCK_THREAD_CPUTIME_ID: clockid_t = 4;
export def CLOCK_UPTIME: clockid_t = 5;
export def CLOCK_BOOTTIME: clockid_t = 6;

export def F_DUPFD: int = 0;
export def F_GETFD: int = 1;
export def F_SETFD: int = 2;
export def F_GETFL: int = 3;
export def F_SETFL: int = 4;
export def F_GETOWN: int = 5;
export def F_SETOWN: int = 6;
export def F_GETLK: int = 7;
export def F_SETLK: int = 8;
export def F_SETLKW: int = 9;
export def F_DUPFD_CLOEXEC: int = 10;
export def F_ISATTY: int = 11;

export def FD_CLOEXEC: int = 1;

export def F_RDLCK: i16 = 1;
export def F_UNLCK: i16 = 2;
export def F_WRLCK: i16 = 3;

export type st_flock = struct {
	l_start: off_t,
	l_len: off_t,
	l_pid: pid_t,
	l_type: i16,
	l_whence: i16,
};

export type dirent = struct {
	d_fileno: ino_t,
	d_off: off_t,
	d_reclen: u16,
	d_type: u8,
	d_namlen: u8,
	__d_padding: [4]u8,
	d_name: [*]u8,
};

export def MAXNAMLEN: size = 255;
export def MAXHOSTNAMELEN: size = 255;
export def DT_UNKNOWN: u8 = 0;
export def DT_FIFO: u8 = 1;
export def DT_CHR: u8 = 2;
export def DT_DIR: u8 = 4;
export def DT_BLK: u8 = 6;
export def DT_REG: u8 = 8;
export def DT_LNK: u8 = 10;
export def DT_SOCK: u8 = 12;

export type pollfd = struct {
	fd: int,
	events: i16,
	revents: i16,
};

export def POLLIN: i16 = 0x1;
export def POLLPRI: i16 = 0x2;
export def POLLOUT: i16 = 0x4;
export def POLLERR: i16 = 0x8;
export def POLLHUP: i16 = 0x10;
export def POLLNVAL: i16 = 0x20;
export def POLLRDNORM: i16 = 0x40;
export def POLLNORM: i16 = POLLRDNORM;
export def POLLWRNORM: i16 = POLLOUT;
export def POLLRDBAND: i16 = 0x80;
export def POLLWRBAND: i16 = 0x100;

export type iovec = struct {
	iov_base: *opaque,
	iov_len: size,
};

export def NSIG: int = 32;

export type sigact = struct {
	union {
		sa_handler: *fn (int) void,
		sa_sigaction: *fn (int, *siginfo, *opaque) void,
	},
	sa_mask: sigset,
	sa_flags: int,
};

export type siginfo = struct {
	si_signo: int,
	si_code: int,
	si_errno: int,
	_data: union {
		_pad: [128/4 - 3]int,
		_proc: struct {
			_pid: pid_t,
			_uid: uid_t,
			_pdata: union {
				_kill: struct {
					_value: sigval,
				},
				_cid: struct {
					_utime: clock_t,
					_stime: clock_t,
					_status: int
				},
			},
		},
		_fault: struct {
			_addr: nullable *opaque,
			_trapno: int,
		},
	},
};

export type sigval = union {
	sival_int: int,
	sival_ptr: *opaque,
};

export type stack_t = struct {
	ss_sp: *opaque,
	ss_size: size,
	ss_flags: int,
};

export type timeval = struct {
	tv_sec: time_t,
	tv_usec: suseconds_t,
};

export type stat = struct {
	st_mode: mode_t,
	st_dev: dev_t,
	st_ino: ino_t,
	st_nlink: nlink_t,
	st_uid: uid_t,
	st_gid: gid_t,
	st_rdev: dev_t,
	st_atim: timespec,
	st_mtim: timespec,
	st_ctim: timespec,
	st_size: off_t,
	st_blocks: blkcnt_t,
	st_blksize: blksize_t,
	st_flags: u32,
	st_gen: u32,
	st_birthtim: timespec,
};

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
	c_cc: [NCCS]cc,
	c_ispeed: int,
	c_ospeed: int,
};

export def NCCS: size = 20;

export type tcflag = enum uint {
	// c_iflag bits
	IGNBRK = 0x1,
	BRKINT = 0x2,
	IGNPAR = 0x4,
	PARMRK = 0x8,
	INPCK = 0x10,
	ISTRIP = 0x20,
	INLCR = 0x40,
	IGNCR = 0x80,
	ICRNL = 0x100,
	IXON = 0x200,
	IXOFF = 0x400,
	IXANY = 0x800,
	IUCLC = 0x1000,
	IMAXBEL = 0x2000,

	// c_oflag bits
	OPOST = 0x1,
	ONLCR = 0x2,
	TABDLY = 0x4,
	TAB0 = 0x0,
	TAB3 = 0x4,
	OXTABS = TAB3,
	ONOEOT = 0x8,
	OCRNL = 0x10,
	OLCUC = 0x20,
	ONOCR = 0x40,
	ONLRET = 0x80,

	// c_cflag bits
	CIGNORE = 0x1,
	CSIZE = 0x300,
	CS5 = 0x0,
	CS6 = 0x100,
	CS7 = 0x200,
	CS8 = 0x300,
	CSTOPB = 0x400,
	CREAD = 0x800,
	PARENB = 0x1000,
	PARODD = 0x2000,
	HUPCL = 0x4000,
	CLOCAL = 0x8000,
	CRTSCTS = 0x10000,
	CRTS_IFLOW = CRTSCTS,
	CCTS_OFLOW = CRTSCTS,
	MDMBUF = 0x100000,
	CHWFLOW = (MDMBUF | CRTSCTS),

	// c_lflag bits
	ECHOKE = 0x1,
	ECHOE = 0x2,
	ECHOK = 0x4,
	ECHO = 0x8,
	ECHONL = 0x10,
	ECHOPRT = 0x20,
	ECHOCTL = 0x40,
	ISIG = 0x80,
	ICANON = 0x100,
	ALTWERASE = 0x200,
	IEXTEN = 0x400,
	EXTPROC = 0x800,
	TOSTOP = 0x400000,
	FLUSHO = 0x800000,
	XCASE = 0x1000000,
	NOKERNINFO = 0x2000000,
	PENDIN = 0x20000000,
	NOFLSH = 0x80000000,
};

export type cc = enum u8 {
	VEOF      = 0,
	VEOL      = 1,
	VEOL2     = 2,
	VERASE    = 3,
	VWERASE   = 4,
	VKILL     = 5,
	VREPRINT  = 6,
	VERASE2   = 7,
	VINTR     = 8,
	VQUIT     = 9,
	VSUSP     = 10,
	VDSUSP    = 11,
	VSTART    = 12,
	VSTOP     = 13,
	VLNEXT    = 14,
	VDISCARD  = 15,
	VMIN      = 16,
	VTIME     = 17,
	VSTATUS   = 18,
};

export def TIOCSPGRP: u64 = 0x80047476;
export def TIOCGWINSZ: u64 = 0x40087468;
export def TIOCSWINSZ: u64 = 0x80087467;
export def TIOCGETA: u64 = 0x402c7413;
export def TIOCSETA: u64 = 0x802c7414;

export def SIG_DFL: uintptr = 0;
export def SIG_IGN: uintptr = 1;

export def SIG_BLOCK: int = 1;
export def SIG_UNBLOCK: int = 2;
export def SIG_SETMASK: int = 3;

export def SA_ONSTACK: int = 0x1;
export def SA_RESTART: int = 0x2;
export def SA_RESETHAND: int = 0x4;
export def SA_NOCLDSTOP: int = 0x8;
export def SA_NODEFER: int = 0x10;
export def SA_NOCLDWAIT: int = 0x20;
export def SA_SIGINFO: u64 = 0x40;

export def SIGHUP: int = 1;
export def SIGINT: int = 2;
export def SIGQUIT: int = 3;
export def SIGILL: int = 4;
export def SIGTRAP: int = 5;
export def SIGABRT: int = 6;
export def SIGEMT: int = 7;
export def SIGFPE: int = 8;
export def SIGKILL: int = 9;
export def SIGBUS: int = 10;
export def SIGSEGV: int = 11;
export def SIGSYS: int = 12;
export def SIGPIPE: int = 13;
export def SIGALRM: int = 14;
export def SIGTERM: int = 15;
export def SIGURG: int = 16;
export def SIGSTOP: int = 17;
export def SIGTSTP: int = 18;
export def SIGCONT: int = 19;
export def SIGCHLD: int = 20;
export def SIGTTIN: int = 21;
export def SIGTTOU: int = 22;
export def SIGIO: int = 23;
export def SIGXCPU: int = 24;
export def SIGXFSZ: int = 25;
export def SIGVTALRM: int = 26;
export def SIGPROF: int = 27;
export def SIGWINCH: int = 28;
export def SIGINFO: int = 29;
export def SIGUSR1: int = 30;
export def SIGUSR2: int = 31;
export def SIGTHR: int = 32;

export def PRIO_PROCESS: int = 0;
export def PRIO_PGRP: int = 1;
export def PRIO_USER: int = 2;

export def STDIN_FILENO: int = 0;
export def STDOUT_FILENO: int = 1;
export def STDERR_FILENO: int = 2;

export def SEEK_SET: int = 0;
export def SEEK_CUR: int = 1;
export def SEEK_END: int = 2;

export def LOCK_SH: int = 1;
export def LOCK_EX: int = 2;
export def LOCK_NB: int = 4;
export def LOCK_UN: int = 8;

// sysctl
export def CTL_KERN: int = 1;
export def CTL_VM: int = 2;
export def CTL_FS: int = 3;
export def CTL_NET: int = 4;
export def CTL_DEBUG: int = 5;
export def CTL_HW: int = 6;
export def CTL_MACHDEP: int = 7;
export def CTL_DDB: int = 9;
export def CTL_VFS: int = 10;

export def KERN_OSTYPE: int = 1;
export def KERN_OSRELEASE: int = 2;
export def KERN_OSREV: int = 3;
export def KERN_VERSION: int = 4;
export def KERN_MAXVNODES: int = 5;
export def KERN_MAXPROC: int = 6;
export def KERN_MAXFILES: int = 7;
export def KERN_ARGMAX: int = 8;
export def KERN_SECURELVL: int = 9;
export def KERN_HOSTNAME: int = 10;
export def KERN_HOSTID: int = 11;
export def KERN_CLOCKRATE: int = 12;
export def KERN_PROF: int = 16;
export def KERN_POSIX1: int = 17;
export def KERN_NGROUPS: int = 18;
export def KERN_JOB_CONTROL: int = 19;
export def KERN_SAVED_IDS: int = 20;
export def KERN_BOOTTIME: int = 21;
export def KERN_DOMAINNAME: int = 22;
export def KERN_MAXPARTITIONS: int = 23;
export def KERN_RAWPARTITION: int = 24;
export def KERN_MAXTHREAD: int =  25;
export def KERN_NTHREADS: int = 26;
export def KERN_OSVERSION: int = 27;
export def KERN_SOMAXCONN: int = 28;
export def KERN_SOMINCONN: int = 29;
export def KERN_NOSUIDCOREDUMP: int = 32;
export def KERN_FSYNC: int = 33;
export def KERN_SYSVMSG: int = 34;
export def KERN_SYSVSEM: int = 35;
export def KERN_SYSVSHM: int = 36;
export def KERN_MSGBUFSIZE: int = 38;
export def KERN_MALLOCSTATS: int = 39;
export def KERN_CPTIME: int = 40;
export def KERN_NCHSTATS: int = 41;
export def KERN_FORKSTAT: int = 42;
export def KERN_TTY: int = 44;
export def KERN_CCPU: int = 45;
export def KERN_FSCALE: int = 46;
export def KERN_NPROCS: int = 47;
export def KERN_MSGBUF: int = 48;
export def KERN_POOL: int = 49;
export def KERN_STACKGAPRANDOM: int = 50;
export def KERN_SYSVIPC_INFO: int = 51;
export def KERN_ALLOWKMEM: int = 52;
export def KERN_WITNESSWATCH: int = 53;
export def KERN_SPLASSERT: int = 54;
export def KERN_PROC_ARGS: int = 55;
export def KERN_NFILES: int = 56;
export def KERN_TTYCOUNT: int = 57;
export def KERN_NUMVNODES: int = 58;
export def KERN_MBSTAT: int = 59;
export def KERN_WITNESS: int = 60;
export def KERN_SEMINFO: int = 61;
export def KERN_SHMINFO: int = 62;
export def KERN_INTRCNT: int = 63;
export def KERN_WATCHDOG: int = 64;
export def KERN_ALLOWDT: int = 65;
export def KERN_PROC: int = 66;
export def KERN_MAXCLUSTERS: int = 67;
export def KERN_EVCOUNT: int = 68;
export def KERN_TIMECOUNTER: int = 69;
export def KERN_MAXLOCKSPERUID: int = 70;
export def KERN_CPTIME2: int = 71;
export def KERN_CACHEPCT: int = 72;
export def KERN_FILE: int = 73;
export def KERN_WXABORT: int = 74;
export def KERN_CONSDEV: int = 75;
export def KERN_NETLIVELOCKS: int = 76;
export def KERN_POOL_DEBUG: int = 77;
export def KERN_PROC_CWD: int = 78;
export def KERN_PROC_NOBROADCASTKILL: int = 79;
export def KERN_PROC_VMMAP: int = 80;
export def KERN_GLOBAL_PTRACE: int = 81;
export def KERN_CONSBUFSIZE: int = 82;
export def KERN_CONSBUF: int = 83;
export def KERN_AUDIO: int = 84;
export def KERN_CPUSTATS: int = 85;
export def KERN_PFSTATUS: int = 86;
export def KERN_TIMEOUT_STATS: int = 87;
export def KERN_UTC_OFFSET: int = 88;
export def KERN_VIDEO: int = 89;
export def KERN_CLOCKINTR: int = 90;
export def KERN_AUTOCONF_SERIAL: int = 91;
export def KERN_MAXID: int = 92;

export def KERN_PROC_ALL: int = 0;
export def KERN_PROC_PID: int = 1;
export def KERN_PROC_PGRP: int = 2;
export def KERN_PROC_SESSION: int = 3;
export def KERN_PROC_TTY: int = 4;
export def KERN_PROC_UID: int = 5;
export def KERN_PROC_RUID: int = 6;
export def KERN_PROC_KTHREAD: int = 7;
export def KERN_PROC_SHOW_THREADS: int = 0x40000000;

export def KERN_SYSVIPC_MSG_INFO: int = 1;
export def KERN_SYSVIPC_SEM_INFO: int = 2;
export def KERN_SYSVIPC_SHM_INFO: int = 3;

export def KERN_PROC_ARGV: int = 1;
export def KERN_PROC_NARGV: int = 2;
export def KERN_PROC_ENV: int = 3;
export def KERN_PROC_NENV: int = 4;

export def KERN_AUDIO_RECORD: int = 1;
export def KERN_AUDIO_MAXID: int = 2;

export def KERN_VIDEO_RECORD: int = 1;
export def KERN_VIDEO_MAXID: int = 2;

export def KERN_FILE_BYFILE: int = 1;
export def KERN_FILE_BYPID: int = 2;
export def KERN_FILE_BYUID: int = 3;
export def KERN_FILESLOP: int = 10;

export def KERN_FILE_TEXT: int = -1;
export def KERN_FILE_CDIR: int = -2;
export def KERN_FILE_RDIR: int = -3;
export def KERN_FILE_TRACE: int = -4;

export def KI_MNAMELEN: int = 96;
export def KI_UNPPATHLEN: int = 104;

export def KERN_INTRCNT_NUM: int = 1;
export def KERN_INTRCNT_CNT: int = 2;
export def KERN_INTRCNT_NAME: int = 3;
export def KERN_INTRCNT_VECTOR: int = 4;
export def KERN_INTRCNT_MAXID: int = 5;

export def KERN_WATCHDOG_PERIOD: int = 1;
export def KERN_WATCHDOG_AUTO: int = 2;
export def KERN_WATCHDOG_MAXID: int = 3;

export def KERN_TIMECOUNTER_TICK: int = 1;
export def KERN_TIMECOUNTER_TIMESTEPWARNINGS: int = 2;
export def KERN_TIMECOUNTER_HARDWARE: int = 3;
export def KERN_TIMECOUNTER_CHOICE: int = 4;
export def KERN_TIMECOUNTER_MAXID: int = 5;

export def KERN_CLOCKINTR_STATS: int = 1;
export def KERN_CLOCKINTR_MAXID: int = 2;

export def FS_POSIX: int = 1;
export def FS_MAXID: int = 2;

export def FS_POSIX_SETUID: int = 1;
export def FS_POSIX_MAXID: int = 2;

export def HW_MACHINE: int = 1;
export def HW_MODEL: int = 2;
export def HW_NCPU: int = 3;
export def HW_BYTEORDER: int = 4;
export def HW_PHYSMEM: int = 5;
export def HW_USERMEM: int = 6;
export def HW_PAGESIZE: int = 7;
export def HW_DISKNAMES: int = 8;
export def HW_DISKSTATS: int = 9;
export def HW_DISKCOUNT: int = 10;
export def HW_SENSORS: int = 11;
export def HW_CPUSPEED: int = 12;
export def HW_SETPERF: int = 13;
export def HW_VENDOR: int = 14;
export def HW_PRODUCT: int = 15;
export def HW_VERSION: int = 16;
export def HW_SERIALNO: int = 17;
export def HW_UUID: int = 18;
export def HW_PHYSMEM64: int = 19;
export def HW_USERMEM64: int = 20;
export def HW_NCPUFOUND: int = 21;
export def HW_ALLOWPOWERDOWN: int = 22;
export def HW_PERFPOLICY: int = 23;
export def HW_SMT: int = 24;
export def HW_NCPUONLINE: int = 25;
export def HW_POWER: int = 26;
export def HW_BATTERY: int = 27;
export def HW_UCOMNAMES: int = 28;
export def HW_MAXID: int = 30;

export def HW_BATTERY_CHARGEMODE: int = 1;
export def HW_BATTERY_CHARGESTART: int = 2;
export def HW_BATTERY_CHARGESTOP: int = 3;
export def HW_BATTERY_MAXID: int = 4;

export def CTL_DEBUG_NAME: int = 0;
export def CTL_DEBUG_VALUE: int = 1;
export def CTL_DEBUG_MAXID: int = 20;

export def SI_NOINFO: int = 32767;
export def SI_USER: int = 0;
export def SI_LWP: int = -1;
export def SI_QUEUE: int = -2;
export def SI_TIMER: int = -3;

export def ILL_ILLOPC: int = 1;
export def ILL_ILLOPN: int = 2;
export def ILL_ILLADR: int = 3;
export def ILL_ILLTRP: int = 4;
export def ILL_PRVOPC: int = 5;
export def ILL_PRVREG: int = 6;
export def ILL_COPROC: int = 7;
export def ILL_BADSTK: int = 8;

export def FPE_INTDIV: int = 1;
export def FPE_INTOVF: int = 2;
export def FPE_FLTDIV: int = 3;
export def FPE_FLTOVF: int = 4;
export def FPE_FLTUND: int = 5;
export def FPE_FLTRES: int = 6;
export def FPE_FLTINV: int = 7;
export def FPE_FLTSUB: int = 8;

export def SEGV_MAPERR: int = 1;
export def SEGV_ACCERR: int = 2;

export def BUS_ADRALN: int = 1;
export def BUS_ADRERR: int = 2;
export def BUS_OBJERR: int = 3;

export def TRAP_BRKPT: int = 1;
export def TRAP_TRACE: int = 2;

export def CLD_EXITED: int = 1;
export def CLD_KILLED: int = 2;
export def CLD_DUMPED: int = 3;
export def CLD_TRAPPED: int = 4;
export def CLD_STOPPED: int = 5;
export def CLD_CONTINUED: int = 6;

export def EVFILT_READ: i16 = -1;
export def EVFILT_WRITE: i16 = -2;
export def EVFILT_AIO: i16 = -3;
export def EVFILT_VNODE: i16 = -4;
export def EVFILT_PROC: i16 = -5;
export def EVFILT_SIGNAL: i16 = -6;
export def EVFILT_TIMER: i16 = -7;
export def EVFILT_DEVICE: i16 = -8;
export def EVFILT_EXCEPT: i16 = -9;

export def EV_ADD: u16 = 0x0001;
export def EV_DELETE: u16 = 0x0002;
export def EV_ENABLE: u16 = 0x0004;
export def EV_DISABLE: u16 = 0x0008;

export def EV_ONESHOT: u16 = 0x0010;
export def EV_CLEAR: u16 = 0x0020;
export def EV_RECEIPT: u16 = 0x0040;
export def EV_DISPATCH: u16 = 0x0080;

export def EV_SYSFLAGS: u16 = 0xf800;
export def EV_FLAG1: u16 = 0x2000;

export def EV_EOF: u16 = 0x8000;
export def EV_ERROR: u16 = 0x4000;

export def NOTE_LOWAT: uint = 0x0001;
export def NOTE_EOF: uint = 0x0002;

export def NOTE_OOB: uint = 0x0004;

export def NOTE_DELETE: uint = 0x0001;
export def NOTE_WRITE: uint = 0x0002;
export def NOTE_EXTEND: uint = 0x0004;
export def NOTE_ATTRIB: uint = 0x0008;
export def NOTE_LINK: uint = 0x0010;
export def NOTE_RENAME: uint = 0x0020;
export def NOTE_REVOKE: uint = 0x0040;
export def NOTE_TRUNCATE: uint =   0x0080;

export def NOTE_EXIT: uint = 0x80000000;
export def NOTE_FORK: uint = 0x40000000;
export def NOTE_EXEC: uint = 0x20000000;
export def NOTE_PCTRLMASK: uint = 0xf0000000;
export def NOTE_PDATAMASK: uint = 0x000fffff;

export def NOTE_TRACK: uint = 0x00000001;
export def NOTE_TRACKERR: uint = 0x00000002;
export def NOTE_CHILD: uint = 0x00000004;

export def NOTE_CHANGE: uint = 0x00000001;

export def NOTE_MSECONDS: uint = 0x00000000;
export def NOTE_SECONDS: uint = 0x00000001;
export def NOTE_USECONDS: uint = 0x00000002;
export def NOTE_NSECONDS: uint = 0x00000003;
export def NOTE_ABSTIME: uint = 0x00000010;

export type kevent = struct {
	ident: uintptr,
	filter: i16,
	flags: u16,
	fflags: uint,
	data: i64,
	udata: nullable *opaque,
};
