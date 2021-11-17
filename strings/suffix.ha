use bytes;

// Returns true if 'in' has the given prefix.
export fn has_prefix(in: str, prefix: str) bool = bytes::hasprefix(toutf8(in), toutf8(prefix));

// Returns true if 'in' has the given prefix.
export fn has_suffix(in: str, suff: str) bool = bytes::hassuffix(toutf8(in), toutf8(suff));
