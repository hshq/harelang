use hare::types;

type context = struct {
	store: *types::typestore,
	scope: *scope,
	fntype: *types::func,
};
