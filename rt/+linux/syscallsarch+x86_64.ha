// License: MPL-2.0
// (c) 2022 Sebastian <sebastian@sebsite.pw>

export fn alarm(seconds: uint) uint = {
	return syscall1(SYS_alarm, seconds: u64): uint;
};

