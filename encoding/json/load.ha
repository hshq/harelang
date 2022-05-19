use io;
use strings;
use types;

// Options for [[load]].
export type load_option = nestlimit;

// The maximum number of nested objects or arrays that can be entered before
// erroring out.
export type nestlimit = uint;

// Parses a JSON value from the given [[io::handle]], returning the value or an
// error. The return value is allocated on the heap; use [[finish]] to free it
// up when you're done using it.
//
// By default, this function assumes non-antagonistic inputs, and does not limit
// recursion depth or memory usage. You may want to set a custom [[nestlimit]],
// or incorporate an [[io::limitreader]] or similar. Alternatively, you can use
// the JSON lexer ([[lex]]) directly if dealing with potentially malicious
// inputs.
export fn load(src: io::handle, opts: load_option...) (value | error) = {
	let limit = types::UINT_MAX;
	for (let i = 0z; i < len(opts); i += 1) {
		limit = opts[i]: nestlimit: uint;
	};
	const lex = newlexer(src);
	defer close(&lex);
	return _load(&lex, 0, limit);
};

fn _load(lexer: *lexer, level: uint, limit: uint) (value | error) = {
	const tok = mustscan(lexer)?;
	match (tok) {
	case _null =>
		return _null;
	case let b: bool =>
		return b;
	case let f: f64 =>
		return f;
	case let s: str =>
		return strings::dup(s);
	case arraystart =>
		if (level == limit) {
			return limitreached;
		};
		return _load_array(lexer, level + 1, limit);
	case objstart =>
		if (level == limit) {
			return limitreached;
		};
		return _load_obj(lexer, level + 1, limit);
	case (arrayend | objend | colon | comma) =>
		return invalid;
	};
};

fn _load_array(lexer: *lexer, level: uint, limit: uint) (value | error) = {
	let array: []value = [];
	let tok = mustscan(lexer)?;
	match (tok) {
	case arrayend =>
		return array;
	case =>
		unlex(lexer, tok);
	};

	for (true) {
		append(array, _load(lexer, level, limit)?);

		tok = mustscan(lexer)?;
		match (tok) {
		case comma => void;
		case arrayend => break;
		case => return invalid;
		};
	};
	return array;
};

fn _load_obj(lexer: *lexer, level: uint, limit: uint) (value | error) = {
	let obj = newobject();
	let tok = mustscan(lexer)?;
	match (tok) {
	case objend =>
		return obj;
	case =>
		unlex(lexer, tok);
	};

	for (true) {
		let tok = mustscan(lexer)?;
		const key = match (tok) {
		case let s: str =>
			yield strings::dup(s);
		case => return invalid;
		};
		defer free(key);

		tok = mustscan(lexer)?;
		if (!(tok is colon)) {
			return invalid;
		};

		const val = _load(lexer, level, limit)?;
		defer finish(val);
		set(&obj, key, val);

		tok = mustscan(lexer)?;
		match (tok) {
		case comma => void;
		case objend => break;
		case => return invalid;
		};
	};

	return obj;
};

fn mustscan(lexer: *lexer) (token | error) = {
	match (lex(lexer)?) {
	case io::EOF =>
		return invalid;
	case let tok: token =>
		return tok;
	};
};
