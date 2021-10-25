export type time_t = i64;
export type suseconds_t = i64;
export type dev_t = u64;
export type ino_t = u64;
export type nlink_t = u64;
export type id_t = uint;
export type pid_t = uint;
export type uid_t = uint;
export type gid_t = uint;
export type off_t = i64;
export type blkcnt_t = i64;
export type blksize_t = i32;
export type fflags_t = u32;
export type mode_t = u16;
export type nfds_t = uint;

export def NSIG: int = 32;

export type sigset = struct {
	__bits: [4]u32,
};

export type sigact = struct {
	union {
		sa_handler: *fn (_: int) void,
		sa_sigaction: *fn (_: int, _: *siginfo, _: *void) void,
	},
	sa_flags: int,
	sa_mask: sigset,
};

export type siginfo = struct {
	// TODO: Fill in more of this
	si_signo: int,
	si_errno: int,
	si_code: int,
	si_pid: pid_t,
	si_uid: u32,
	si_status: int,
	si_addr: *void,
};

export type pollfd = struct {
	fd: int,
	events: i16,
	revents: i16,
};

export type timespec = struct {
	tv_sec: time_t,
	tv_nsec: i64,
};

export type timeval = struct {
	tv_sec: time_t,
	tv_usec: suseconds_t,
};

export type st_flock = struct {
	l_start: off_t,
	l_len: off_t,
	l_pid: pid_t,
	l_type: i16,
	l_whence: i16,
	l_sysid: int,
};

export type st = struct {
	dev: dev_t,
	ino: ino_t,
	nlink: nlink_t,
	mode: mode_t,
	uid: uid_t,
	gid: gid_t,
	rdev: dev_t,
	atime: timespec,
	mtime: timespec,
	ctime: timespec,
	btime: timespec,
	sz: off_t,
	blocks: blkcnt_t,
	blksz: blksize_t,
	flags: fflags_t,
};

export type freebsd11_stat = struct {
	st_dev: u32,
	st_ino: u32,
	st_mode: mode_t,
	st_nlink: u16,
	st_uid: uid_t,
	st_gid: gid_t,
	st_rdev: u32,
	st_atim: timespec,
	st_mtim: timespec,
	st_ctim: timespec,
	st_size: off_t,
	st_blocks: blkcnt_t,
	st_blksize: blksize_t,
	st_flags: fflags_t,
	st_gen: u32,
	st_lspare: u32,
	st_birthtim: timespec,
};

export type freebsd11_dirent = struct {
	d_fileno: u32,
	d_reclen: u16,
	d_type: u8,
	d_namlen: u8,
	d_name: [*]char,
};

export type winsize = struct {
	ws_row: u16,
	ws_col: u16,
	ws_xpixel: u16,
	ws_ypixel: u16,
};

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

export def TIOCGWINSZ: u64 = 0x40087468;

export def DT_UNKNOWN: u8 = 0;
export def DT_FIFO: u8 = 1;
export def DT_CHR: u8 = 2;
export def DT_DIR: u8 = 4;
export def DT_BLK: u8 = 6;
export def DT_REG: u8 = 8;
export def DT_LNK: u8 = 10;
export def DT_SOCK: u8 = 12;
export def DT_WHT: u8 = 14;

export def O_RDONLY: int = 0x0000;
export def O_WRONLY: int = 0x0001;
export def O_RDWR: int = 0x0002;
export def O_NONBLOCK: int = 0x0004;
export def O_APPEND: int = 0x0008;
export def O_SHLOCK: int = 0x0010;
export def O_EXLOCK: int = 0x0020;
export def O_ASYNC: int = 0x0040;
export def O_FSYNC: int = 0x0080;
export def O_SYNC: int = 0x0080;
export def O_NOFOLLOW: int = 0x0100;
export def O_CREAT: int = 0x0200;
export def O_TRUNC: int = 0x0400;
export def O_EXCL: int = 0x0800;
export def O_NOCTTY: int = 0x8000;
export def O_DIRECT: int = 0x00010000;
export def O_DIRECTORY: int = 0x00020000;
export def O_EXEC: int = 0x00040000;
export def O_TTY_INIT: int = 0x00080000;
export def O_CLOEXEC: int = 0x00100000;
export def O_DSYNC: int = 0x01000000;

export def AT_FDCWD: int = -100;
export def AT_EACCESS: int = 0x0100;
export def AT_SYMLINK_NOFOLLOW: int = 0x0200;
export def AT_SYMLINK_FOLLOW: int = 0x0400;
export def AT_REMOVEDIR: int = 0x0800;
export def AT_RESOLVE_BENEATH: int = 0x2000;

