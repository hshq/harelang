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
supplied, it also prints information about the build parameters, in an output
format that's consistent for machine reading: the first line is always
*hare $version*, and subsequent lines give configuration values in the form of a
name on its own line unindenteed, followed by any number of values, each on its
own line indented with a single tab.

*hare-build*(1) compiles a Hare program or module.

*hare-cache*(1) manages the build cache.

*hare-deps*(1) displays the dependency tree of a Hare program or module.

*hare-run*(1) compiles and runs a Hare program or module.

*hare-test*(1) compiles and runs tests for Hare code.

# SEE ALSO

*hare-module*(5), *haredoc*(1)

# NOTES

See _https://harelang.org/community/_ for information on where to ask questions,
send patches, submit bug reports, and chat with others in the community.

Documentation for the language itself can be found at
_https://harelang.org/documentation/_.

The language specification is available at
_https://harelang.org/specification/_.
