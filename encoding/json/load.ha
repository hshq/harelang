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
	const lex = newlexer(src);
	defer close(&lex);
	return _load(&lex);
};

fn _load(lexer: *lexer) (value | error) = {
	const tok = mustscan(lexer)?;
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
		return _load_array(lexer);
	case objstart =>
		return _load_obj(lexer);
	case (arrayend | objend | colon | comma) =>
		return invalid;
	};
};

fn _load_array(lexer: *lexer) (value | error) = {
	let array: []value = [];
	for (true) {
		let tok = mustscan(lexer)?;
		match (tok) {
		case arrayend =>
			break;
		case =>
			unlex(lexer, tok);
		};

		append(array, _load(lexer)?);

		tok = mustscan(lexer)?;
		match (tok) {
		case comma => void;
		case arrayend => break;
		case => return invalid;
		};
	};
	return array;
};

fn _load_obj(lexer: *lexer) (value | error) = {
	let obj = newobject();
	for (true) {
		let tok = mustscan(lexer)?;
		const key = match (tok) {
		case let s: str =>
			yield strings::dup(s);
		case objend => break;
		case => return invalid;
		};
		defer free(key);

		tok = mustscan(lexer)?;
		if (!(tok is colon)) {
			return invalid;
		};

		const val = _load(lexer)?;
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
