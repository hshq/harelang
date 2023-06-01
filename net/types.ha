// The end of the full-duplex connection that should be [[shutdown]].
export type shut = enum {
	RD, // Disables further receptions.
	WR, // Disables further transmissions.
	RDWR, // Disables further receptions and transmissions.
};
