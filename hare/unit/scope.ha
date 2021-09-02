use hare::ast;
use hare::types;
use hash::fnv;
use hash;
use strings;

export type object_kind = enum {
	BIND,
	CONST,
	DECL,
	TYPE,
};

export type object = struct {
	kind: object_kind,
	hash: u64,

	// The fully qualified identifier
	ident: ast::ident,
	// Local name, if different from the fully qualified identifier
	name: ast::ident,

	_type: const *types::_type,
	// TODO: store value for constants
};

export def SCOPE_BUCKETS: size = 4096;

export type scope_class = enum {
	COMPOUND,
	ENUM,
	FUNC,
	LOOP,
	MATCH,
	SUBUNIT,
	UNIT,
};

export type scope = struct {
	class: scope_class,
	parent: nullable *scope,
	objects: []object,
	hashmap: [SCOPE_BUCKETS][]*object,
};

fn scope_push(ctx: *context, class: scope_class) *scope = {
	let new = alloc(scope {
		class = class,
		parent = ctx.scope,
		...
	});
	ctx.scope = new;
	return new;
};

fn scope_pop(ctx: *context) *scope = {
	const scope = ctx.scope;
	ctx.scope = ctx.scope.parent: *scope; // TODO: as *scope
	return scope;
};

fn scope_insert(ctx: *context, obj: object) *object = {
	const scope = ctx.scope;
	append(scope.objects, obj);
	let obj = &scope.objects[len(scope.objects) - 1];
	let hash = fnv::fnv64a();
	defer hash::close(hash);
	const zerobuf = [0u8];
	for (let i = len(obj.ident); i > 0; i -= 1) {
		hash::write(hash, strings::toutf8(obj.ident[i - 1]));
		hash::write(hash, zerobuf[..]);
	};
	let hash = fnv::sum64(hash);
	obj.hash = hash;
	append(scope.hashmap[hash: size % SCOPE_BUCKETS], obj);
	return obj;
};
