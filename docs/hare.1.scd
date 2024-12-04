hare(1)

# NAME

hare - compile, run, test, and inspect Hare programs and modules

# SYNOPSIS

*hare* -h

*hare* version [-hv]

*hare* _command_ [_arguments_...]

# DESCRIPTION

*hare -h* prints help text.

*hare version* prints version information for the *hare* program. If *-v* is
supplied, it also prints information about the build parameters. If *-vv* is
specified, detailed information about the version and build parameters is
printed as shell environment variables in a format which is consistent between
versions and suitable for machine reading.

*hare-build*(1) compiles a Hare program or module.

*hare-cache*(1) manages the build cache.

*hare-deps*(1) displays the dependency tree of a Hare program or module.

*hare-run*(1) compiles and runs a Hare program or module.

*hare-test*(1) compiles and runs tests for Hare code.

# BUGS

The quality of error messages is poor.

# SEE ALSO

*hare-module*(5), *haredoc*(1)

See _https://harelang.org/community/_ for information on where to ask questions,
send patches, submit bug reports, and chat with others in the community.

Documentation for the language itself can be found at
_https://harelang.org/documentation/_.

The language specification is available at
_https://harelang.org/specification/_.
