// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Kiëd Llaentenn <kiedtl@tilde.team>
use errors;

// Any error that may occur during TTY-related tasks.
export type error = !(errors::invalid
					| errors::unsupported
					| errors::noentry
					| errors::overflow);

// Converts an [[error]] to a human-friendly string.
export fn strerror(err: error) str = {
	return errors::strerror(err);
};

// Structure representing dimensions of a terminal.
export type ttysize = struct {
	rows:    u16,
	columns: u16,
};
