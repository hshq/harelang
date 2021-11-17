use bytes;

// Returns true if 'in' has the given prefix.
export fn hasprefix(in: str, prefix: str) bool = bytes::hasprefix(toutf8(in), toutf8(prefix));

// Returns true if 'in' has the given prefix.
export fn hassuffix(in: str, suff: str) bool = bytes::hassuffix(toutf8(in), toutf8(suff));
