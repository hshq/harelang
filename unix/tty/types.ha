use errors;

export type error = (errors::invalid | errors::unsupported)!;

export type ttysize = struct {
	rows:    u16,
	columns: u16,
};
