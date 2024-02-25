// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type time_t      = i64;
export type suseconds_t = i64;
export type dev_t       = i32;
export type ino_t       = u32;
export type nlink_t     = u16;
export type id_t        = uint;
export type pid_t       = uint;
export type uid_t       = uint;
export type gid_t       = uint;
export type off_t       = i64;
export type blkcnt_t    = i64;
export type blksize_t   = i32;
export type fflags_t    = u32;
export type mode_t      = u16;
export type nfds_t      = uint;
export type rlim_t      = u64;

// <sys/syslimits.h>: ax supplemental group id's
export def NGROUPS_MAX: size = 16;
// <sys/signal.h>: counting 0; could be 33 (mask is 1-32)
export def NSIG: int = 32;

// if SA_SIGINFO is set, sa_sigaction is to be used instead of sa_handler.
// #define sa_handler      __sigaction_u.__sa_handler
// #define sa_sigaction    __sigaction_u.__sa_sigaction

export def SA_ONSTACK  : u64 = 0x0001; // take signal on signal stack
export def SA_RESTART  : u64 = 0x0002; // restart system on signal return
export def SA_RESETHAND: u64 = 0x0004; // reset to SIG_DFL when taking signal
export def SA_NOCLDSTOP: u64 = 0x0008; // do not generate SIGCHLD on child stop
export def SA_NODEFER  : u64 = 0x0010; // don't mask the signal we're delivering
export def SA_NOCLDWAIT: u64 = 0x0020; // don't keep zombies around
export def SA_SIGINFO  : u64 = 0x0040; // signal handler with SA_SIGINFO args

export def SA_USERTRAMP: u64 = 0x0100; // do not bounce off kernel's sigtramp
// This will provide 64bit register set in a 32bit user address space
export def SA_64REGSET : u64 = 0x0200; // signal handler with SA_SIGINFO args with 64bit regs information

// the following are the only bits we support from user space, the
// rest are for kernel use only.
export def SA_USERSPACE_MASK: u64 = (SA_ONSTACK | SA_RESTART | SA_RESETHAND | SA_NOCLDSTOP | SA_NODEFER | SA_NOCLDWAIT | SA_SIGINFO);

// Flags for sigprocmask:
export def SIG_BLOCK  : int = 1; // block specified signal set
export def SIG_UNBLOCK: int = 2; // unblock specified signal set
export def SIG_SETMASK: int = 3; // set specified signal set

export type sigset = struct {
    __bits: [4]u32,
};

// <sys/signal.h>

export def SIG_ERR : uintptr = -1;
export def SIG_DFL : uintptr = 0;
export def SIG_IGN : uintptr = 1;
export def SIG_HOLD: uintptr = 5;

export type sigact = struct {
    union {
        sa_handler: *fn (int) void,
        sa_sigaction: *fn (int, *siginfo, *opaque) void,
    },
    sa_mask: sigset,
    sa_flags: int,
};

