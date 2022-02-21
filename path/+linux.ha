// License: MPL-2.0
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>

// Path separator, platform-specific.
export def PATHSEP: u8 = '/': u32: u8;

// Maximum length of a file path for this platform.
export def PATH_MAX: size = 4096;
