use errors;
use hare::ast;

export def BUCKETS: size = 65535;

// A function which evaluates an [[ast::expr]], providing either a size result
// or an error.
export type resolver = fn(
	rstate: *void,
	store: *typestore,
	expr: const *ast::expr,
) (size | errors::opaque);

export type typestore = struct {
	arch: arch,
	map: [BUCKETS][]struct {
		hash: u32,
		_type: _type,
	},
	resolve: *resolver,
	rstate: *void,
};

// Initializes a new type store. Optionally, provide a function which
// type-checks and evaluates an [[ast::expr]].
export fn store(arch: arch, resolver: *resolver, rstate: *void) *typestore = {
	return alloc(typestore {
		arch = arch,
		resolve = resolver,
		rstate = rstate,
		...
	});
};

// Returned from [[lookup]] when we are unable to resolve this type, but it does
// not necessarily have an error. This occurs when a type includes an unknown
// forward reference.
export type deferred = void!;

// A resolver function was not provided to [[store]], but was required to look
// up this type.
export type noresolver = void!;

// All possible errors for [[lookup]].
export type error = (noresolver | errors::opaque)!;

// Retrieves a [[_type]] for a given [[ast::_type]].
export fn lookup(
	store: *typestore,
	t: *ast::_type,
) (const *_type | deferred | error) = {
	const t = fromast(store, t)?;
	const h = hash(&t);
	let bucket = &store.map[h % BUCKETS];
	// XXX: Should not have to dereference bucket
	for (let i = 0z; i < len(*bucket); i += 1) {
		if (bucket[i].hash == h) {
			type_finish(&t);
			return &bucket[i]._type;
		};
	};
	append(*bucket, struct {
		hash: u32 = h,
		_type: _type = t,
	});
	return &bucket[len(*bucket) - 1]._type;
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
		* => abort(), // TODO
	};
	return _type {
		flags = atype.flags: flags,
		_type = underlying,
		sz = sz,
		align = align,
	};
};

fn type_finish(t: *_type) void = {
	match (t._type) {
		a: alias => ast::ident_free(a.id),
		builtin => void,
		pointer => void,
		* => abort(), // TODO
	};
};
