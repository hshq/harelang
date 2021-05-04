use bufio;
use hare::ast;
use hare::lex;
use hare::parse;
use io;
use strings;

fn parse_type(in: str) ast::_type = {
	let buf = bufio::fixed(strings::toutf8(in), io::mode::READ);
	defer io::close(buf);
	let lex = lex::init(buf, "<test>");
	return parse::_type(&lex)!;
};

@test fn store() void = {
	let st = store(x86_64, null, null);
	defer store_free(st);

	let atype = parse_type("int");
	defer ast::type_free(atype);
	let htype = lookup(st, &atype)!;
	assert(htype._type is builtin);
	assert(htype._type as builtin == builtin::INT);
	assert(htype.sz == x86_64._int && htype.align == x86_64._int);

	let type2 = lookup(st, &atype)!;
	assert(htype == type2, "types should be singletons");

	let atype = parse_type("*int");
	defer ast::type_free(atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == x86_64._pointer && htype.align == x86_64._pointer);
	let htype = htype._type as pointer;
	assert(htype.referent._type as builtin == builtin::INT);
};

@test fn structs() void = {
	let st = store(x86_64, null, null);
	defer store_free(st);

	// Basic struct
	let atype = parse_type("struct { x: int, y: int }");
	defer ast::type_free(atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == 8);
	let stype = htype._type as _struct;
	assert(stype.kind == struct_union::STRUCT);
	assert(len(stype.fields) == 2);

	let x = stype.fields[0];
	assert(x.name == "x");
	assert(x.offs == 0);
	assert(x._type._type as builtin == builtin::INT);

	let y = stype.fields[1];
	assert(y.name == "y");
	assert(y.offs == 4);
	assert(y._type._type as builtin == builtin::INT);

	// Basic union
	let atype = parse_type("union { x: int, y: int }");
	defer ast::type_free(atype);
	let htype = lookup(st, &atype)!;
	assert(htype.sz == 4);
	let stype = htype._type as _struct;
	assert(stype.kind == struct_union::UNION);
	assert(len(stype.fields) == 2);

	let x = stype.fields[0];
	assert(x.name == "x");
	assert(x.offs == 0);
	assert(x._type._type as builtin == builtin::INT);

	let y = stype.fields[1];
	assert(y.name == "y");
	assert(y.offs == 0);
	assert(y._type._type as builtin == builtin::INT);

	// Alignment
	// TODO

	// Sort order
	// TODO

	// Embedded struct
	// TODO

	// Embedded union
	// TODO

	// Embedded (struct) alias
	// TODO

	// Embedded (union) alias
	// TODO

	// Explicit offsets
	// TODO

	// C compatibility testing
	// TODO
};
