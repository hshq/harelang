// License: MPL-2.0
// (c) 2021 Eyal Sawady <ecs@d2evs.net>

export def PR_SET_PDEATHSIG: int = 1;
export def PR_GET_PDEATHSIG: int = 2;
export def PR_GET_DUMPABLE: u64 = 3;
export def PR_SET_DUMPABLE: int = 4;
export def PR_GET_UNALIGN: int = 5;
export def PR_SET_UNALIGN: int = 6;
export def PR_UNALIGN_NOPRINT: u64 = 1;
export def PR_UNALIGN_SIGBUS: u64 = 2;
export def PR_GET_KEEPCAPS: int = 7;
export def PR_SET_KEEPCAPS: int = 8;
export def PR_GET_FPEMU: int = 9;
export def PR_SET_FPEMU: int = 10;
export def PR_FPEMU_NOPRINT: u64 = 1;
export def PR_FPEMU_SIGFPE: u64 = 2;
export def PR_GET_FPEXC: int = 11;
export def PR_SET_FPEXC: int = 12;
export def PR_FP_EXC_SW_ENABLE: u64 = 0x80;
export def PR_FP_EXC_DIV: u64 = 0x010000;
export def PR_FP_EXC_OVF: u64 = 0x020000;
export def PR_FP_EXC_UND: u64 = 0x040000;
export def PR_FP_EXC_RES: u64 = 0x080000;
export def PR_FP_EXC_INV: u64 = 0x100000;
export def PR_FP_EXC_DISABLED: u64 = 0;
export def PR_FP_EXC_NONRECOV: u64 = 1;
export def PR_FP_EXC_ASYNC: u64 = 2;
export def PR_FP_EXC_PRECISE: u64 = 3;
export def PR_GET_TIMING: int = 13;
export def PR_SET_TIMING: int = 14;
export def PR_TIMING_STATISTICAL: u64 = 0;
export def PR_TIMING_TIMESTAMP: u64 = 1;
export def PR_SET_NAME: int = 15;
export def PR_GET_NAME: int = 16;
export def PR_GET_ENDIAN: int = 19;
export def PR_SET_ENDIAN: int = 20;
export def PR_ENDIAN_BIG: u64 = 0;
export def PR_ENDIAN_LITTLE: u64 = 1;
export def PR_ENDIAN_PPC_LITTLE: u64 = 2;
export def PR_GET_SECCOMP: int = 21;
export def PR_SET_SECCOMP: int = 22;
export def PR_CAPBSET_READ: int = 23;
export def PR_CAPBSET_DROP: int = 24;
export def PR_GET_TSC: int = 25;
export def PR_SET_TSC: int = 26;
export def PR_TSC_ENABLE: u64 = 1;
export def PR_TSC_SIGSEGV: u64 = 2;
export def PR_GET_SECUREBITS: int = 27;
export def PR_SET_SECUREBITS: int = 28;
export def PR_SET_TIMERSLACK: int = 29;
export def PR_GET_TIMERSLACK: int = 30;

export def PR_TASK_PERF_EVENTS_DISABLE: int = 31;
export def PR_TASK_PERF_EVENTS_ENABLE: int = 32;

export def PR_MCE_KILL: int = 33;
export def PR_MCE_KILL_CLEAR: u64 = 0;
export def PR_MCE_KILL_SET: u64 = 1;
export def PR_MCE_KILL_LATE: u64 = 0;
export def PR_MCE_KILL_EARLY: u64 = 1;
export def PR_MCE_KILL_DEFAULT: u64 = 2;
export def PR_MCE_KILL_GET: int = 34;

export def PR_SET_MM: int = 35;
export def PR_SET_MM_START_CODE: u64 = 1;
export def PR_SET_MM_END_CODE: u64 = 2;
export def PR_SET_MM_START_DATA: u64 = 3;
export def PR_SET_MM_END_DATA: u64 = 4;
export def PR_SET_MM_START_STACK: u64 = 5;
export def PR_SET_MM_START_BRK: u64 = 6;
export def PR_SET_MM_BRK: u64 = 7;
export def PR_SET_MM_ARG_START: u64 = 8;
export def PR_SET_MM_ARG_END: u64 = 9;
export def PR_SET_MM_ENV_START: u64 = 10;
export def PR_SET_MM_ENV_END: u64 = 11;
export def PR_SET_MM_AUXV: u64 = 12;
export def PR_SET_MM_EXE_FILE: u64 = 13;
export def PR_SET_MM_MAP: u64 = 14;
export def PR_SET_MM_MAP_SIZE: u64 = 15;

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

