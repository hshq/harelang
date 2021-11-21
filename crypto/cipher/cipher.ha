// An abstract interface for implementing block ciphers.
export type block = struct {
	sz: size,

	nparallel: size,

	encrypt: *fn(b: *block, dest: []u8, src: []u8) void,
	decrypt: *fn(b: *block, dest: []u8, src: []u8) void,
};

 // Returns the blocksize in bytes
export fn sz(b: *block) size = b.sz;

// The number of blocks that can be processed at once at encrypt or decrypt
export fn nparallel(b: *block) size = b.nparallel;

// Encrypt up to nparallel blocks of size sz of src data and write it to dest
export fn encrypt(b: *block, dest: []u8, src: []u8) void =
	b.encrypt(b, dest, src);

// Decrypt up to nparallel blocks of size sz of src data and write it to dest
export fn decrypt(b: *block, dest: []u8, src: []u8) void =
	b.decrypt(b, dest, src);
