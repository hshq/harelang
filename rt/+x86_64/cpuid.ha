// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type cpuid_vendor = enum {
	AMD,
	INTEL,
	WINCHIP,
	TRANSMETA,
	CYRIX,
	CENTAUR,
	NEXGEN,
	UMC,
	SIS,
	NSC,
	RISE,
	VORTEX,
	VIA,
	ZHAOXIN,
	HYGON,
	MCST_ELBRUS,

	// Virtual Machines.
	VMWARE,
	XENHVM,
	MICROSOFT_HV,
	PARALLELS,
};

export type cpuid_unknownvendor = !void;

// cpuid vendor list taken from https://wiki.osdev.org/CPUID and
// https://en.wikipedia.org/wiki/CPUID
// Order and len matches the entries in the cpuid_vendor enum.
const vendors: [_]str = [
	"AuthenticAMD",
	"GenuineIntel",
	"CentaurHauls",
	"GenuineTMx86",
	"CyrixInstead",
	"CentaurHauls",
	"NexGenDriven",
	"UMC UMC UMC ",
	"SiS SiS SiS ",
	"Geode by NSC",
	"RiseRiseRise",
	"Vortex86 SoC",
	"VIA VIA VIA ",
	"  Shanghai  ",
	"HygonGenuine",
	"E2K MACHINE",
	"VMwareVMware",
	"XenVMMXenVMM",
	"Microsoft Hv",
	" lrpepyh vr",
];

def VENDOR_OLDAMD: str = "AMDisbetter!";
def VENDOR_OLDTRANSMETA: str = "TransmetaCPU";

export type cpuid_edxflag = enum uint {
	SSE = 1 << 25,
	SSE2 = 1 << 26,
};

export type cpuid_ecxflag = enum uint {
	SSE3 = 1 << 0,
	AES = 1 << 25,
	AVX = 1 << 28,
};

fn cpuid_getvendorstr(v: *[12]u8) void;

fn cpuid_getfeatureflags(flags: *[2]u32) void;

// Figures out cpu vendor using cpuid
export fn cpuid_getvendor() (cpuid_vendor | cpuid_unknownvendor) = {
	let vstr: [12]u8 = [0...];
	cpuid_getvendorstr(&vstr);

	for (let i = 0z; i < len(vendors); i += 1) {
		if (bytes_equal(vstr, strings_toutf8(vendors[i]))) {
			return i: cpuid_vendor;
		};
	};

	// some vendors changed their strings in between cpu revisions
	if (bytes_equal(vstr, strings_toutf8(VENDOR_OLDAMD))) {
		return cpuid_vendor::AMD;
	};

	if (bytes_equal(vstr, strings_toutf8(VENDOR_OLDTRANSMETA))) {
		return cpuid_vendor::TRANSMETA;
	};

	return cpuid_unknownvendor;
};

// Checks if cpu has given features. See [[cpuid_edxflag]] and
// [[cpuid_ecxflag]] for available options.
export fn cpuid_hasflags(edx: u32, ecx: u32) bool = {
	let flags: [2]u32 = [0...];
	cpuid_getfeatureflags(&flags);

	return flags[0] & edx == edx && flags[1] & ecx == ecx;
};

// we can't use strings in rt so we add a helper here
fn strings_toutf8(s: str) []u8 = {
	return *(&s: *[]u8);
};

fn bytes_equal(a: []u8, b: []u8) bool = {
	if (len(a) != len(b)) {
		return false;
	};

	for (let i = 0z; i < len(a); i += 1) {
		if (a[i] != b[i]) {
			return false;
		};
	};
	return true;
};
