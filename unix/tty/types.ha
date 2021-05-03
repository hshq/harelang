use errors;

export type error = !(errors::invalid | errors::unsupported | errors::noentry);

export type ttysize = struct {
	rows:    u16,
	columns: u16,
};
