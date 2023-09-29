// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

let want_abort = false;

// Expect the currently running test to abort. The test will fail if it doesn't
// abort.
export fn expectabort() void = want_abort = true;
