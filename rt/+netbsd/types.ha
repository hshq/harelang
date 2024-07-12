// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type time_t = i64;
export type suseconds_t = i64;
export type dev_t = u64;
export type ino_t = u64;
export type nlink_t = u64;
export type id_t = uint;
export type pid_t = u64;
export type uid_t = u32;
export type gid_t = u32;
export type off_t = i64;
export type blkcnt_t = i64;
export type blksize_t = i32;
export type fflags_t = u32;
export type mode_t = u32;
export type nfds_t = uint;
export type rlim_t = u64;

export type path = (str | []u8 | *const u8);

// Maximum length of a file path including the NUL terminator.
export def PATH_MAX = 1024z;

// Max bytes in a file name
export def NAME_MAX: int = 511;

export def NGROUPS_MAX: size = 1023;
export def NSIG: int = 32;

export type sigset = struct {
	__bits: [4]u32,
};

export def SA_ONSTACK: u64 = 0x0001;
export def SA_RESTART: u64 = 0x0002;
export def SA_RESETHAND: u64 = 0x0004;
export def SA_NOCLDSTOP: u64 = 0x0008;
export def SA_NODEFER: u64 = 0x0010;
export def SA_NOCLDWAIT: u64 = 0x0020;
export def SA_SIGINFO: u64 = 0x0040;

export def SIG_ERR: uintptr = -1;
export def SIG_DFL: uintptr = 0;
export def SIG_IGN: uintptr = 1;
export def SIG_CATCH: uintptr = 2;
export def SIG_HOLD: uintptr = 3;

export type sigact = struct {
	union {
		sa_handler: *fn (int) void,
		sa_sigaction: *fn (int, *siginfo, *opaque) void,
	},
	sa_mask: sigset,
	sa_flags: int,
};

export def SIG_BLOCK: int = 1;
export def SIG_UNBLOCK: int = 2;
export def SIG_SETMASK: int = 3;

export type sigval = union {
	sival_t: int,
	sival_ptr: *opaque,
};

