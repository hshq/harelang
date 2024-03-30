// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use hare::ast;
use sort;
use strings;

export def BUCKETS: size = 65535;

// A function which evaluates a [[hare::ast::expr]], providing either a size
// result or an error.
export type resolver = fn(
	rstate: nullable *opaque,
	store: *typestore,
	expr: const *ast::expr,
) (size | deferred | error);

export type typestore = struct {
	// This hash map provides the canonical address for all types owned by
	// this type store. Any type which has a reference to another type has
	// borrowed it from this map.
	map: [BUCKETS][]_type,

	arch: arch,
	resolve: nullable *resolver,
	rstate: nullable *opaque,
};

// Initializes a new type store. Optionally, provide a function which
// type-checks and evaluates an [[hare::ast::expr]]. If a resolver is not
// provided, looking up types with an expression component (e.g. [2 + 2]int)
// will return [[noresolver]].
export fn store(
	arch: arch,
	resolver: nullable *resolver,
	rstate: nullable *opaque,
) *typestore = alloc(typestore {
	arch = arch,
	resolve = resolver,
	rstate = rstate,
	...
});

// Frees state associated with a [[typestore]].
export fn store_free(store: *typestore) void = {
	for (let i = 0z; i < len(store.map); i += 1) {
		for (let j = 0z; j < len(store.map[i]); j += 1) {
			type_finish(&store.map[i][j]);
		};
		free(store.map[i]);
	};
	free(store);
};

// Creates a new type alias.
export fn newalias(
	store: *typestore,
	ident: const ast::ident,
	of: const *_type,
) const *_type = {
	const atype: _type = _type {
		flags = of.flags,
		repr = alias {
			id = ast::ident_dup(ident),
			secondary = of,
		},
		id = 0,
		sz = of.sz,
		_align = of._align,
	};
	const id = hash(&atype);
	atype.id = id;

	// Fill in forward-referenced aliases
	match (lookup(store, &ast::_type {
		repr = ast::alias_type {
			unwrap = false,
			ident = ident,
		},
		...
	})) {
	case error => void;
	case deferred => void;
	case let ty: const *_type =>
		let ty = ty: *_type;
		*ty = atype;
		return ty;
	};

	// Or create a new alias
	let bucket = &store.map[id % BUCKETS];
	append(bucket, atype);
	return &bucket[len(bucket) - 1];
};

// Returned from [[lookup]] when we are unable to resolve this type, but it does
// not necessarily have an error. This occurs when a type includes an unknown
// forward reference.
export type deferred = !void;

// A resolver function was not provided to [[store]], but was required to look
// up this type.
export type noresolver = !void;

// All possible errors for [[lookup]].
export type error = !(noresolver | errors::opaque_);

// Convert an error into a human-friendly string.
export fn strerror(err: error) const str = match (err) {
case noresolver =>
	return "Resolver function not provided, but required";
case let err: errors::opaque_ =>
	return errors::strerror(err);
};

// Retrieves a [[_type]] for a given [[hare::ast::_type]].
export fn lookup(
	store: *typestore,
	ty: *ast::_type,
) (const *_type | deferred | error) = {
	const ty = fromast(store, ty)?;
	if (ty.flags == 0) match (ty.repr) {
	case let b: builtin =>
		switch (b) {
		case builtin::F32 =>
			return &builtin_f32;
		case builtin::F64 =>
			return &builtin_f64;
		case builtin::I8 =>
			return &builtin_i8;
		case builtin::I16 =>
			return &builtin_i16;
		case builtin::I32 =>
			return &builtin_i32;
		case builtin::I64 =>
			return &builtin_i64;
		case builtin::OPAQUE =>
			return &builtin_opaque;
		case builtin::RUNE =>
			return &builtin_rune;
		case builtin::U8 =>
			return &builtin_u8;
		case builtin::U16 =>
			return &builtin_u16;
		case builtin::U32 =>
			return &builtin_u32;
		case builtin::U64 =>
			return &builtin_u64;
		case builtin::VOID =>
			return &builtin_void;
		case builtin::DONE =>
			return &builtin_done;
		case => void;
		};
	case => void;
	};

	const id = hash(&ty);
	let bucket = &store.map[id % BUCKETS];
	for (let i = 0z; i < len(bucket); i += 1) {
		if (bucket[i].id == id) {
			type_finish(&ty);
			return &bucket[i];
		};
	};
	ty.id = id;
	append(bucket, ty);
	return &bucket[len(bucket) - 1];
};

