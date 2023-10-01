// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use format::elf;
use linux;
use types::c;

let ehdr: nullable *elf::header64 = null;

fn sys_infoehdr() nullable *elf::header64 = {
	static let ehdr_checked = false;
	if (ehdr_checked) {
		return ehdr;
	};
	ehdr_checked = true;

	for (let i = 0; linux::auxv[i].a_type != 0; i += 1) {
		if (linux::auxv[i].a_type != elf::at::SYSINFO_EHDR)
			continue;
		ehdr = linux::auxv[i].a_val: uintptr: *elf::header64;
		return ehdr;
	};
	return null;
};

type vdso_ctx = struct {
	segbase: uintptr,
	stringtab: *c::char,
	symtab: *[*]elf::sym64,
	hashhdr: *elf::hashhdr,
	versym: nullable *[*]u16,
	verdef: nullable *elf::verdef64,
};

let ctx: nullable *vdso_ctx = null;

fn get_vdso_ctx() nullable *vdso_ctx = {
	static let vdso_checked = false;
	if (vdso_checked) {
		return ctx;
	};
	vdso_checked = true;

	const eh = match (sys_infoehdr()) {
	case null =>
		return null;
	case let x: *elf::header64 =>
		yield x;
	};

	const ehui = eh: uintptr;
	let phui = ehui + eh.e_phoff: uintptr;
	let dynvec: nullable *[*]elf::dyn64 = null;
	let baseseg: nullable *opaque = null;

	for (let i: u16 = 0; i < eh.e_phnum; i += 1) {
		const ph = phui: *elf::phdr64;
		switch (ph.p_type) {
		case elf::pt::LOAD =>
			baseseg = (ehui +
				ph.p_offset: uintptr -
				ph.p_vaddr: uintptr): nullable *opaque;
		case elf::pt::DYNAMIC =>
			dynvec = (ehui +
				ph.p_offset: uintptr): *[*]elf::dyn64;
		case => void;
		};
		phui += eh.e_phentsize: uintptr;
	};

	if (dynvec == null || baseseg == null) {
		return null;
	};
	const dynv = dynvec: *[*]elf::dyn64;

	let segbase = baseseg: uintptr;
	let stringtab: nullable *c::char = null;
	let symtab: nullable *[*]elf::sym64 = null;
	let hashhdr: nullable *elf::hashhdr = null;
	let versym: nullable *[*]u16 = null;
	let verdef: nullable *elf::verdef64 = null;

	for (let i = 0; dynv[i].d_tag != elf::dt::NULL; i += 1) {
		const tabptr = (segbase + dynv[i].d_val: uintptr): *opaque;
		switch (dynv[i].d_tag) {
		case elf::dt::STRTAB =>
			stringtab = tabptr: *c::char;
		case elf::dt::SYMTAB =>
			symtab = tabptr: *[*]elf::sym64;
		case elf::dt::HASH =>
			hashhdr = tabptr: *elf::hashhdr;
		case elf::dt::VERSYM =>
			versym = tabptr: *[*]u16;
		case elf::dt::VERDEF =>
			verdef = tabptr: *elf::verdef64;
		case =>
			continue;
		};
	};

	if (stringtab == null || symtab == null || hashhdr == null) {
		return null;
	};

	if (verdef == null) {
		versym = null;
	};

	// TODO: use a static variable here somehow(?)
	const vctx = alloc(vdso_ctx {
		segbase = segbase,
		stringtab = stringtab: *c::char,
		symtab = symtab: *[*]elf::sym64,
		hashhdr = hashhdr: *elf::hashhdr,
		verdef = verdef,
		versym = versym,
	});
	ctx = vctx;

	return ctx;
};

fn vdso_checkver(ctx: *vdso_ctx, version: str, num: u32) bool = {
	let prev = null: *elf::verdef64;
	let cur = match (ctx.verdef) {
	case null =>
		return true;
	case let vd: *elf::verdef64 =>
		yield vd;
	};
	const versym = match (ctx.versym) {
	case null =>
		return true;
	case let vs: *[*]u16 =>
		yield vs[num] & 0x7ff;
	};
	for (cur != prev) {
		if (cur.vd_flags & elf::ver_flg::BASE: u16 == 0 &&
			cur.vd_ndx & 0x7fff == versym) {
			const aux = (cur: uintptr +
				cur.vd_aux: uintptr): *elf::verdaux64;
			const name = ctx.stringtab: uintptr +
				aux.vda_name: uintptr;
			return version == c::tostr(name: *c::char)!;
		};
		prev = cur;
		cur = (cur: uintptr + cur.vd_next: uintptr): *elf::verdef64;
	};
	return false;
};

export fn getsym(symname: str, symver: str) nullable *opaque = {
	const ctx = match (get_vdso_ctx()) {
	case null =>
		return null;
	case let x: *vdso_ctx =>
		yield x;
	};

	const sym_types = (1 << elf::stt::NOTYPE |
			1 << elf::stt::OBJECT |
			1 << elf::stt::FUNC |
			1 << elf::stt::COMMON): size;

	const sym_binds = (1 << elf::stb::GLOBAL |
			1 << elf::stb::WEAK): size;

	for (let i = 0u32; i < ctx.hashhdr.nchain; i += 1) {
		const sym = ctx.symtab[i];
		const symtype = 1 << (sym.st_info & 0xf): size;
		const symbind = 1 << (sym.st_info >> 4): size;
		if (symtype & sym_types == 0 || symbind & sym_binds == 0 ||
			sym.st_shndx == 0) {
			continue;
		};
		const name = ctx.stringtab: uintptr + sym.st_name: uintptr;
		const s: str = c::tostr(name: *const c::char)!;
		if (s != symname)
			continue;
		if (!vdso_checkver(ctx, symver, i))
			continue;
		return (ctx.segbase + sym.st_value: uintptr): *opaque;
	};
	return null;
};
