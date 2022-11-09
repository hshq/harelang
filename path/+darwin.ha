// License: MPL-2.0
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>

// Platform-specific path separator byte.
export def PATHSEP: u8 = '/';

const pathsepstr: str = "/";

// Maximum length of a file path for this platform.
export def PATH_MAX: size = 1024;
