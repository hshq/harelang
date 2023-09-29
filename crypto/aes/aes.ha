// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use crypto::cipher;

def MAXEXPKEYSZ: size = CT64_EXPKEYSZ;
def MAXNPARALLEL: size = CT64_NPARALLEL;

const rtvtable: *cipher::blockvtable = &ct64_vtable;
const initfuncptr: *initfunc = &ct64_init;
