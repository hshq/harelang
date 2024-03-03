// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use crypto::cipher;

def MAXEXPKEYSZ: size = CT64_EXPKEYSZ;
def MAXNPARALLEL: size = CT64_NPARALLEL;

let rtvtable: *cipher::blockvtable = &ct64_vtable;
let initfuncptr: *initfunc = &ct64_init;

@init fn init() void = {
	if (x86ni_available()) {
		hwsup = true;
		rtvtable = &x86ni_vtable;
		initfuncptr = &x86ni_init;
	};
};
