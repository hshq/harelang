// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use debug::image;
use rt;
use unix::signal;
use unix::signal::{sig};
use fmt;

// altstack.s
let altstack: [ALTSTACK_SIZE]uintptr;

// 16 KiB, sync with altstack.s
def ALTSTACK_SIZE: size = 16384;

@init fn init_overflow() void = {
	rt::sigaltstack(&rt::stack_t {
		ss_sp = rt::malloc(ALTSTACK_SIZE): *opaque,
		ss_flags = 0,
		ss_size = ALTSTACK_SIZE,
	}, null)!;
	signal::handle(sig::SEGV, &signal_handler, signal::flag::ONSTACK);
	signal::handle(sig::FPE, &signal_handler, signal::flag::ONSTACK);
	signal::handle(sig::BUS, &signal_handler, signal::flag::ONSTACK);
	signal::handle(sig::ILL, &signal_handler, signal::flag::ONSTACK);
};

fn signal_handler(sig: sig, info: *signal::siginfo, uctx: *opaque) void = {
	signal::resetall();

	const ip = uctx_ip(uctx);
	const sp = uctx_sp(uctx);
	const addr = info.addr: uintptr;
	let frame = uctx_frame(uctx);

	switch (sig) {
	case sig::SEGV =>
		const is_overflow = addr & ~0xFFFF == sp & ~0xFFFF;
		fmt::errorfln("{} ({}) at address 0x{:x}",
			if (is_overflow) "Stack overflow"
			else "Illegal pointer access",
			errcode_str(sig, info.code), addr): void;
	case sig::BUS =>
		fmt::errorfln("Bus error ({}) at address 0x{:x}",
			errcode_str(sig, info.code), addr): void;
	case sig::FPE =>
		// addr is the location of the faulting instruction, construct
		// an additional synethetic stack frame
		let copy = frame; frame = mkframe(&copy, addr);
		fmt::errorfln("Arithmetic exception ({})",
			errcode_str(sig, info.code)): void;
	case => void;
	};

	const self = match (image::self()) {
	case let img: image::image =>
		yield img;
	case => halt();
	};
	defer image::close(&self);

	fmt::errorln("Backtrace:")!;
	backtrace(&self, frame);

	halt();
};

fn errcode_str(sig: sig, code: signal::code) const str = {
	// Note: this only handles a few cases by design
	// It also is limited only to error codes defined by POSIX
	switch (sig) {
	case sig::ILL =>
		switch (code) {
		case signal::code::ILLOPC => return "illegal opcode";
		case signal::code::ILLOPN => return "illegal operand";
		case signal::code::ILLADR => return "illegal addressing mode";
		case signal::code::ILLTRP => return "illegal trap";
		case signal::code::PRVOPC => return "privileged opcode";
		case signal::code::PRVREG => return "privileged register";
		case signal::code::COPROC => return "coprocessor error";
		case signal::code::BADSTK => return "internal stack error";
		case => void;
		};
	case sig::FPE =>
		switch (code) {
		case signal::code::INTDIV => return "integer divide by zero";
		case signal::code::INTOVF => return "integer overflow";
		case signal::code::FLTDIV => return "floating-point divide by zero";
		case signal::code::FLTOVF => return "floating-point overflow";
		case signal::code::FLTUND => return "floating-point underflow";
		case signal::code::FLTRES => return "floating-point inexact result";
		case signal::code::FLTINV => return "invalid floating-point operation";
		case signal::code::FLTSUB => return "subscript out of range";
		case => void;
		};
	case sig::SEGV =>
		switch (code) {
		case signal::code::MAPERR => return "address not mapped to object";
		case signal::code::ACCERR => return "invalid permissions for mapped object";
		case => void;
		};
	case sig::BUS =>
		switch (code) {
		case signal::code::ADRALN => return "invalid address alignment";
		case signal::code::ADRERR => return "nonexistent physical address";
		case signal::code::OBJERR => return "object-specific hardware error";
		case => void;
		};
	case => void;
	};

	return "unknown reason";
};
