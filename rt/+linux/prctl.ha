// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export def PR_SET_PDEATHSIG = 1;
export def PR_GET_PDEATHSIG = 2;
export def PR_GET_DUMPABLE = 3;
export def PR_SET_DUMPABLE = 4;
export def PR_GET_UNALIGN = 5;
export def PR_SET_UNALIGN = 6;
export def PR_UNALIGN_NOPRINT = 1;
export def PR_UNALIGN_SIGBUS = 2;
export def PR_GET_KEEPCAPS = 7;
export def PR_SET_KEEPCAPS = 8;
export def PR_GET_FPEMU = 9;
export def PR_SET_FPEMU = 10;
export def PR_FPEMU_NOPRINT = 1;
export def PR_FPEMU_SIGFPE = 2;
export def PR_GET_FPEXC = 11;
export def PR_SET_FPEXC = 12;
export def PR_FP_EXC_SW_ENABLE = 0x80;
export def PR_FP_EXC_DIV = 0x010000;
export def PR_FP_EXC_OVF = 0x020000;
export def PR_FP_EXC_UND = 0x040000;
export def PR_FP_EXC_RES = 0x080000;
export def PR_FP_EXC_INV = 0x100000;
export def PR_FP_EXC_DISABLED = 0;
export def PR_FP_EXC_NONRECOV = 1;
export def PR_FP_EXC_ASYNC = 2;
export def PR_FP_EXC_PRECISE = 3;
export def PR_GET_TIMING = 13;
export def PR_SET_TIMING = 14;
export def PR_TIMING_STATISTICAL = 0;
export def PR_TIMING_TIMESTAMP = 1;
export def PR_SET_NAME = 15;
export def PR_GET_NAME = 16;
export def PR_GET_ENDIAN = 19;
export def PR_SET_ENDIAN = 20;
export def PR_ENDIAN_BIG = 0;
export def PR_ENDIAN_LITTLE = 1;
export def PR_ENDIAN_PPC_LITTLE = 2;
export def PR_GET_SECCOMP = 21;
export def PR_SET_SECCOMP = 22;
export def PR_CAPBSET_READ = 23;
export def PR_CAPBSET_DROP = 24;
export def PR_GET_TSC = 25;
export def PR_SET_TSC = 26;
export def PR_TSC_ENABLE = 1;
export def PR_TSC_SIGSEGV = 2;
export def PR_GET_SECUREBITS = 27;
export def PR_SET_SECUREBITS = 28;
export def PR_SET_TIMERSLACK = 29;
export def PR_GET_TIMERSLACK = 30;

export def PR_TASK_PERF_EVENTS_DISABLE = 31;
export def PR_TASK_PERF_EVENTS_ENABLE = 32;

export def PR_MCE_KILL = 33;
export def PR_MCE_KILL_CLEAR = 0;
export def PR_MCE_KILL_SET = 1;
export def PR_MCE_KILL_LATE = 0;
export def PR_MCE_KILL_EARLY = 1;
export def PR_MCE_KILL_DEFAULT = 2;
export def PR_MCE_KILL_GET = 34;

export def PR_SET_MM = 35;
export def PR_SET_MM_START_CODE = 1;
export def PR_SET_MM_END_CODE = 2;
export def PR_SET_MM_START_DATA = 3;
export def PR_SET_MM_END_DATA = 4;
export def PR_SET_MM_START_STACK = 5;
export def PR_SET_MM_START_BRK = 6;
export def PR_SET_MM_BRK = 7;
export def PR_SET_MM_ARG_START = 8;
export def PR_SET_MM_ARG_END = 9;
export def PR_SET_MM_ENV_START = 10;
export def PR_SET_MM_ENV_END = 11;
export def PR_SET_MM_AUXV = 12;
export def PR_SET_MM_EXE_FILE = 13;
export def PR_SET_MM_MAP = 14;
export def PR_SET_MM_MAP_SIZE = 15;

