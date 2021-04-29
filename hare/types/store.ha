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

// A type store. Holds singletons for types in a hash map.
export type typestore = struct {
	map: [BUCKETS][]struct {
		hash: u32,
		_type: _type,
	},
	resolve: *resolver,
	rstate: *void,
};

// Initializes a new type store. Optionally, provide a function which
// type-checks and evaluates an [[ast::expr]].
export fn store(resolver: *resolver, rstate: *void) *typestore = {
	return alloc(typestore {
		resolve = resolver,
		rstate = rstate,
		...
	});
};

// Returned from [[lookup]] when we are unable to resolve this type, but it does
// not necessarily have an error. This occurs when a type includes an unknown
// forward reference.
export type deferred = void;

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
	const t = fromast(t);
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

fn fromast(atype: *ast::_type) _type = {
	let underlying = match (atype._type) {
		a: ast::alias_type => {
			assert(!a.unwrap); // TODO
			ast::ident_dup(a.ident): alias;
		},
		b: ast::builtin_type => b: builtin,
		* => abort(), // TODO
	};
	return _type {
		flags = atype.flags: flags,
		_type = underlying,
	};
};

fn type_finish(t: *_type) void = {
	match (t._type) {
		a: alias => ast::ident_free(a),
		builtin => void,
		* => abort(), // TODO
	};
};