export def MAP_SHARED: uint = 0x0001;
export def MAP_PRIVATE: uint = 0x0002;
export def MAP_FIXED: uint = 0x0010;
export def MAP_HASSEMAPHORE: uint = 0x0200;
export def MAP_STACK: uint = 0x0400;
export def MAP_NOSYNC: uint = 0x0800;
export def MAP_FILE: uint = 0x0000;
export def MAP_ANON: uint = 0x1000;
export def MAP_GUARD: uint = 0x00002000;
export def MAP_EXCL: uint = 0x00004000;
export def MAP_NOCORE: uint = 0x00020000;
export def MAP_PREFAULT_READ: uint = 0x00040000;
export def MAP_32BIT: uint = 0x00080000;

export def PROT_NONE: uint = 0x00;
export def PROT_READ: uint = 0x01;
export def PROT_WRITE: uint = 0x02;
export def PROT_EXEC: uint = 0x04;

export def SIGHUP: int = 1;
export def SIGINT: int = 2;
export def SIGQUIT: int = 3;
export def SIGILL: int = 4;
export def SIGTRAP: int = 5;
export def SIGABRT: int	= 6;
export def SIGFPE: int = 8;
export def SIGKILL: int = 9;
export def SIGBUS: int = 10;
export def SIGSEGV: int = 11;
export def SIGSYS: int = 12;
export def SIGPIPE: int = 13;
export def SIGALRM: int = 14;
export def SIGTERM: int = 15;
export def SIGSTOP: int = 17;
export def SIGTSTP: int = 18;
export def SIGCONT: int = 19;
export def SIGCHLD: int	= 20;
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
export def SIGLWP: int = SIGTHR;
export def SIGLIBRT: int = 33;

export def F_DUPFD: int = 0;
export def F_GETFD: int = 1;
export def F_SETFD: int = 2;
export def F_GETFL: int = 3;
export def F_SETFL: int = 4;
export def F_GETOWN: int = 5;
export def F_SETOWN: int = 6;
export def F_OGETLK: int = 7;
export def F_OSETLK: int = 8;
export def F_OSETLKW: int = 9;
export def F_DUP2FD: int = 10;
export def F_GETLK: int = 11;
export def F_SETLK: int = 12;
export def F_SETLKW: int = 13;
export def F_SETLK_REMOTE: int = 14;
export def F_READAHEAD: int = 15;
export def F_RDAHEAD: int = 16;
export def F_DUPFD_CLOEXEC: int = 17;
export def F_DUP2FD_CLOEXEC: int = 18;
export def F_ADD_SEALS: int = 19;
export def F_GET_SEALS: int = 20;
export def F_ISUNIONSTACK: int = 21;

export def F_SEAL_SEAL: int = 0x0001;
export def F_SEAL_SHRINK: int = 0x0002;
export def F_SEAL_GROW: int = 0x0004;
export def F_SEAL_WRITE: int = 0x0008;

export def FD_CLOEXEC: int = 1;
export def F_RDLCK: int = 1;
export def F_UNLCK: int = 2;
export def F_WRLCK: int = 3;
export def F_UNLCKSYS: int = 4;
export def F_CANCEL: int = 5;

export def PRIO_PROCESS: int = 0;
export def PRIO_PGRP: int = 1;
export def PRIO_USER: int = 2;

export def F_OK: int = 0;
export def X_OK: int = 0x01;
export def W_OK: int = 0x02;
export def R_OK: int = 0x04;

export def CLOCK_REALTIME: int = 0;
export def CLOCK_MONOTONIC: int = 4;
export def CLOCK_VIRTUAL: int = 1;
export def CLOCK_PROF: int = 2;
export def CLOCK_UPTIME: int = 5;
export def CLOCK_UPTIME_PRECISE: int = 7;
export def CLOCK_UPTIME_FAST: int = 8;
export def CLOCK_REALTIME_PRECISE: int = 9;
export def CLOCK_REALTIME_FAST: int = 10;
export def CLOCK_MONOTONIC_PRECISE: int = 11;
export def CLOCK_MONOTONIC_FAST: int = 12;
export def CLOCK_SECOND: int = 13;
export def CLOCK_THREAD_CPUTIME_ID: int = 14;
export def CLOCK_PROCESS_CPUTIME_ID: int = 15;