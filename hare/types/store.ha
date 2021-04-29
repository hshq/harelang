use hare::ast;

export def BUCKETS: size = 65535;

// A type store. Holds singletons for types in a hash map.
export type typestore = struct {
	map: [BUCKETS][]struct {
		hash: u32,
		_type: _type,
	},
};

// Initializes a new type store.
export fn store() *typestore = alloc(typestore { ... });

// Retrieves a [[_type]] for a given [[ast::_type]].
export fn lookup(store: *typestore, t: *ast::_type) const *_type = {
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
	void; // TODO
};
