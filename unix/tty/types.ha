use errors;

// Any error that may occur during TTY-related tasks.
export type error = !(errors::invalid | errors::unsupported | errors::noentry);

// Structure representing dimensions of a terminal.
export type ttysize = struct {
	rows:    u16,
	columns: u16,
};
