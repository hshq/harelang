// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use errors;
use fs;
use rt;

// Sets the file mode creation mask for the current process and return the
// previous value of the mask.
export fn umask(mode: fs::mode) fs::mode = rt::umask(mode: rt::mode_t): fs::mode;
