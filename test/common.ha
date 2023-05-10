let want_abort = false;

// Expect the currently running test to abort. The test will fail if it doesn't
// abort.
export fn expectabort() void = want_abort = true;
