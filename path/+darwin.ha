// License: MPL-2.0
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>

// Platform-specific path separator byte.
export def SEP: u8 = '/';

const sepstr: str = "/";

// Maximum length of a file path for this platform.
export def MAX: size = 1023;