export type prctl_mm_map = struct {
	start_code: u64,
	end_code: u64,
	start_data: u64,
	end_data: u64,
	start_brk: u64,
	brk: u64,
	start_stack: u64,
	arg_start: u64,
	arg_end: u64,
	env_start: u64,
	env_end: u64,
	auxv: *u64,
	auxv_size: u32,
	exe_fd: u32,
};

export def PR_SET_PTRACER = 0x59616d61;
export def PR_SET_PTRACER_ANY = -1;

export def PR_SET_CHILD_SUBREAPER = 36;
export def PR_GET_CHILD_SUBREAPER = 37;

export def PR_SET_NO_NEW_PRIVS = 38;
export def PR_GET_NO_NEW_PRIVS = 39;

export def PR_GET_TID_ADDRESS = 40;

export def PR_SET_THP_DISABLE = 41;
export def PR_GET_THP_DISABLE = 42;

export def PR_MPX_ENABLE_MANAGEMENT = 43;
export def PR_MPX_DISABLE_MANAGEMENT = 44;

export def PR_SET_FP_MODE = 45;
export def PR_GET_FP_MODE = 46;
export def PR_FP_MODE_FR = 1 << 0;
export def PR_FP_MODE_FRE = 1 << 1;

export def PR_CAP_AMBIENT = 47;
export def PR_CAP_AMBIENT_IS_SET = 1;
export def PR_CAP_AMBIENT_RAISE = 2;
export def PR_CAP_AMBIENT_LOWER = 3;
export def PR_CAP_AMBIENT_CLEAR_ALL = 4;

export def PR_SVE_SET_VL = 50;
export def PR_SVE_SET_VL_ONEXEC = 1 << 18;
export def PR_SVE_GET_VL = 51;
export def PR_SVE_VL_LEN_MASK = 0xffff;
export def PR_SVE_VL_INHERIT = 1 << 17;

export def PR_GET_SPECULATION_CTRL = 52;
export def PR_SET_SPECULATION_CTRL = 53;
export def PR_SPEC_STORE_BYPASS = 0;
export def PR_SPEC_INDIRECT_BRANCH = 1;
export def PR_SPEC_NOT_AFFECTED = 0;
export def PR_SPEC_PRCTL = 1 << 0;
export def PR_SPEC_ENABLE = 1 << 1;
export def PR_SPEC_DISABLE = 1 << 2;
export def PR_SPEC_FORCE_DISABLE = 1 << 3;
export def PR_SPEC_DISABLE_NOEXEC = 1 << 4;

export def PR_PAC_RESET_KEYS = 54;
export def PR_PAC_APIAKEY = 1 << 0;
export def PR_PAC_APIBKEY = 1 << 1;
export def PR_PAC_APDAKEY = 1 << 2;
export def PR_PAC_APDBKEY = 1 << 3;
export def PR_PAC_APGAKEY = 1 << 4;

export def PR_SET_TAGGED_ADDR_CTRL = 55;
export def PR_GET_TAGGED_ADDR_CTRL = 56;
export def PR_TAGGED_ADDR_ENABLE = 1 << 0;
export def PR_MTE_TCF_SHIFT = 1;
export def PR_MTE_TCF_NONE = 0 << 1;
export def PR_MTE_TCF_SYNC = 1 << 1;
export def PR_MTE_TCF_ASYNC = 2 << 1;
export def PR_MTE_TCF_MASK = 3 << 1;
export def PR_MTE_TAG_SHIFT = 3;
export def PR_MTE_TAG_MASK = 0xffff << 3;

export def PR_SET_IO_FLUSHER = 57;
export def PR_GET_IO_FLUSHER = 58;

export def PR_SET_SYSCALL_USER_DISPATCH = 59;
export def PR_SYS_DISPATCH_OFF = 0;
export def PR_SYS_DISPATCH_ON = 1;
export def SYSCALL_DISPATCH_FILTER_ALLOW = 0;
export def SYSCALL_DISPATCH_FILTER_BLOCK = 1;
