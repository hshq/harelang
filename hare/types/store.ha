use ascii;
use errors;
use hare::ast;
use sort;

export def BUCKETS: size = 65535;

// A function which evaluates an [[ast::expr]], providing either a size result
// or an error.
export type resolver = fn(
	rstate: *void,
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
	rstate: nullable *void,
};

// Initializes a new type store. Optionally, provide a function which
// type-checks and evaluates an [[ast::expr]]. If a resolver is not provided,
// looking up types with an expression component (e.g. [2 + 2]int) will return
// [[noresolver]].
export fn store(
	arch: arch,
	resolver: nullable *resolver,
	rstate: nullable *void,
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

// Returned from [[lookup]] when we are unable to resolve this type, but it does
// not necessarily have an error. This occurs when a type includes an unknown
// forward reference.
export type deferred = !void;

// A resolver function was not provided to [[store]], but was required to look
// up this type.
export type noresolver = !void;

// All possible errors for [[lookup]].
export type error = !(noresolver | errors::opaque);

// Retrieves a [[_type]] for a given [[ast::_type]].
export fn lookup(
	store: *typestore,
	ty: *ast::_type,
) (const *_type | deferred | error) = {
	const ty = fromast(store, ty)?;
	const id = hash(&ty);
	let bucket = &store.map[id % BUCKETS];
	// XXX: Should not have to dereference bucket
	for (let i = 0z; i < len(*bucket); i += 1) {
		if (bucket[i].id == id) {
			type_finish(&ty);
			return &bucket[i];
		};
	};
	ty.id = id;
	append(*bucket, ty);
	return &bucket[len(*bucket) - 1];
};

fn fromast(store: *typestore, atype: *ast::_type) (_type | deferred | error) = {
	let sz = SIZE_UNDEFINED, align = SIZE_UNDEFINED;
	let underlying = match (atype._type) {
		a: ast::alias_type => {
			// TODO: This is incomplete
			assert(!a.unwrap);
			alias {
				id = ast::ident_dup(a.ident),
				_type = null,
			};
		},
		// TODO: Tuple unpacking could improve this
		b: ast::builtin_type => switch (b) {
			ast::builtin_type::BOOL => {
				sz = store.arch._int;
				align = store.arch._int;
				builtin::BOOL;
			},
			ast::builtin_type::CHAR => {
				sz = 1; align = 1;
				builtin::CHAR;
			},
			ast::builtin_type::F32 => {
				sz = 4; align = 4;
				builtin::F32;
			},
			ast::builtin_type::F64 => {
				sz = 8; align = 8;
				builtin::F64;
			},
			ast::builtin_type::I16 => {
				sz = 2; align = 2;
				builtin::I16;
			},
			ast::builtin_type::I32 => {
				sz = 4; align = 4;
				builtin::I32;
			},
			ast::builtin_type::I64 => {
				sz = 8; align = 8;
				builtin::I64;
			},
			ast::builtin_type::I8 => {
				sz = 1; align = 1;
				builtin::I8;
			},
			ast::builtin_type::INT => {
				sz = store.arch._int;
				align = store.arch._int;
				builtin::INT;
			},
			ast::builtin_type::RUNE => {
				sz = 4; align = 4;
				builtin::RUNE;
			},
			ast::builtin_type::SIZE => {
				sz = store.arch._size;
				align = store.arch._size;
				builtin::SIZE;
			},
			ast::builtin_type::STR => {
				sz += store.arch._pointer;
				sz += sz % store.arch._size + store.arch._size;
				sz += store.arch._size;
				align = if (store.arch._size > store.arch._pointer)
						store.arch._size
					else
						store.arch._pointer;
				builtin::STR;
			},
			ast::builtin_type::U16 => {
				sz = 2; align = 2;
				builtin::U16;
			},
			ast::builtin_type::U32 => {
				sz = 4; align = 4;
				builtin::U32;
			},
			ast::builtin_type::U64 => {
				sz = 8; align = 8;
				builtin::U64;
			},
			ast::builtin_type::U8 => {
				sz = 1; align = 1;
				builtin::U8;
			},
			ast::builtin_type::UINT => {
				sz = store.arch._int;
				align = store.arch._int;
				builtin::UINT;
			},
			ast::builtin_type::UINTPTR => {
				sz = store.arch._pointer;
				align = store.arch._pointer;
				builtin::UINTPTR;
			},
			ast::builtin_type::VOID => {
				sz = 0; align = 0;
				builtin::VOID;
			},
			ast::builtin_type::NULL => builtin::NULL,
			ast::builtin_type::ICONST,
			ast::builtin_type::FCONST => abort(), // TODO?
		},
		p: ast::pointer_type => {
			sz = store.arch._pointer;
			align = store.arch._pointer;
			pointer {
				referent = lookup(store, p.referent)?,
				flags = p.flags: pointer_flags,
			};
		},
		st: ast::struct_type => {
			let st = struct_from_ast(store, st, false)?;
			sz = 0; align = 0;
			for (let i = 0z; i < len(st.fields); i += 1) {
				const field = st.fields[i];
				if (field.offs + field._type.sz > sz) {
					sz = field.offs + field._type.sz;
				};
				if (field._type.align > align) {
					align = field._type.align;
				};
			};
			st;
		},
		un: ast::union_type => {
			let st = struct_from_ast(store, un, true)?;
			sz = 0; align = 0;
			for (let i = 0z; i < len(st.fields); i += 1) {
				const field = st.fields[i];
				if (field.offs + field._type.sz > sz) {
					sz = field.offs + field._type.sz;
				};
				if (field._type.align > align) {
					align = field._type.align;
				};
			};
			st;
		},
		tu: ast::tuple_type => {
			let tu = tuple_from_ast(store, tu)?;
			sz = 0; align = 0;
			for (let i = 0z; i < len(tu); i += 1) {
				const value = tu[i];
				if (value.offs + value._type.sz > sz) {
					sz = value.offs + value._type.sz;
				};
				if (value._type.align > align) {
					align = value._type.align;
				};
			};
			tu;
		},
		lt: ast::list_type => {
			let r = list_from_ast(store, &lt)?;
			sz = r.0;
			align = r.1;
			r.2;
		},
		ta: ast::tagged_type => abort(), // TODO
		func: ast::func_type => abort(), // TODO
		et: ast::enum_type => abort(), // TODO
	};
	return _type {
		flags = atype.flags: flags,
		_type = underlying,
		sz = sz,
		align = align,
	};
};

fn list_from_ast(
	store: *typestore,
	lt: *ast::list_type
) ((size, size, (slice | array)) | deferred | error) = {
	let sz = SIZE_UNDEFINED, align = SIZE_UNDEFINED;
	let memb = lookup(store, lt.members)?;
	let t = match (lt.length) {
		ast::len_slice => {
			sz = store.arch._pointer;
			if (sz % store.arch._size != 0) {
				sz += store.arch._size - (sz % store.arch._size);
			};
			sz += store.arch._size * 2;
			align = if (store.arch._pointer > store.arch._size)
					store.arch._pointer
				else store.arch._size;
			memb: slice;
		},
		// Note: contextual length is handled by hare::unit when
		// initializing bindings. We treat it like unbounded here and
		// it's fixed up later on.
		(ast::len_unbounded | ast::len_contextual) => {
			align = memb.align;
			array {
				length = SIZE_UNDEFINED,
				member = memb,
			};
		},
		ex: *ast::expr => {
			const resolv = match (store.resolve) {
				null => return noresolver,
				r: *resolver => r,
			};
			const length = resolv(store.rstate, store, ex)?;
			sz = memb.sz * length;
			assert(sz / length == memb.sz, "overflow");
			align = memb.align;
			array {
				length = length,
				member = memb,
			};
		},
	};
	return (sz, align, t);
};

fn _struct_from_ast(
	store: *typestore,
	membs: []ast::struct_member,
	is_union: bool,
	fields: *[]struct_field,
	offs: *size,
) (void | deferred | error) = {
	const nfields = len(*fields);
	for (let i = 0z; i < len(membs); i += 1) {
		*offs = match (membs[i]._offset) {
			ex: *ast::expr => match (store.resolve) {
				null => return noresolver,
				res: *resolver => res(store.rstate, store, ex)?,
			},
			null => *offs,
		};

		const memb = match (membs[i].member) {
			se: ast::struct_embedded => {
				let membs: []ast::struct_member = match (se._type) {
					st: ast::struct_type => st,
					ut: ast::union_type => ut,
					* => abort(), // Invariant
				};
				_struct_from_ast(store, membs,
					se._type is ast::union_type,
					fields, offs)?;
				continue;
			},
			se: ast::struct_alias => abort(), // TODO
			sf: ast::struct_field => sf,
		};

		const _type = lookup(store, memb._type)?;
		if (*offs % _type.align != 0) {
			*offs += _type.align - (*offs % _type.align);
		};

		append(*fields, struct_field {
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
		for (let i = nfields; i < len(*fields); i += 1) {
			if (fields[i].offs + fields[i]._type.sz > max) {
				max = fields[i].offs + fields[i]._type.sz;
			};
		};
		*offs = max;
	};
};

fn struct_from_ast(
	store: *typestore,
	membs: []ast::struct_member,
	is_union: bool,
) (_struct | deferred | error) = {
	let fields: []struct_field = [];
	let offs = 0z;
	_struct_from_ast(store, membs, is_union, &fields, &offs)?;
	sort::sort(fields, size(struct_field), &field_cmp);
	return _struct {
		kind = if (is_union) struct_union::UNION else struct_union::STRUCT,
		fields = fields,
	};
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

		if (offs % vtype.align != 0) {
			offs += vtype.align - (offs % vtype.align);
		};

		append(values, tuple_value {
			_type = vtype,
			offs = offs,
		});

		offs += vtype.sz;
	};
	return values;
};

fn field_cmp(a: const *void, b: const *void) int = {
	const a = a: const *struct_field, b = b: *const struct_field;
	return ascii::strcmp(a.name, b.name) as int;
};

fn type_finish(t: *_type) void = {
	match (t._type) {
		a: alias => ast::ident_free(a.id),
		array => void,
		builtin => void,
		e: _enum => {
			for (let i = 0z; i < len(e.values); i += 1) {
				free(e.values[i].0);
			};
			free(e.values);
		},
		f: func => {
			type_finish(f.result);
			for (let i = 0z; i < len(f.params); i += 1) {
				type_finish(f.params[i]);
			};
			free(f.params);
		},
		pointer => void,
		s: slice => type_finish(s),
		st: _struct => free(st.fields),
		tu: tuple => free(tu),
		ta: tagged => free(ta),
	};
};
