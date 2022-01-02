use bufio;
use io;
use hare::types;
use hare::unit;

type context = struct {
	out: io::handle,
	buf: bufio::memstream,
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

fn binding_lookup(ctx: *context, object: *unit::object) *binding = {
	// XXX: We could use a hash map here
	for (let i = 0z; i < len(ctx.bindings); i += 1) {
		if (ctx.bindings[i].object == object) {
			return &ctx.bindings[i];
		};
	};
	abort();
};
