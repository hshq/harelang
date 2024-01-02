hare-test(1)

# NAME

hare test - compile and run tests for Hare code

# SYNOPSIS

*hare test* [-hqv]++
	[-a _arch_]++
	[-D _ident[:type]=value_]++
	[-j _jobs_]++
	[-L _libdir_]++
	[-l _libname_]++
	[-o _path_]++
	[-R]++
	[-T _tagset_]++
	[_path_ [_tests_...]]

# DESCRIPTION

*hare test* compiles and runs tests for a Hare program or module. The +test tag
is added to the default build tags (see *BUILD TAGS* in *hare-module*(5)). If no
_path_ is given, all Hare modules in the current working directory are
recursively discovered, built, and their tests made eligible for the test run.
Otherwise, if a _path_ is given, the source file or module is built and tested.

If no _tests_ are supplied, all eligible tests are run. Otherwise, each argument
is interpreted as a *glob*(7) pattern, giving the names of the tests to run.

# OPTIONS

Refer to *hare-build*(1).

# ENVIRONMENT

Refer to *hare-build*(1).

# SEE ALSO

*hare-build*(1), *hare-run*(1), *hare-module*(5)
