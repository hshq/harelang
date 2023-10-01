hare-deps(1)

# NAME

hare deps - display the dependency tree of a Hare program or module

# SYNOPSIS

*hare deps* [-hd] [-T _tagset_] [_path_|_module_]

# DESCRIPTION

*hare deps* displays the dependency tree of a Hare program or module, as per the
algorithm described in *DEPENDENCY RESOLUTION* in *hare-module*(5). The _path_
argument is a path to a Hare source file or a directory which contains a Hare
module (see *hare-module*(5)). If no path is given, the Hare module contained in
the current working directly is used.

By default, the dependency tree is pretty-printed using Unicode box-drawing
characters.

# OPTIONS

*-h*
	Print the help text.

*-d*
	Print the dependency tree as a dot file for use with *graphviz*(1).

*-T* _tagset_
	Set or unset build tags. See *BUILD TAGS* in *hare-module*(5).

# ENVIRONMENT

The following environment variables affect *hare deps*' execution:

|[ *HAREPATH*
:< The list of directories to search for dependencies in.
|  *NO_COLOR*
:  Disables all color output when set to a non-empty string.

# SEE ALSO

*hare-module*(5)