export type siginfo = struct {
    // TODO: Fill in more of this
    si_signo : int,     // signal number
    si_errno : int,     // errno association
    si_code  : int,     // signal code
    si_pid   : pid_t,   // sending process
    si_uid   : uid_t,   // sender's ruid
    si_status: int,     // exit value
    si_addr  : *opaque, // faulting instruction
    // si_value : sigval,  // signal value
    // si_band  : i64,     // band event for SIGPOLL
    // __pad    : [7]u64,  // Reserved for Future Use
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

// <sys/poll.h>
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

// <sys/fcntl.h>
export type st_flock = struct {
    l_start : off_t, // starting offset
    l_len   : off_t, // len = 0 means until end of file
    l_pid   : pid_t, // lock owner
    l_type  : i16,   // lock type: read/write, etc.
    l_whence: i16,   // type of l_start
};

export type st = struct {
    dev   : dev_t,
    ino   : ino_t,
    nlink : nlink_t,
    mode  : mode_t,
    uid   : uid_t,
    gid   : gid_t,
    rdev  : dev_t,
    atime : timespec,
    mtime : timespec,
    ctime : timespec,
    btime : timespec,
    sz    : off_t,
    blocks: blkcnt_t,
    blksz : blksize_t,
    flags : fflags_t,
};

// <sys/stat.h>
export type stat_t = struct {
    st_dev     : dev_t,     // [XSI] ID of device containing file
    st_ino     : ino_t,     // [XSI] File serial number
    st_mode    : mode_t,    // [XSI] Mode of file (see below)
    st_nlink   : nlink_t,   // [XSI] Number of hard links
    st_uid     : uid_t,     // [XSI] User ID of the file
    st_gid     : gid_t,     // [XSI] Group ID of the file
    st_rdev    : dev_t,     // [XSI] Device ID
    st_atim    : timespec,  // time of last access
    st_mtim    : timespec,  // time of last data modification
    st_ctim    : timespec,  // time of last status change
    st_size    : off_t,     // [XSI] file size, in bytes
    st_blocks  : blkcnt_t,  // [XSI] blocks allocated for file
    st_blksize : blksize_t, // [XSI] optimal blocksize for I/O
    st_flags   : fflags_t,  // user defined flags for file
    st_gen     : u32,       // file generation number
    st_lspare  : i32,       // RESERVED: DO NOT USE!
    st_birthtim: timespec,  // RESERVED: DO NOT USE!
};

// <sys/dirent.h>
// SYS_getdirentries
export def MAXNAMLEN:  u16 = 256;
export def MAXPATHLEN: u16 = 1024;

export type dirent = struct {
    d_fileno: ino_t,   // file number of entry
    d_reclen: u16,     // length of this record
    d_type  : u8,      // file type, see below
    d_namlen: u8,      // length of string in d_name
    d_name  : [*]u8,   // name must be no longer than this
};

// SYS_getdirentries64
// export type dirent = struct {
//  d_fileno: ino_t,   // file number of entry
//  d_off   : u64,     // seek offset (optional, used by servers)
//  d_reclen: u16,     // length of this record
//  d_namlen: u16,     // length of string in d_name
//  d_type  : u8,      // file type, see below
//  d_name  : [*]u8,   // entry name (up to MAXPATHLEN bytes)
// };

// <sys/uio.h>
export type iovec = struct {
    iov_base: *opaque, // [XSI] Base address of I/O memory region
    iov_len:   size,   // [XSI] Size of region iov_base points to
};

// <sys/termios.h>
export type winsize = struct {
    ws_row   : u16, // rows, in characters
    ws_col   : u16, // columns, in characters
    ws_xpixel: u16, // horizontal size, pixels
    ws_ypixel: u16, // vertical size, pixels
};

export type termios = struct {
    c_iflag : tcflag,   // input flags
    c_oflag : tcflag,   // output flags
    c_cflag : tcflag,   // control flags
    c_lflag : tcflag,   // local flags
    c_cc    : [NCCS]cc, // control chars
    c_ispeed: speed_t,  // input speed
    c_ospeed: speed_t,  // output speed
};

export type speed_t = u64;

export def NCCS: size = 20;

export type tcflag = enum uint {
    // c_iflag bits: Input flags - software input processing
    IGNBRK     = 0x00000001, // ignore BREAK condition
    BRKINT     = 0x00000002, // map BREAK to SIGINTR
    IGNPAR     = 0x00000004, // ignore (discard) parity errors
    PARMRK     = 0x00000008, // mark parity and framing errors
    INPCK      = 0x00000010, // enable checking of parity errors
    ISTRIP     = 0x00000020, // strip 8th bit off chars
    INLCR      = 0x00000040, // map NL into CR
    IGNCR      = 0x00000080, // ignore CR
    ICRNL      = 0x00000100, // map CR to NL (ala CRMOD)
    IXON       = 0x00000200, // enable output flow control
    IXOFF      = 0x00000400, // enable input flow control
    IXANY      = 0x00000800, // any char will restart after stop
    IMAXBEL    = 0x00002000, // ring bell on input queue full
    IUTF8      = 0x00004000, // maintain state for UTF-8 VERASE

    // c_oflag bits: Output flags - software output processing
    OPOST      = 0x00000001, // enable following output processing
    ONLCR      = 0x00000002, // map NL to CR-NL (ala CRMOD)
    OXTABS     = 0x00000004, // expand tabs to spaces
    ONOEOT     = 0x00000008, // discard EOT's (^D) on output)
    // - Begin unimplemented features
    // OCRNL      = 0x00000010, // map CR to NL on output
    // ONOCR      = 0x00000020, // no CR output at column 0
    // ONLRET     = 0x00000040, // NL performs CR function
    // OFILL      = 0x00000080, // use fill characters for delay
    // NLDLY      = 0x00000300, // \n delay
    // TABDLY     = 0x00000c04, // horizontal tab delay
    // CRDLY      = 0x00003000, // \r delay
    // FFDLY      = 0x00004000, // form feed delay
    // BSDLY      = 0x00008000, // \b delay
    // VTDLY      = 0x00010000, // vertical tab delay
    // OFDEL      = 0x00020000, // fill is DEL, else NUL

    // NL0        = 0x00000000,
    // NL1        = 0x00000100,
    // NL2        = 0x00000200,
    // NL3        = 0x00000300,
    // TAB0       = 0x00000000,
    // TAB1       = 0x00000400,
    // TAB2       = 0x00000800,
    // TAB3       = 0x00000004, // not in sys/ioctl_compat.h, use OXTABS value
    // CR0        = 0x00000000,
    // CR1        = 0x00001000,
    // CR2        = 0x00002000,
    // CR3        = 0x00003000,
    // FF0        = 0x00000000,
    // FF1        = 0x00004000,
    // BS0        = 0x00000000,
    // BS1        = 0x00008000,
    // VT0        = 0x00000000,
    // VT1        = 0x00010000,
    // + End unimplemented features

    // c_cflag bits: Control flags - hardware control of terminal
    CIGNORE    = 0x00000001, // ignore control flags
    CSIZE      = 0x00000300, // character size mask
    CS5        = 0x00000000, // 5 bits (pseudo)
    CS6        = 0x00000100, // 6 bits
    CS7        = 0x00000200, // 7 bits
    CS8        = 0x00000300, // 8 bits
    CSTOPB     = 0x00000400, // send 2 stop bits
    CREAD      = 0x00000800, // enable receiver
    PARENB     = 0x00001000, // parity enable
    PARODD     = 0x00002000, // odd parity, else even
    HUPCL      = 0x00004000, // hang up on last close
    CLOCAL     = 0x00008000, // ignore modem status lines
    CCTS_OFLOW = 0x00010000, // CTS flow control of output
    CRTS_IFLOW = 0x00020000, // RTS flow control of input
    CRTSCTS    = (CCTS_OFLOW | CRTS_IFLOW),
    CDTR_IFLOW = 0x00040000, // DTR flow control of input
    CDSR_OFLOW = 0x00080000, // DSR flow control of output
    CCAR_OFLOW = 0x00100000, // DCD flow control of output
    MDMBUF     = 0x00100000, // old name for CCAR_OFLOW

    // c_lflag bits: "Local" flags - dumping ground for other state
    ECHOKE     = 0x00000001, // visual erase for line kill
    ECHOE      = 0x00000002, // visually erase chars
    ECHOK      = 0x00000004, // echo NL after line kill
    ECHO       = 0x00000008, // enable echoing
    ECHONL     = 0x00000010, // echo NL even if ECHO is off
    ECHOPRT    = 0x00000020, // visual erase mode for hardcopy
    ECHOCTL    = 0x00000040, // echo control chars as ^(Char)
    ISIG       = 0x00000080, // enable signals INTR, QUIT, [D]SUSP
    ICANON     = 0x00000100, // canonicalize input lines
    ALTWERASE  = 0x00000200, // use alternate WERASE algorithm
    IEXTEN     = 0x00000400, // enable DISCARD and LNEXT
    EXTPROC    = 0x00000800, // external processing
    TOSTOP     = 0x00400000, // stop background jobs from output
    FLUSHO     = 0x00800000, // output being flushed (state)
    NOKERNINFO = 0x02000000, // no kernel output from VSTATUS
    PENDIN     = 0x20000000, // XXX retype pending input (state)
    NOFLSH     = 0x80000000, // don't flush after interrupt
};

// <sys/termios.h>
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

// <sys/ttycom.h>
export def TIOCGWINSZ  : u64 = 0x40087468; // get window size
export def TIOCSWINSZ  : u64 = 0x80087467; // set window size
export def TIOCGETA    : u64 = 0x40487413; // get termios struct
export def TIOCSETA    : u64 = 0x80487414; // set termios struct
export def TIOCSPGRP   : u64 = 0x80047476; // set pgrp of tty

// <sys/resource.h>
export type rusage = struct {
    ru_utime   : timeval, // user time used (PL)
    ru_stime   : timeval, // system time used (PL)
    ru_maxrss  : i64, // max resident set size (PL)
    ru_ixrss   : i64, // integral shared memory size (NU)
    ru_idrss   : i64, // integral unshared data (NU)
    ru_isrss   : i64, // integral unshared stack (NU)
    ru_minflt  : i64, // page reclaims (NU)
    ru_majflt  : i64, // page faults (NU)
    ru_nswap   : i64, // swaps (NU)
    ru_inblock : i64, // block input operations (atomic)
    ru_oublock : i64, // block output operations (atomic)
    ru_msgsnd  : i64, // messages sent (atomic)
    ru_msgrcv  : i64, // messages received (atomic)
    ru_nsignals: i64, // signals received (atomic)
    ru_nvcsw   : i64, // voluntary context switches (atomic)
    ru_nivcsw  : i64, // involuntary "
};

// <sys/dirent.h>: File types
export def DT_UNKNOWN: u8 = 0;
export def DT_FIFO   : u8 = 1;
export def DT_CHR    : u8 = 2;
export def DT_DIR    : u8 = 4;
export def DT_BLK    : u8 = 6;
export def DT_REG    : u8 = 8;
export def DT_LNK    : u8 = 10;
export def DT_SOCK   : u8 = 12;
export def DT_WHT    : u8 = 14;

// <sys/fcntl.h>: open-only flags
export def O_RDONLY   : int = 0x0000; // open for reading only
export def O_WRONLY   : int = 0x0001; // open for writing only
export def O_RDWR     : int = 0x0002; // open for reading and writing
export def O_ACCMODE  : int = 0x0003; // mask for above modes
export def O_NONBLOCK : int = 0x0004; // no delay
export def O_APPEND   : int = 0x0008; // set append mode
export def O_SHLOCK   : int = 0x0010; // open with shared file lock
export def O_EXLOCK   : int = 0x0020; // open with exclusive file lock
export def O_ASYNC    : int = 0x0040; // signal pgrp when data ready
export def O_SYNC     : int = 0x0080; // synch I/O file integrity
export def O_FSYNC    : int = O_SYNC; // source compatibility: do not use
export def O_NOFOLLOW : int = 0x0100; // don't follow symlinks
export def O_CREAT    : int = 0x0200; // create if nonexistant
export def O_TRUNC    : int = 0x0400; // truncate to zero length
export def O_EXCL     : int = 0x0800; // error if already exists
export def O_EVTONLY  : int = 0x8000; // descriptor requested for event notifications only
// export def O_DIRECT   : int = 0x10000;
export def O_NOCTTY   : int = 0x20000; // don't assign controlling terminal
export def O_DIRECTORY: int = 0x100000;
export def O_SYMLINK  : int = 0x200000; // allow open of a symlink
export def O_CLOEXEC  : int = 0x1000000; // implicitly set FD_CLOEXEC
export def O_DSYNC    : int = 0x400000; // synch I/O data integrity

// <sys/fcntl.h>: Descriptor value for the current working directory
export def AT_FDCWD           : int = -2;
// Flags for the at functions
export def AT_EACCESS         : int = 0x0010; // Use effective ids in access check
export def AT_SYMLINK_NOFOLLOW: int = 0x0020; // Act on the symlink itself not the target
export def AT_SYMLINK_FOLLOW  : int = 0x0040; // Act on target of symlink
export def AT_REMOVEDIR       : int = 0x0080; // Path refers to directory
export def AT_REALDEV         : int = 0x0200; // Return real device inodes resides on for fstatat(2)
export def AT_FDONLY          : int = 0x0400; // Use only the fd and Ignore the path for fstatat(2)

// export def AT_EMPTY_PATH      : int = 0x0;

// [XSI] The symbolic names for file modes for use as values of mode_t
// shall be defined as described in <sys/stat.h>

// File type
export def S_IFMT  : mode_t = 0o170000; // [XSI] type of file mask
export def S_IFIFO : mode_t = 0o010000; // [XSI] named pipe (fifo)
export def S_IFCHR : mode_t = 0o020000; // [XSI] character special
export def S_IFDIR : mode_t = 0o040000; // [XSI] directory
export def S_IFBLK : mode_t = 0o060000; // [XSI] block special
export def S_IFREG : mode_t = 0o100000; // [XSI] regular
export def S_IFLNK : mode_t = 0o120000; // [XSI] symbolic link
export def S_IFSOCK: mode_t = 0o140000; // [XSI] socket
export def S_IFWHT : mode_t = 0o160000; // OBSOLETE: whiteout


// <sys/mman.h>: Flags contain sharing type and options.
export def MAP_SHARED                  : uint = 0x0001; // [MF|SHM] share changes
export def MAP_PRIVATE                 : uint = 0x0002; // [MF|SHM] changes are private
// Other flags
export def MAP_FIXED                   : uint = 0x0010; // [MF|SHM] interpret addr exactly
export def MAP_RENAME                  : uint = 0x0020; // Sun: rename private pages to file
export def MAP_NORESERVE               : uint = 0x0040; // Sun: don't reserve needed swap area
export def MAP_RESERVED0080            : uint = 0x0080; // previously unimplemented MAP_INHERIT
export def MAP_NOEXTEND                : uint = 0x0100; // for MAP_FILE, don't change file size
export def MAP_HASSEMAPHORE            : uint = 0x0200; // region may contain semaphores
export def MAP_NOCACHE                 : uint = 0x0400; // don't cache pages for this mapping
export def MAP_JIT                     : uint = 0x0800; // Allocate a region that will be used for JIT purposes
// Mapping type
export def MAP_FILE                    : uint = 0x0000; // map from file (default)
export def MAP_ANON                    : uint = 0x1000; // allocated from memory, swap space
export def MAP_ANONYMOUS               : uint = MAP_ANON;
// map some possibly unreliable memory and be able to access it safely
export def MAP_RESILIENT_CODESIGN      : uint = 0x2000; // no code-signing failures
export def MAP_RESILIENT_MEDIA         : uint = 0x4000; // no backing-store failures
// Flags used to support translated processes.
export def MAP_TRANSLATED_ALLOW_EXECUTE: uint = 0x20000; // allow execute in translated processes
export def MAP_UNIX03                  : uint = 0x40000; // UNIX03 compliance

// <sys/mman.h>: Protections are chosen from these bits, or-ed together
export def PROT_NONE : uint = 0x00; // [MC2] no permissions
export def PROT_READ : uint = 0x01; // [MC2] pages can be read
export def PROT_WRITE: uint = 0x02; // [MC2] pages can be written
export def PROT_EXEC : uint = 0x04; // [MC2] pages can be executed

// <sys/signal.h>
export def SIGHUP   : int = 1;
export def SIGINT   : int = 2;
export def SIGQUIT  : int = 3;
export def SIGILL   : int = 4;
export def SIGTRAP  : int = 5;
export def SIGABRT  : int = 6;
export def SIGIOT   : int = SIGABRT;
export def SIGEMT   : int = 7;
export def SIGFPE   : int = 8;
export def SIGKILL  : int = 9;
export def SIGBUS   : int = 10;
export def SIGSEGV  : int = 11;
export def SIGSYS   : int = 12;
export def SIGPIPE  : int = 13;
export def SIGALRM  : int = 14;
export def SIGTERM  : int = 15;
export def SIGURG   : int = 16;
export def SIGSTOP  : int = 17;
export def SIGTSTP  : int = 18;
export def SIGCONT  : int = 19;
export def SIGCHLD  : int = 20;
export def SIGTTIN  : int = 21;
export def SIGTTOU  : int = 22;
export def SIGIO    : int = 23;
export def SIGXCPU  : int = 24;
export def SIGXFSZ  : int = 25;
export def SIGVTALRM: int = 26;
export def SIGPROF  : int = 27;
export def SIGWINCH : int = 28;
export def SIGINFO  : int = 29;
export def SIGUSR1  : int = 30;
export def SIGUSR2  : int = 31;

// <sys/fcntl.h>: command values
export def F_DUPFD         : int = 0; // duplicate file descriptor
export def F_GETFD         : int = 1; // get file descriptor flags
export def F_SETFD         : int = 2; // set file descriptor flags
export def F_GETFL         : int = 3; // get file status flags
export def F_SETFL         : int = 4; // set file status flags
export def F_GETOWN        : int = 5; // get SIGIO/SIGURG proc/pgrp
export def F_SETOWN        : int = 6; // set SIGIO/SIGURG proc/pgrp
export def F_GETLK         : int = 7; // get record locking information
export def F_SETLK         : int = 8; // set record locking information
export def F_SETLKW        : int = 9; // F_SETLK; wait if blocked
export def F_SETLKWTIMEOUT : int = 10; // F_SETLK; wait if blocked, return on timeout

export def F_FLUSH_DATA    : int = 40;
export def F_CHKCLEAN      : int = 41; // Used for regression test
export def F_PREALLOCATE   : int = 42; // Preallocate storage
export def F_SETSIZE       : int = 43; // Truncate a file. Equivalent to calling truncate(2)
export def F_RDADVISE      : int = 44; // Issue an advisory read async with no copy to user
export def F_RDAHEAD       : int = 45; // turn read ahead off/on for this fd
// 46,47 used to be F_READBOOTSTRAP and F_WRITEBOOTSTRAP
export def F_NOCACHE       : int = 48; // turn data caching off/on for this fd
export def F_LOG2PHYS      : int = 49; // file offset to device offset
export def F_GETPATH       : int = 50; // return the full path of the fd
export def F_FULLFSYNC     : int = 51; // fsync + ask the drive to flush to the media
export def F_PATHPKG_CHECK : int = 52; // find which component (if any) is a package
export def F_FREEZE_FS     : int = 53; // "freeze" all fs operations
export def F_THAW_FS       : int = 54; // "thaw" all fs operations
export def F_GLOBAL_NOCACHE: int = 55; // turn data caching off/on (globally) for this file
export def F_ADDSIGS       : int = 59; // add detached signatures
export def F_ADDFILESIGS   : int = 61; // add signature from same file (used by dyld for shared libs)
export def F_NODIRECT      : int = 62; // used in conjunction with F_NOCACHE to indicate that DIRECT, synchonous writes
                                    // should not be used (i.e. its ok to temporaily create cached pages)
export def F_GETPROTECTIONCLASS: int = 63; // Get the protection class of a file from the EA, returns int
export def F_SETPROTECTIONCLASS: int = 64; // Set the protection class of a file for the EA, requires int
export def F_LOG2PHYS_EXT      : int = 65; // file offset to device offset, extended
export def F_GETLKPID          : int = 66; // get record locking information, per-process
// See F_DUPFD_CLOEXEC below for 67

export def F_SETBACKINGSTORE   : int = 70; // Mark the file as being the backing store for another filesystem
export def F_GETPATH_MTMINFO   : int = 71; // return the full path of the FD, but error in specific mtmd circumstances
export def F_GETCODEDIR        : int = 72; // Returns the code directory, with associated hashes, to the caller
export def F_SETNOSIGPIPE      : int = 73; // No SIGPIPE generated on EPIPE
export def F_GETNOSIGPIPE      : int = 74; // Status of SIGPIPE for this fd
export def F_TRANSCODEKEY      : int = 75; // For some cases, we need to rewrap the key for AKS/MKB
export def F_SINGLE_WRITER     : int = 76; // file being written to a by single writer... if throttling enabled, writes
                               // may be broken into smaller chunks with throttling in between
export def F_GETPROTECTIONLEVEL: int = 77; // Get the protection version number for this filesystem
export def F_FINDSIGS          : int = 78; // Add detached code signatures (used by dyld for shared libs)

export def F_ADDFILESIGS_FOR_DYLD_SIM: int = 83; // Add signature from same file, only if it is signed by Apple (used by dyld for simulator)
export def F_BARRIERFSYNC      : int = 85;  // fsync + issue barrier to drive
export def F_ADDFILESIGS_RETURN: int = 97;  // Add signature from same file, return end offset in structure on success
export def F_CHECK_LV          : int = 98;  // Check if Library Validation allows this Mach-O file to be mapped into the calling process
export def F_PUNCHHOLE         : int = 99;  // Deallocate a range of the file
export def F_TRIM_ACTIVE_FILE  : int = 100; // Trim an active file
export def F_SPECULATIVE_READ  : int = 101; // Synchronous advisory read fcntl for regular and compressed file
export def F_GETPATH_NOFIRMLINK: int = 102; // return the full path without firmlinks of the fd
export def F_ADDFILESIGS_INFO  : int = 103; // Add signature from same file, return information
export def F_ADDFILESUPPL      : int = 104; // Add supplemental signature from same file with fd reference to original
export def F_GETSIGSINFO       : int = 105; // Look up code signature information attached to a file or slice
// FS-specific fcntl()'s numbers begin at 0x00010000 and go up
export def FCNTL_FS_SPECIFIC_BASE: int = 0x00010000;

export def F_DUPFD_CLOEXEC : int = 67; // mark the dup with FD_CLOEXEC

// <sys/fcntl.h>: file descriptor flags (F_GETFD, F_SETFD)
export def FD_CLOEXEC: int = 1; // close-on-exec flag

// <sys/fcntl.h>: record locking flags (F_GETLK, F_SETLK, F_SETLKW)
export def F_RDLCK: i16 = 1; // shared or read lock
export def F_UNLCK: i16 = 2; // unlock
export def F_WRLCK: i16 = 3; // exclusive or write lock

// <sys/resource.h>: 1st parameter to getpriority()/setpriority()
export def PRIO_PROCESS: int = 0; // Second argument is a PID
export def PRIO_PGRP:    int = 1; // Second argument is a GID
export def PRIO_USER:    int = 2; // Second argument is a UID

// <sys/unistd.h>: access function
export def F_OK: int = 0;    // test for existence of file
export def X_OK: int = 0x01; // test for execute or search permission
export def W_OK: int = 0x02; // test for write permission
export def R_OK: int = 0x04; // test for read permission

// <time.h>: enum clockid_t
// export type clockid_t = int;
// export def CLOCK_REALTIME            : int = 0;
// export def CLOCK_MONOTONIC           : int = 6;
// export def CLOCK_MONOTONIC_RAW       : int = 4;
// export def CLOCK_MONOTONIC_RAW_APPROX: int = 5;
// export def CLOCK_UPTIME_RAW          : int = 8;
// export def CLOCK_UPTIME_RAW_APPROX   : int = 9;
// export def CLOCK_PROCESS_CPUTIME_ID  : int = 12;
// export def CLOCK_THREAD_CPUTIME_ID   : int = 16;
export type clockid_t = enum int {
    CLOCK_REALTIME             = 0,
    CLOCK_MONOTONIC            = 6,
    CLOCK_MONOTONIC_RAW        = 4,
    CLOCK_MONOTONIC_RAW_APPROX = 5,
    CLOCK_UPTIME_RAW           = 8,
    CLOCK_UPTIME_RAW_APPROX    = 9,
    CLOCK_PROCESS_CPUTIME_ID   = 12,
    CLOCK_THREAD_CPUTIME_ID    = 16,
};

// <sys/wait.h>
export def WNOHANG:    int = 0x00000001; // [XSI] no hang in wait/no child to reap
export def WUNTRACED:  int = 0x00000002; // [XSI] notify on stop, untraced child
export def WSTOPPED:   int = 0x00000008; // [XSI] Any child stopped by signal
export def WCONTINUED: int = 0x00000010; // [XSI] Any child stopped then continued
export def WNOWAIT:    int = 0x00000020; // [XSI] Leave process returned waitable
export def WEXITED:    int = 0x00000004; // [XSI] Processes which have exitted

// <unistd.h>
export def STDIN_FILENO:  int = 0;
export def STDOUT_FILENO: int = 1;
export def STDERR_FILENO: int = 2;

export def SEEK_SET: int = 0; // set file offset to offset
export def SEEK_CUR: int = 1; // set file offset to current plus offset
export def SEEK_END: int = 2; // set file offset to EOF plus offset

// <sys/fcntl.h>
// lock operations for flock(2)
export def LOCK_SH: int = 0x01; // shared file lock
export def LOCK_EX: int = 0x02; // exclusive file lock
export def LOCK_NB: int = 0x04; // don't block when locking
export def LOCK_UN: int = 0x08; // unlock file

// <sys/resource.h>
// A structure representing a resource limit.  The address of an instance
// of this structure is the second parameter to getrlimit()/setrlimit().
export type rlimit = struct {
    rlim_cur: rlim_t,   // current (soft) limit
    rlim_max: rlim_t,   // maximum value for rlim_cur
};

// Symbolic constants for resource limits; since all limits are representable
// as a type rlim_t, we are permitted to define RLIM_SAVED_* in terms of
// RLIM_INFINITY.
// export def RLIM_INFINITY: rlim_t = -1;
export def RLIM_INFINITY: rlim_t = ((1u64 << 63) - 1);  // no limit

// Possible values of the first parameter to getrlimit()/setrlimit(), to
// indicate for which resource the operation is being performed.
export def RLIMIT_CPU:         int = 0;         // cpu time per process
export def RLIMIT_FSIZE:       int = 1;         // file size
export def RLIMIT_DATA:        int = 2;         // data segment size
export def RLIMIT_STACK:       int = 3;         // stack size
export def RLIMIT_CORE:        int = 4;         // core file size
export def RLIMIT_AS:          int = 5;         // address space (resident set size)
export def RLIMIT_RSS:         int = RLIMIT_AS; // source compatibility alias
export def RLIMIT_MEMLOCK:     int = 6;         // locked-in-memory address space
export def RLIMIT_NPROC:       int = 7;         // number of processes
export def RLIMIT_NOFILE:      int = 8;         // number of open files
export def RLIM_NLIMITS:       int = 9;         // total number of resource limits
export def _RLIMIT_POSIX_FLAG: int = 0x1000;    // Set bit for strict POSIX

// <sys/socket.h>
export def SHUT_RD  : int = 0; // shut down the reading side
export def SHUT_WR  : int = 1; // shut down the writing side
export def SHUT_RDWR: int = 2; // shut down both sides

// __DARWIN_C_LEVEL >= __DARWIN_C_FULL: true
// !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE): true
//      默认都没定义