fn fromast(store: *typestore, atype: *ast::_type) (_type | deferred | error) = {
	let sz = SIZE_UNDEFINED, _align = SIZE_UNDEFINED;
	const repr = match (atype.repr) {
	case let a: ast::alias_type =>
		// TODO: This is incomplete
		assert(!a.unwrap);
		yield alias {
			id = ast::ident_dup(a.ident),
			secondary = null,
		};
	case let b: ast::builtin_type =>
		// TODO: Tuple unpacking could improve this
		yield switch (b) {
		case ast::builtin_type::BOOL =>
			sz = store.arch._int;
			_align = store.arch._int;
			yield builtin::BOOL;
		case ast::builtin_type::DONE =>
			sz = 0; _align = 0;
			yield builtin::DONE;
		case ast::builtin_type::F32 =>
			sz = 4; _align = 4;
			yield builtin::F32;
		case ast::builtin_type::F64 =>
			sz = 8; _align = 8;
			yield builtin::F64;
		case ast::builtin_type::I16 =>
			sz = 2; _align = 2;
			yield builtin::I16;
		case ast::builtin_type::I32 =>
			sz = 4; _align = 4;
			yield builtin::I32;
		case ast::builtin_type::I64 =>
			sz = 8; _align = 8;
			yield builtin::I64;
		case ast::builtin_type::I8 =>
			sz = 1; _align = 1;
			yield builtin::I8;
		case ast::builtin_type::INT =>
			sz = store.arch._int;
			_align = store.arch._int;
			yield builtin::INT;
		case ast::builtin_type::RUNE =>
			sz = 4; _align = 4;
			yield builtin::RUNE;
		case ast::builtin_type::SIZE =>
			sz = store.arch._size;
			_align = store.arch._size;
			yield builtin::SIZE;
		case ast::builtin_type::STR =>
			sz = store.arch._pointer;
			sz += sz % store.arch._size + store.arch._size;
			sz += store.arch._size;
			_align = if (store.arch._size > store.arch._pointer)
					store.arch._size
				else
					store.arch._pointer;
			yield builtin::STR;
		case ast::builtin_type::U16 =>
			sz = 2; _align = 2;
			yield builtin::U16;
		case ast::builtin_type::U32 =>
			sz = 4; _align = 4;
			yield builtin::U32;
		case ast::builtin_type::U64 =>
			sz = 8; _align = 8;
			yield builtin::U64;
		case ast::builtin_type::U8 =>
			sz = 1; _align = 1;
			yield builtin::U8;
		case ast::builtin_type::UINT =>
			sz = store.arch._int;
			_align = store.arch._int;
			yield builtin::UINT;
		case ast::builtin_type::UINTPTR =>
			sz = store.arch._pointer;
			_align = store.arch._pointer;
			yield builtin::UINTPTR;
		case ast::builtin_type::VOID =>
			sz = 0; _align = 0;
			yield builtin::VOID;
		case ast::builtin_type::NULL =>
			sz = store.arch._pointer;
			_align = store.arch._pointer;
			yield builtin::NULL;
		case ast::builtin_type::ICONST, ast::builtin_type::FCONST,
			ast::builtin_type::RCONST =>
			abort(); // TODO?
		case ast::builtin_type::OPAQUE =>
			sz = SIZE_UNDEFINED;
			_align = SIZE_UNDEFINED;
			yield builtin::OPAQUE;
		case ast::builtin_type::NEVER =>
			sz = SIZE_UNDEFINED;
			_align = SIZE_UNDEFINED;
			yield builtin::NEVER;
		case ast::builtin_type::VALIST =>
			sz = store.arch.valist_size;
			_align = store.arch.valist_align;
			yield builtin::VALIST;
		};
	case let f: ast::func_type =>
		yield func_from_ast(store, &f)?;
	case let p: ast::pointer_type =>
		sz = store.arch._pointer;
		_align = store.arch._pointer;
		yield pointer {
			referent = lookup(store, p.referent)?,
			flags = p.flags: pointer_flag,
		};
	case let st: ast::struct_type =>
		let st = struct_from_ast(store, st, false)?;
		sz = 0; _align = 0;
		for (let i = 0z; i < len(st.fields); i += 1) {
			const field = st.fields[i];
			if (field.offs + field._type.sz > sz) {
				sz = field.offs + field._type.sz;
			};
			if (field._type._align > _align) {
				_align = field._type._align;
			};
		};
		yield st;
	case let un: ast::union_type =>
		let st = struct_from_ast(store, un, true)?;
		sz = 0; _align = 0;
		for (let i = 0z; i < len(st.fields); i += 1) {
			const field = st.fields[i];
			if (field.offs + field._type.sz > sz) {
				sz = field.offs + field._type.sz;
			};
			if (field._type._align > _align) {
				_align = field._type._align;
			};
		};
		yield st;
	case let ta: ast::tagged_type =>
		let ta = tagged_from_ast(store, ta)?;
		sz = 0; _align = 0;
		for (let i = 0z; i < len(ta); i += 1) {
			if (ta[i].sz > sz) {
				sz = ta[i].sz;
			};
			if (ta[i]._align > _align) {
				_align = ta[i]._align;
			};
		};
		if (store.arch._int > _align) {
			_align = store.arch._int;
		};
		sz += store.arch._int % _align + store.arch._int;
		yield ta;
	case let tu: ast::tuple_type =>
		let tu = tuple_from_ast(store, tu)?;
		sz = 0; _align = 0;
		for (let i = 0z; i < len(tu); i += 1) {
			const value = tu[i];
			if (value.offs + value._type.sz > sz) {
				sz = value.offs + value._type.sz;
			};
			if (value._type._align > _align) {
				_align = value._type._align;
			};
		};
		yield tu;
	case let lt: ast::list_type =>
		let r = list_from_ast(store, &lt)?;
		sz = r.0;
		_align = r.1;
		yield r.2;
	case let et: ast::enum_type =>
		abort(); // TODO
	};
	if (sz != SIZE_UNDEFINED && sz != 0 && sz % _align != 0) {
		sz += _align - (sz - _align) % _align;
	};
	return _type {
		id = 0, // filled in later
		flags = atype.flags: flag,
		repr = repr,
		sz = sz,
		_align = _align,
	};
};

