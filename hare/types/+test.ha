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
