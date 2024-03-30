// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use fmt;
use io;
use memio;
use strings;

export type literal = str;
export type variable = str;
export type instruction = (literal | variable);
export type template = []instruction;

// Parameters to execute with a template, a tuple of a variable name and a
// formattable object.
export type param = (str, fmt::formattable);

// The template string has an invalid format.
export type invalid = !void;

// Converts an error into a human-friendly string.
export fn strerror(err: invalid) str = "Template string has invalid format";

// Compiles a template string. The return value must be freed with [[finish]]
// after use.
export fn compile(input: str) (template | invalid) = {
	let buf = memio::dynamic();
	defer io::close(&buf)!;

	let instrs: []instruction = [];
	const iter = strings::iter(input);
	for (let rn => strings::next(&iter)) {
		if (rn == '$') {
			match (strings::next(&iter)) {
			case let next_rn: rune =>
				if (next_rn == '$') {
					memio::appendrune(&buf, rn)!;
				} else {
					strings::prev(&iter);
					const lit = memio::string(&buf)!;
					append(instrs, strings::dup(lit): literal);
					memio::reset(&buf);

					parse_variable(&instrs, &iter, &buf)?;
				};
			case =>
				return invalid;
			};
		} else {
			memio::appendrune(&buf, rn)!;
		};
	};

	if (len(memio::string(&buf)!) != 0) {
		const lit = memio::string(&buf)!;
		append(instrs, strings::dup(lit): literal);
	};

	return instrs;
};

// Frees resources associated with a [[template]].
export fn finish(tmpl: *template) void = {
	for (let instr .. *tmpl) {
		match (instr) {
		case let lit: literal =>
			free(lit);
		case let var: variable =>
			free(var);
		};
	};
	free(*tmpl);
};

// Executes a template, writing the output to the given [[io::handle]]. If the
// template calls for a parameter which is not provided, an assertion will be
// fired.
export fn execute(
	tmpl: *template,
	out: io::handle,
	params: param...
) (size | io::error) = {
	let z = 0z;
	for (let instr .. *tmpl) {
		match (instr) {
		case let lit: literal =>
			z += fmt::fprint(out, lit)?;
		case let var: variable =>
			const value = get_param(var, params...);
			z += fmt::fprint(out, value)?;
		};
	};
	return z;
};

fn get_param(name: str, params: param...) fmt::formattable = {
	// TODO: Consider preparing a parameter map or something
	for (let (var_name, obj) .. params) {
		if (var_name == name) {
			return obj;
		};
	};
	fmt::errorfln("strings::template: required parameter ${} was not provided", name)!;
	abort();
};

fn parse_variable(
	instrs: *[]instruction,
	iter: *strings::iterator,
	buf: *memio::stream,
) (void | invalid) = {
	let brace = false;
	match (strings::next(iter)) {
	case let rn: rune =>
		if (rn == '{') {
			brace = true;
		} else {
			strings::prev(iter);
		};
	case =>
		return invalid;
	};

	for (true) {
		const rn = match (strings::next(iter)) {
		case let rn: rune =>
			yield rn;
		case =>
			return invalid;
		};

		if (brace) {
			if (rn == '{') {
				return invalid;
			} else if (rn != '}') {
				memio::appendrune(buf, rn)!;
			} else {
				break;
			};
		} else {
			if (ascii::isalnum(rn)) {
				memio::appendrune(buf, rn)!;
			} else {
				strings::prev(iter);
				break;
			};
		};
	};

	const var = memio::string(buf)!;
	append(instrs, strings::dup(var): variable);
	memio::reset(buf);
};

def test_input: str = `Dear ${recipient},

I am the crown prince of $country. Your brother, $brother, has recently passed
away in my country. I am writing to you to facilitate the transfer of his
foreign bank account balance of $$1,000,000 to you.`;

def test_output: str = `Dear Mrs. Johnson,

I am the crown prince of South Africa. Your brother, Elon Musk, has recently passed
away in my country. I am writing to you to facilitate the transfer of his
foreign bank account balance of $1,000,000 to you.`;

@test fn template() void = {
	const tmpl = compile(test_input)!;
	defer finish(&tmpl);

	let buf = memio::dynamic();
	defer io::close(&buf)!;

	execute(&tmpl, &buf,
		("recipient", "Mrs. Johnson"),
		("country", "South Africa"),
		("brother", "Elon Musk"),
	)!;

	assert(memio::string(&buf)! == test_output);
};
