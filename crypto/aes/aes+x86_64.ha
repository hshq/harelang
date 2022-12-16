// License: MPL-2.0
// (c) 2022 Armin Preiml <apreiml@strohwolke.at>
use crypto::cipher;

def MAXEXPKEYSIZE: size = CT64_EXPKEYSIZE;
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

