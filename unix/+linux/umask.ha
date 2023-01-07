// License: MPL-2.0
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2021 Umar Getagazov <umar@handlerug.me>
use errors;
use fs;
use rt;

// Sets the file mode creation mask for the current process and return the
// previous value of the mask.
export fn umask(mode: fs::mode) fs::mode = rt::umask(mode)!: fs::mode;
