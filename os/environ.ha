// Looks up an environment variable and returns its value. Aborts if unset.
export fn must_getenv(name: str) str = {
	// TODO: It would be nice to print the name of the variable in the error
	match (getenv(name)) {
		s: str => s,
		* => abort("required environment variable unset"),
	};
};
