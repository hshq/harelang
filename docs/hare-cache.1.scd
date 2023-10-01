hare-cache(1)

# NAME

hare cache - inspect and manage the build cache

# SYNOPSIS

*hare cache* [-hc]

# DESCRIPTION

*hare cache* provides tools to manage the build cache. If no options are
supplied, the path and disk usage of the cache are printed.

# OPTIONS

*-h*
	Print the help text.

*-c*
	Clear the cache.

# ENVIRONMENT

The following environment variables affect *hare cache*'s execution:

|[ *HARECACHE*
:< The path to the build cache. Defaults to *$XDG_CACHE_HOME/hare*, or
   *~/.cache/hare* if *$XDG_CACHE_HOME* isn't set.

# SEE ALSO

*hare-build*(1), *hare-run*(1), *hare-test*(1)
