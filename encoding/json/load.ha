use io;
use strings;

// Parses a JSON value from the given [[io::handle]], returning the value or an
// error. The return value is allocated on the heap; use [[finish]] to free it
// up when you're done using it.
//
// This code assumes non-antagonistic inputs, and does not limit recursion depth
// or memory usage. You may want to incorporate something like
// [[io::limitreader]] or similar, or use the JSON lexer ([[lex]]) directly into
// your program if dealing with potentially malicious inputs.
export fn load(src: io::handle) (value | error) = {
	const lex = lex(src);
	defer close(&lex);
	return _load(&lex);
};

fn _load(lex: *lexer) (value | error) = {
	const tok = mustscan(lex)?;
	match (tok) {
	case _null =>
		return _null;
	case let b: bool =>
		return b;
	case let f: f64 =>
		return f;
	case let s: str =>
		return s;
	case arraystart =>
		return _load_array(lex);
	case objstart =>
		return _load_obj(lex);
	case (arrayend | objend | colon | comma) =>
		return invalid;
	};
};

fn _load_array(lex: *lexer) (value | error) = {
	let array: []value = [];
	for (true) {
		let tok = mustscan(lex)?;
		match (tok) {
		case arrayend =>
			break;
		case =>
			unlex(lex, tok);
		};

		append(array, _load(lex)?);

		tok = mustscan(lex)?;
		match (tok) {
		case comma => void;
		case arrayend => break;
		case => return invalid;
		};
	};
	return array;
};

fn _load_obj(lex: *lexer) (value | error) = {
	let obj = newobject();
	for (true) {
		let tok = mustscan(lex)?;
		const key = match (tok) {
		case let s: str =>
			yield strings::dup(s);
		case objend => break;
		case => return invalid;
		};
		defer free(key);

		tok = mustscan(lex)?;
		if (!(tok is colon)) {
			return invalid;
		};

		const val = _load(lex)?;
		set(&obj, key, val);

		tok = mustscan(lex)?;
		match (tok) {
		case comma => void;
		case objend => break;
		case => return invalid;
		};
	};

	return obj;
};

fn mustscan(lex: *lexer) (token | error) = {
	match (next(lex)?) {
	case io::EOF =>
		return invalid;
	case let tok: token =>
		return tok;
	};
};
