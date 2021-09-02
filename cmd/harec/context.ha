use io;
use hare::types;
use hare::unit;

type context = struct {
	out: *io::stream,
	store: *types::typestore,
	unit: *unit::unit,
	arch: struct {
		ptr: *qtype,
		sz: *qtype,
	},
	serial: uint,
	bindings: []binding,
};

type binding = struct {
	object: *unit::object,
	name: temporary,
};
