fn syscall0(u64) u64;
fn syscall1(u64, u64) u64;
fn syscall2(u64, u64, u64) u64;
fn syscall3(u64, u64, u64, u64) u64;
fn syscall4(u64, u64, u64, u64, u64) u64;
fn syscall5(u64, u64, u64, u64, u64, u64) u64;
fn syscall6(u64, u64, u64, u64, u64, u64, u64) u64;

export fn write(fd: int, buf: *const void, count: size) size =
	syscall3(SYS_write, fd: u64, buf: uintptr: u64, count: u64): size;

export fn getpid() int = syscall0(SYS_getpid): int;

export @noreturn fn exit(status: int) void = syscall1(SYS_exit, status: u64);

export fn kill(pid: int, signal: int) int =
	syscall2(SYS_kill, pid: u64, signal: u64): int;

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
