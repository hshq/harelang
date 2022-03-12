use time;

// Represents a system for ordering days as dates and eras.
// Allows conversion between [[date]] types.
export type calendar = struct {
	// TODO
	TODO: bool,
};

export type localdate = struct {
	nday: i64,
};

export type localtime = struct {
	ntime: time::duration,
};