export def PR_SET_PTRACER: int = 0x59616d61;
export def PR_SET_PTRACER_ANY: u64 = -1;

export def PR_SET_CHILD_SUBREAPER: int = 36;
export def PR_GET_CHILD_SUBREAPER: int = 37;

export def PR_SET_NO_NEW_PRIVS: int = 38;
export def PR_GET_NO_NEW_PRIVS: int = 39;

export def PR_GET_TID_ADDRESS: int = 40;

export def PR_SET_THP_DISABLE: int = 41;
export def PR_GET_THP_DISABLE: int = 42;

export def PR_MPX_ENABLE_MANAGEMENT: int = 43;
export def PR_MPX_DISABLE_MANAGEMENT: int = 44;

export def PR_SET_FP_MODE: int = 45;
export def PR_GET_FP_MODE: int = 46;
export def PR_FP_MODE_FR: u64 = 1 << 0;
export def PR_FP_MODE_FRE: u64 = 1 << 1;

export def PR_CAP_AMBIENT: int = 47;
export def PR_CAP_AMBIENT_IS_SET: u64 = 1;
export def PR_CAP_AMBIENT_RAISE: u64 = 2;
export def PR_CAP_AMBIENT_LOWER: u64 = 3;
export def PR_CAP_AMBIENT_CLEAR_ALL: u64 = 4;

export def PR_SVE_SET_VL: int = 50;
export def PR_SVE_SET_VL_ONEXEC: u64 = 1 << 18;
export def PR_SVE_GET_VL: int = 51;
export def PR_SVE_VL_LEN_MASK: u64 = 0xffff;
export def PR_SVE_VL_INHERIT: u64 = 1 << 17;

export def PR_GET_SPECULATION_CTRL: int = 52;
export def PR_SET_SPECULATION_CTRL: int = 53;
export def PR_SPEC_STORE_BYPASS: u64 = 0;
export def PR_SPEC_INDIRECT_BRANCH: u64 = 1;
export def PR_SPEC_NOT_AFFECTED: u64 = 0;
export def PR_SPEC_PRCTL: u64 = 1 << 0;
export def PR_SPEC_ENABLE: u64 = 1 << 1;
export def PR_SPEC_DISABLE: u64 = 1 << 2;
export def PR_SPEC_FORCE_DISABLE: u64 = 1 << 3;
export def PR_SPEC_DISABLE_NOEXEC: u64 = 1 << 4;

export def PR_PAC_RESET_KEYS: int = 54;
export def PR_PAC_APIAKEY: u64 = 1 << 0;
export def PR_PAC_APIBKEY: u64 = 1 << 1;
export def PR_PAC_APDAKEY: u64 = 1 << 2;
export def PR_PAC_APDBKEY: u64 = 1 << 3;
export def PR_PAC_APGAKEY: u64 = 1 << 4;

export def PR_SET_TAGGED_ADDR_CTRL: int = 55;
export def PR_GET_TAGGED_ADDR_CTRL: int = 56;
export def PR_TAGGED_ADDR_ENABLE: u64 = 1 << 0;
export def PR_MTE_TCF_SHIFT: u64 = 1;
export def PR_MTE_TCF_NONE: u64 = 0 << 1;
export def PR_MTE_TCF_SYNC: u64 = 1 << 1;
export def PR_MTE_TCF_ASYNC: u64 = 2 << 1;
export def PR_MTE_TCF_MASK: u64 = 3 << 1;
export def PR_MTE_TAG_SHIFT: u64 = 3;
export def PR_MTE_TAG_MASK: u64 = 0xffff << 3;

export def PR_SET_IO_FLUSHER: int = 57;
export def PR_GET_IO_FLUSHER: int = 58;

export def PR_SET_SYSCALL_USER_DISPATCH: int = 59;
export def PR_SYS_DISPATCH_OFF: u64 = 0;
export def PR_SYS_DISPATCH_ON: u64 = 1;
export def SYSCALL_DISPATCH_FILTER_ALLOW: u64 = 0;
export def SYSCALL_DISPATCH_FILTER_BLOCK: u64 = 1;
