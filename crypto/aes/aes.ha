// License: MPL-2.0
// (c) 2022 Armin Preiml <apreiml@strohwolke.at>
use crypto::cipher;

def MAXEXPKEYSIZE: size = CT64_EXPKEYSIZE;
def MAXNPARALLEL: size = CT64_NPARALLEL;

const rtvtable: *cipher::blockvtable = &ct64_vtable;
const initfuncptr: *initfunc = &ct64_init;