export type stack_t = struct {
	ss_sp: *opaque,
	ss_size: size,
	ss_flags: int,
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

export def UTIME_OMIT = -0x2;

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

export type stat = struct {
	st_dev: u64,
	st_mode: mode_t,
	__pad0: u32,
	st_ino: u64,
	st_nlink: u32,
	st_uid: uid_t,
	st_gid: gid_t,
	__pad1: u32,
	st_rdev: u64,
	st_atim: timespec,
	st_mtim: timespec,
	st_ctim: timespec,
	st_birthtim: timespec,
	st_size: off_t,
	st_blocks: blkcnt_t,
	st_blksize: blksize_t,
	st_flags: fflags_t,
	st_gen: u32,
	st_spare: [2]u32,
};

export type fsid_t = struct {
	__fsid_val: [2]u32,
};

export def VFS_NAMELEN: int = 32;
export def VFS_MNAMELEN: int = 1024;

export type statvfs = struct {
	// copy of mount exported flags
	f_flag:		u64,
	// file system block size
	f_bsize:	u64,
	// fundamental file system block size
	f_frsize:	u64,
	// optimal file system block size
	f_iosize:	u64,

	// The following are in units of f_frsize

	// number of blocks in file system,
	f_blocks:	u64,
	// free blocks avail in file system
	f_bfree:	u64,
	// free blocks avail to non-root
	f_bavail:	u64,
	// blocks reserved for root
	f_bresvd:	u64,

	// total file nodes in file system
	f_files:	u64,
	// free file nodes in file system
	f_ffree:	u64,
	// free file nodes avail to non-root
	f_favail:	u64,
	// file nodes reserved for root
	f_fresvd:	u64,

	// count of sync reads since mount
	f_syncreads:	u64,
	// count of sync writes since mount
	f_syncwrites:	u64,

	// count of async reads since mount
	f_asyncreads:	u64,
	// count of async writes since mount
	f_asyncwrites:	u64,

	// NetBSD compatible fsid
	f_fsidx:	fsid_t,
	// Posix compatible fsid
	f_fsid:		u64,
	// maximum filename length
	f_namemax:	u64,
	// user that mounted the file system
	f_owner:	uid_t,
	__pad0:		u32,

	// spare space
	f_spare:	[4]u64,

	// fs type name
	f_fstypename:	[VFS_NAMELEN]u8,
	// directory on which mounted
	f_mntonname:	[VFS_MNAMELEN]u8,
	// mounted file system
	f_mntfromname:	[VFS_MNAMELEN]u8,
	// disk label name if avail
	f_mntfromlabel:	[VFS_MNAMELEN]u8,
};

export type dirent = struct {
	// file number of entry
	d_fileno: ino_t,
	// length of this record
	d_reclen: u16,
	// length of d_name
	d_namlen: u16,
	// file type, see below
	d_type: u8,
	d_name: [NAME_MAX + 1]u8,
};

export type iovec = struct {
	iov_base: *opaque,
	iov_len: size
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
};

export def NCCS: size = 20;

export type tcflag = enum uint {
	// c_iflag bits
	IGNBRK  = 0x00000001,
	BRKINT  = 0x00000002,
	IGNPAR  = 0x00000004,
	PARMRK  = 0x00000008,
	INPCK   = 0x00000010,
	ISTRIP  = 0x00000020,
	INLCR   = 0x00000040,
	IGNCR   = 0x00000080,
	ICRNL   = 0x00000100,
	IXON    = 0x00000200,
	IXOFF   = 0x00000400,
	IXANY   = 0x00000800,
	IMAXBEL = 0x00002000,

	// c_oflag bits
	OPOST  = 0x00000001,
	ONLCR  = 0x00000002,
	TABDLY = 0x00000004,
	TAB0   = 0x00000000,
	TAB3   = 0x00000004,
	ONOEOT = 0x00000008,
	OCRNL  = 0x00000010,
	ONOCR  = 0x00000020,
	ONLRET = 0x00000040,

	// c_cflag bits
	CIGNORE    = 0x00000001,
	CSIZE      = 0x00000300,
	CS5        = 0x00000000,
	CS6        = 0x00000100,
	CS7        = 0x00000200,
	CS8        = 0x00000300,
	CSTOPB     = 0x00000400,
	CREAD      = 0x00000800,
	PARENB     = 0x00001000,
	PARODD     = 0x00002000,
	HUPCL      = 0x00004000,
	CLOCAL     = 0x00008000,
	CCTS_OFLOW = 0x00010000,
	CRTS_IFLOW = 0x00020000,
	CRTSCTS    = (CCTS_OFLOW | CRTS_IFLOW),
	CDTR_IFLOW = 0x00040000,
	CDSR_OFLOW = 0x00080000,
	CCAR_OFLOW = 0x00100000,
	CNO_RTSDTR = 0x00200000,

	// c_lflag bits
	ECHOKE     = 0x00000001,
	ECHOE      = 0x00000002,
	ECHOK      = 0x00000004,
	ECHO       = 0x00000008,
	ECHONL     = 0x00000010,
	ECHOPRT    = 0x00000020,
	ECHOCTL    = 0x00000040,
	ISIG       = 0x00000080,
	ICANON     = 0x00000100,
	ALTWERASE  = 0x00000200,
	IEXTEN     = 0x00000400,
	EXTPROC    = 0x00000800,
	TOSTOP     = 0x00400000,
	FLUSHO     = 0x00800000,
	NOKERNINFO = 0x02000000,
	PENDIN     = 0x20000000,
	NOFLSH     = 0x80000000,
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

export def TIOCGWINSZ: u64 = 0x40087468;
export def TIOCSWINSZ: u64 = 0x80087467;
export def TIOCGETA: u64 = 0x402c7413;
export def TIOCSETA: u64 = 0x802c7414;
export def TIOCPTSNAME: u64 = 0x48087448;
export def TIOCSPGRP: u64 = 0x80047476;
export def FIODGNAME: u64 = 0x80106678;

export type ptmget = struct {
	cfd: int,
	sfd: int,
	cn: [PATH_MAX]u8,
	sn: [PATH_MAX]u8,
};

export type rusage = struct {
	// user time used
	ru_utime: timeval,
	// system time used
	ru_stime: timeval,
	// max resident set size
	ru_maxrss: i64,
	// integral shared memory size
	ru_ixrss: i64,
	// integral unshared data "
	ru_idrss: i64,
	// integral unshared stack "
	ru_isrss: i64,
	// page reclaims
	ru_minflt: i64,
	// page faults
	ru_majflt: i64,
	// swaps
	ru_nswap: i64,
	// block input operations
	ru_inblock: i64,
	// block output operations
	ru_oublock: i64,
	// messages sent
	ru_msgsnd: i64,
	// messages received
	ru_msgrcv: i64,
	// signals received
	ru_nsignals: i64,
	// voluntary context switches
	ru_nvcsw: i64,
	// involuntary "
	ru_nivcsw: i64,
};

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
export def O_ACCMODE: int = 0x0003;
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
export def O_CLOEXEC: int = 0x00400000;
export def O_DSYNC: int = 0x01000000;
export def O_RSYNC: int = 0x00020000;

export def AT_FDCWD: int = -100;
export def AT_EACCESS: int = 0x0100;
export def AT_SYMLINK_NOFOLLOW: int = 0x0200;
export def AT_SYMLINK_FOLLOW: int = 0x0400;
export def AT_REMOVEDIR: int = 0x0800;
export def AT_RESOLVE_BENEATH: int = 0x2000;

// set user id on execution
export def S_ISUID: u64 =	0o004000;
// set group id on execution
export def S_ISGID: u64 =	0o002000;
// sticky bit
export def S_ISTXT: u64 =	0o001000;
// RWX mask for owner
export def S_IRWXU: u64 =	0o000700;
// R for owner
export def S_IRUSR: u64 =	0o000400;
// W for owner
export def S_IWUSR: u64 =	0o000200;
// X for owner
export def S_IXUSR: u64 =	0o000100;
export def S_IREAD: u64 =	S_IRUSR;
export def S_IWRITE: u64 =	S_IWUSR;
export def S_IEXEC: u64 =	S_IXUSR;
// RWX mask for group
export def S_IRWXG: u64 =	0o000070;
// R for group
export def S_IRGRP: u64 =	0o000040;
// W for group
export def S_IWGRP: u64 =	0o000020;
// X for group
export def S_IXGRP: u64 =	0o000010;
// RWX mask for other
export def S_IRWXO: u64 =	0o000007;
// R for other
export def S_IROTH: u64 =	0o000004;
// W for other
export def S_IWOTH: u64 =	0o000002;
// X for other
export def S_IXOTH: u64 =	0o000001;
// type of file mask
export def S_IFMT: u64 =	0o170000;
// named pipe (fifo)
export def S_IFIFO: u64 =	0o010000;
// character special
export def S_IFCHR: u64 =	0o020000;
// directory
export def S_IFDIR: u64 =	0o040000;
// block special
export def S_IFBLK: u64 =	0o060000;
// regular
export def S_IFREG: u64 =	0o100000;
// symbolic link
export def S_IFLNK: u64 =	0o120000;
// save swapped text even after use
export def S_ISVTX: u64 =	0o001000;
// socket
export def S_IFSOCK: u64 =	0o140000;
// whiteout
export def S_IFWHT: u64 =	0o160000;
// Archive state 1, ls -l shows 'a'
export def S_ARCH1: u64 =	0o200000;
// Archive state 2, ls -l shows 'A'
export def S_ARCH2: u64 =	0o400000;

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
export def SIGABRT: int = 6;
export def SIGIOT: int = SIGABRT;
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
export def F_DUPFD_CLOEXEC: int = 12;
export def F_DUP2FD_CLOEXEC: int = 18;
export def F_ADD_SEALS: int = 16;
export def F_GET_SEALS: int = 17;
export def F_ISUNIONSTACK: int = 21;

export def F_SEAL_SEAL: int = 0x0001;
export def F_SEAL_SHRINK: int = 0x0002;
export def F_SEAL_GROW: int = 0x0004;
export def F_SEAL_WRITE: int = 0x0008;

export def FD_CLOEXEC: int = 1;
export def F_UNLCKSYS: int = 4;
export def F_CANCEL: int = 5;

export def F_RDLCK: i16 = 1;
export def F_UNLCK: i16 = 2;
export def F_WRLCK: i16 = 3;

export def PRIO_PROCESS: int = 0;
export def PRIO_PGRP: int = 1;
export def PRIO_USER: int = 2;

export def F_OK: int = 0;
export def X_OK: int = 0x01;
export def W_OK: int = 0x02;
export def R_OK: int = 0x04;

export def CLOCK_REALTIME: int = 0;
export def CLOCK_VIRTUAL: int = 1;
export def CLOCK_PROF: int = 2;
export def CLOCK_MONOTONIC: int = 3;
export def CLOCK_THREAD_CPUTIME_ID: int = 0x20000000;
export def CLOCK_PROCESS_CPUTIME_ID: int = 0x40000000;

export def WNOHANG: int = 1;
export def WUNTRACED: int = 2;
export def WSTOPPED: int = WUNTRACED;
export def WCONTINUED: int = 4;
export def WNOWAIT: int = 8;
export def WEXITED: int = 16;
export def WTRAPPED: int = 32;

export def STDIN_FILENO: int = 0;
export def STDOUT_FILENO: int = 1;
export def STDERR_FILENO: int = 2;

export def SEEK_SET: int = 0;
export def SEEK_CUR: int = 1;
export def SEEK_END: int = 2;

// Flock operations
export def LOCK_SH: int = 1;
export def LOCK_EX: int = 2;
export def LOCK_NB: int = 4;
export def LOCK_UN: int = 8;

export type rlimit = struct {
	rlim_cur: rlim_t,
	rlim_max: rlim_t,
};

export def RLIM_INFINITY: rlim_t = -1;

export def RLIMIT_CPU: int		= 0;
export def RLIMIT_FSIZE: int		= 1;
export def RLIMIT_DATA: int		= 2;
export def RLIMIT_STACK: int		= 3;
export def RLIMIT_CORE: int		= 4;
export def RLIMIT_RSS: int		= 5;
export def RLIMIT_MEMLOCK: int		= 6;
export def RLIMIT_NPROC: int		= 7;
export def RLIMIT_NOFILE: int		= 8;
export def RLIMIT_SBSIZE: int		= 9;
export def RLIMIT_VMEM: int		= 10;
export def RLIMIT_AS: int		= RLIMIT_VMEM;
export def RLIMIT_NPTS: int		= 11;
export def RLIMIT_SWAP: int		= 12;
export def RLIMIT_KQUEUES: int		= 13;
export def RLIMIT_UMTXP: int		= 14;
// number of threads
export def RLIMIT_NTHR: int		= 11;

export def SHUT_RD: int = 0;
export def SHUT_WR: int = 1;
export def SHUT_RDWR: int = 2;

// non-existent device
export def NODEV: int = -1;

// synchronously wait for I/O to complete
export def MNT_WAIT:	int = 1;
// start all I/O, but do not wait for it
export def MNT_NOWAIT:	int = 2;
// push data not written by filesystem syncer
export def MNT_LAZY:	int = 3;

// Efficient memory file-system
export def MOUNT_TMPFS =	"tmpfs";
export def MOUNT_SHMFS =	MOUNT_TMPFS;

// Shared memory objects are supported using tmpfs.
export def SHMFS_DIR_PATH =	"/var/shm";
export def SHMFS_DIR_MODE =	(S_ISVTX | S_IRWXU | S_IRWXG | S_IRWXO);
export def SHMFS_OBJ_PREFIX =	".shmobj_";
