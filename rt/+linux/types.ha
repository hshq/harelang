export type dev_t = u64;
export type ino_t = u64;
export type nlink_t = u64;
export type mode_t = uint;
export type uid_t = uint;
export type gid_t = uint;
export type time_t = i64;
export type suseconds_t = i64;

export type timeval = struct {
	tv_sec:  time_t,
	tv_usec: suseconds_t,
};

export type timespec = struct {
	tv_sec:  time_t,
	tv_nsec: i64,
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

export def O_RDONLY: int	= 0;
export def O_WRONLY: int	= 1;
export def O_RDWR: int		= 2;
// TODO: Add the other flags:
export def O_CLOEXEC: int	= 0o2000000;

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

def STATX_TYPE: uint		= 0x00000001u;
def STATX_MODE: uint		= 0x00000002u;
def STATX_NLINK: uint		= 0x00000004u;
def STATX_UID: uint		= 0x00000008u;
def STATX_GID: uint		= 0x00000010u;
def STATX_ATIME: uint		= 0x00000020u;
def STATX_MTIME: uint		= 0x00000040u;
def STATX_CTIME: uint		= 0x00000080u;
def STATX_INO: uint		= 0x00000100u;
def STATX_SIZE: uint		= 0x00000200u;
def STATX_BLOCKS: uint		= 0x00000400u;
def STATX_BASIC_STATS: uint	= 0x000007FFu;
def STATX_BTIME: uint		= 0x00000800u;
def STATX_MNT_ID: uint		= 0x00001000u;

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

export def MAP_SHARED: uint		= 0x01u;
export def MAP_PRIVATE: uint		= 0x02u;
export def MAP_SHARED_VALIDATE: uint	= 0x03u;
export def MAP_FIXED: uint		= 0x10u;
export def MAP_ANON: uint		= 0x20u;
export def MAP_NORESERVE: uint		= 0x4000u;
export def MAP_GROWSDOWN: uint		= 0x0100u;
export def MAP_DENYWRITE: uint		= 0x0800u;
export def MAP_EXECUTABLE: uint		= 0x1000u;
export def MAP_LOCKED: uint		= 0x2000u;
export def MAP_POPULATE: uint		= 0x8000u;
export def MAP_NONBLOCK: uint		= 0x10000u;
export def MAP_STACK: uint		= 0x20000u;
export def MAP_HUGETLB: uint		= 0x40000u;
export def MAP_SYNC: uint		= 0x80000u;
export def MAP_FIXED_NOREPLACE: uint	= 0x100000u;
export def MAP_FILE: uint		= 0u;
export def MAP_HUGE_SHIFT: uint		= 26u;
export def MAP_HUGE_MASK: uint		= 0x3fu;
export def MAP_HUGE_64KB: uint		= 16u << 26u;
export def MAP_HUGE_512KB: uint		= 19u << 26u;
export def MAP_HUGE_1MB: uint		= 20u << 26u;
export def MAP_HUGE_2MB: uint		= 21u << 26u;
export def MAP_HUGE_8MB: uint		= 23u << 26u;
export def MAP_HUGE_16MB: uint		= 24u << 26u;
export def MAP_HUGE_32MB: uint		= 25u << 26u;
export def MAP_HUGE_256MB: uint		= 28u << 26u;
export def MAP_HUGE_512MB: uint		= 29u << 26u;
export def MAP_HUGE_1GB: uint		= 30u << 26u;
export def MAP_HUGE_2GB: uint		= 31u << 26u;
export def MAP_HUGE_16GB: uint		= 34u << 26u;

export def PROT_NONE: uint	= 0u;
export def PROT_READ: uint 	= 1u;
export def PROT_WRITE: uint	= 2u;
export def PROT_EXEC: uint	= 4u;
export def PROT_GROWSDOWN: uint	= 0x01000000u;
export def PROT_GROWSUP: uint	= 0x02000000u;

export def F_OK: int = 0;
export def R_OK: int = 4;
export def W_OK: int = 2;
export def X_OK: int = 1;

export def F_DUPFD: int = 0;
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
