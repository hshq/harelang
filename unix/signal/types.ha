// License: MPL-2.0
// (c) 2022 Drew DeVault <sir@cmpwn.com>

// A function which handles a signal. The first argument is the signal number
// which was caught, the second provides information about the signal, and the
// third argument is the ucontext, which is usually ignored by most signal
// handlers.
export type handler = fn(sig: int, info: *siginfo, ucontext: *void) void;