fn func_from_ast(
	store: *typestore,
	ft: *ast::func_type,
) (func | deferred | error) = {
	let f = func {
		result = lookup(store, ft.result)?,
		variadism = switch (ft.variadism) {
		case ast::variadism::NONE =>
			yield variadism::NONE;
		case ast::variadism::C =>
			yield variadism::C;
		case ast::variadism::HARE =>
			yield variadism::HARE;
		},
		params = alloc([], len(ft.params)),
	};
	for (let i = 0z; i < len(ft.params); i += 1) {
		append(f.params, lookup(store, ft.params[i]._type)?);
	};
	return f;
};

fn list_from_ast(
	store: *typestore,
	lt: *ast::list_type
) ((size, size, (slice | array)) | deferred | error) = {
	let sz = SIZE_UNDEFINED, _align = SIZE_UNDEFINED;
	let memb = lookup(store, lt.members)?;
	let t = match (lt.length) {
	case ast::len_slice =>
		sz = store.arch._pointer;
		if (sz % store.arch._size != 0) {
			sz += store.arch._size - (sz % store.arch._size);
		};
		sz += store.arch._size * 2;
		_align = if (store.arch._pointer > store.arch._size)
				store.arch._pointer
			else store.arch._size;
		yield memb: slice;
	case (ast::len_unbounded | ast::len_contextual) =>
		// Note: contextual length is handled by hare::unit when
		// initializing bindings. We treat it like unbounded here and
		// it's fixed up later on.
		_align = memb._align;
		yield array {
			length = SIZE_UNDEFINED,
			member = memb,
		};
	case let ex: *ast::expr =>
		const resolv = match (store.resolve) {
		case null =>
			return noresolver;
		case let r: *resolver =>
			yield r;
		};
		const length = resolv(store.rstate, store, ex)?;
		sz = memb.sz * length;
		assert(sz / length == memb.sz, "overflow");
		_align = memb._align;
		yield array {
			length = length,
			member = memb,
		};
	};
	return (sz, _align, t);
};

