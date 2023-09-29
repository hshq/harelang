// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type siginfo = struct {
	si_signo: int,
	si_errno: int,
	si_code: int,
	si_pid: pid_t,
	si_uid: uid_t,
	si_status: int,
	si_addr: *opaque,
	si_value: sigval,
	_reason: union {
		_fault: struct {
			_trapno: int,
		},
		_timer: struct {
			_timerid: int,
			_overrun: int,
		},
		_mesgq: struct {
			_mqd: int,
		},
		_poll: struct {
			_band: i64,
		},
		__spare__: struct {
			__spare1__: i64,
			__spare2__: [7]int,
		},
	},
};

