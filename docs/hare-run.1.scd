hare-run(1)

# NAME

hare run - compile and run a Hare program or module

# SYNOPSIS

*hare run* [-hqv]++
	[-a _arch_]++
	[-D _ident[:type]=value_]++
	[-j _jobs_]++
	[-L _libdir_]++
	[-l _libname_]++
	[-R]++
	[-T _tagset_]++
	[_path_ [_args_...]]

# DESCRIPTION

*hare run* compiles and runs a Hare program or module. The _path_ argument is a
path to a Hare source file or to a directory which contains a Hare module (see
*hare-module*(5)). If no path is given, the Hare module contained in the current
working directory is run. The remaining _args_ are passed to the compiled
program.

# OPTIONS

Refer to *hare-build*(1).

# ENVIRONMENT

Refer to *hare-build*(1).

# SEE ALSO

*hare-build*(1), *hare-test*(1), *hare-module*(5)
