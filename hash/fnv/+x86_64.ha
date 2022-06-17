// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2022 Sebastian <sebastian@sebsite.pw>

// Hashes a string, returning a size key, for use in a hash map.
export fn string(s: str) size = string64(s): size;