fn _struct_from_ast(
	store: *typestore,
	atype: ast::struct_union_type,
	is_union: bool,
	fields: *[]struct_field,
	offs: *size,
) (void | deferred | error) = {
	const nfields = len(fields);
	const membs = match(atype) {
	case let atype: ast::struct_type =>
		yield atype.members;
	case let atype: ast::union_type =>
		yield atype: []ast::struct_member;
	};
	for (let i = 0z; i < len(membs); i += 1) {
		*offs = match (membs[i]._offset) {
		case let ex: *ast::expr =>
			yield match (store.resolve) {
			case null =>
				return noresolver;
			case let res: *resolver =>
				yield res(store.rstate, store, ex)?;
			};
		case null =>
			yield *offs;
		};

		const memb = match (membs[i].member) {
		case let se: ast::struct_embedded =>
			let membs: []ast::struct_member = match (se.repr) {
			case let st: ast::struct_type =>
				yield st.members;
			case let ut: ast::union_type =>
				yield ut;
			case =>
				abort(); // Invariant
			};
			_struct_from_ast(store, membs,
				se.repr is ast::union_type,
				fields, offs)?;
			continue;
		case let se: ast::struct_alias =>
			abort(); // TODO
		case let sf: ast::struct_field =>
			yield sf;
		};

		const _type = lookup(store, memb._type)?;
		if (*offs % _type._align != 0) {
			*offs += _type._align - (*offs % _type._align);
		};

		append(fields, struct_field {
			name = memb.name,
			offs = *offs,
			_type = _type,
		});

		if (!is_union) {
			*offs += _type.sz;
		};
	};

	if (is_union) {
		let max = 0z;
		for (let i = nfields; i < len(fields); i += 1) {
			if (fields[i].offs + fields[i]._type.sz > max) {
				max = fields[i].offs + fields[i]._type.sz;
			};
		};
		*offs = max;
	};
};

fn struct_from_ast(
	store: *typestore,
	atype: ast::struct_union_type,
	is_union: bool,
) (_struct | deferred | error) = {
	let fields: []struct_field = [];
	let offs = 0z;
	_struct_from_ast(store, atype, is_union, &fields, &offs)?;
	sort::sort(fields, size(struct_field), &field_cmp);
	return _struct {
		kind = if (is_union) struct_union::UNION else struct_union::STRUCT,
		fields = fields,
	};
};

fn tagged_collect(
	store: *typestore,
	atype: ast::tagged_type,
	types: *[]const *_type,
) (void | deferred | error) = {
	for (let i = 0z; i < len(atype); i += 1) match (atype[i].repr) {
	case let ta: ast::tagged_type =>
		tagged_collect(store, ta, types)?;
	case =>
		append(types, lookup(store, atype[i])?);
	};
};

fn tagged_cmp(a: const *opaque, b: const *opaque) int = {
	const a = a: const **_type, b = b: const **_type;
	return if (a.id < b.id) -1 else if (a.id == b.id) 0 else 1;
};

fn tagged_from_ast(
	store: *typestore,
	atype: ast::tagged_type,
) (tagged | deferred | error) = {
	let types: []const *_type = [];
	//defer! free(types);
	tagged_collect(store, atype, &types)?;
	sort::sort(types, size(const *_type), &tagged_cmp);
	for (let i = 1z; i < len(types); i += 1) {
		if (types[i].id == types[i - 1].id) {
			delete(types[i]);
			i -= 1;
		};
	};
	// TODO: Handle this gracefully
	assert(len(types) > 1);
	return types;
};

fn tuple_from_ast(
	store: *typestore,
	membs: ast::tuple_type,
) (tuple | deferred | error) = {
	let values: []tuple_value = [];
	let offs = 0z;
	for (let i = 0z; i < len(membs); i += 1) {
		const val = membs[i];
		const vtype = lookup(store, val)?;

		if (offs % vtype._align != 0) {
			offs += vtype._align - (offs % vtype._align);
		};

		append(values, tuple_value {
			_type = vtype,
			offs = offs,
		});

		offs += vtype.sz;
	};
	return values;
};

fn field_cmp(a: const *opaque, b: const *opaque) int = {
	const a = a: const *struct_field, b = b: *const struct_field;
	return strings::compare(a.name, b.name);
};

fn type_finish(t: *_type) void = {
	match (t.repr) {
	case let a: alias =>
		ast::ident_free(a.id);
	case array => void;
	case builtin => void;
	case let e: _enum =>
		free(e.values);
	case let f: func =>
		free(f.params);
	case pointer => void;
	case let s: slice => void;
	case let st: _struct =>
		free(st.fields);
	case let tu: tuple =>
		free(tu);
	case let ta: tagged =>
		free(ta);
	};
};
