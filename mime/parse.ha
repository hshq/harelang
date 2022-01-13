use ascii;
use errors;
use strings;

const tspecial: str = "()<>@,;:\\/[]?=";
export type type_params = strings::tokenizer;

fn typevalid(in: str) (void | errors::invalid) = {
	const miter = strings::iter(in);
	for (true) {
		const rn = match (strings::next(&miter)) {
		case let rn: rune =>
			yield rn;
		case void =>
			break;
		};
		if (!ascii::isascii(rn) || rn == ' '
				|| ascii::iscntrl(rn)
				|| strings::contains(tspecial, rn)) {
			return errors::invalid;
		};
	};
};

// Parses a Media Type, returning a tuple of the content type (e.g.
// "text/plain") and a parameter parser object, or [[errors::invalid]] if the
// input cannot be parsed.
//
// To enumerate the Media Type parameter list, pass the type_params object into
// [[next_param]]. If you do not need the parameter list, you can safely discard
// the object. Note that any format errors following the ";" token will not
// cause [[errors::invalid]] to be returned unless [[next_param]] is used to
// enumerate all of the parameters.
export fn parse(in: str) ((str, type_params) | errors::invalid) = {
	const items = strings::cut(in, ";");
	const mtype = items.0, params = items.1;
	const items = strings::cut(mtype, "/");
	if (len(items.0) < 1 || len(items.1) < 1) {
		return errors::invalid;
	};
	typevalid(items.0)?;
	typevalid(items.1)?;
	return (mtype, strings::tokenize(params, ";"));
};

// Returns the next parameter as a (key, value) tuple from a [[type_params]]
// object that was prepared via [[parse]], void if there are no remaining
// parameters, and [[errors::invalid]] if a syntax error was encountered.
export fn next_param(in: *type_params) ((str, str) | void | errors::invalid) = {
	const tok = match (strings::next_token(in)) {
	case let s: str =>
		if (s == "") {
			// empty parameter
			return errors::invalid;
		};
		yield s;
	case void =>
		return;
	};

	const items = strings::cut(tok, "=");
	// The RFC does not permit whitespace here, but whitespace is very
	// common in the wild. ¯\_(ツ)_/¯
	items.0 = strings::trim(items.0);
	items.1 = strings::trim(items.1);

	if (strings::hasprefix(items.1, "\"")) {
		// So you handed mime::next_param a seemingly valid parameter
		// and ended up getting this error instead. Good. That's means
		// you're motivated to deal with this! YOU read the RFC's ABNF
		// grammar and figure out how this should be implemented. I sure
		// as hell don't have the patience for this shitty RFC.
		return errors::invalid;
	};

	return (items.0, items.1);
};

@test fn parse() void = {
	const res = parse("text/plain")!;
	assert(res.0 == "text/plain");

	const res = parse("image/png")!;
	assert(res.0 == "image/png");

	const res = parse("application/svg+xml; charset=utf-8; foo=bar")!;
	assert(res.0 == "application/svg+xml");
	const params = res.1;
	const param = next_param(&params)! as (str, str);
	assert(param.0 == "charset" && param.1 == "utf-8");
	const param = next_param(&params)! as (str, str);
	assert(param.0 == "foo" && param.1 == "bar");
	assert(next_param(&params) is void);
};
