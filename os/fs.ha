use fs;

// Provides an implementation of [fs::fs] for the host filesystem.
export let root: *fs::fs = null: *fs::fs;

// Provides an implementation of [fs::fs] for the current working directory.
export let cwd: *fs::fs = null: *fs::fs;
