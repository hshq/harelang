haredoc(1)

# NAME

haredoc - read and format Hare documentation

# SYNOPSIS

*haredoc* [-hat] [-F _format_] [-T _tagset_] [_identifier_|_path_]

# DESCRIPTION

*haredoc* reads documentation from a source file or module. If no identifier or
path is supplied, documentation is read from the Hare module contained in the
current working directory, or from the root of the standard library if the
current working directory doesn't contain a Hare module (see *hare-module*(5)).

If an identifier is supplied, it's first looked up as a declaration. If no
suitable declaration exists, it's looked up as a module instead. The identifier
may also include a trailing ::, in which case it will always be treated as a
module. The identifier is resolved using the algorithm described in *DEPENDENCY
RESOLUTION* in *hare-module*(5).

# OPTIONS

*-h*
	Print the help text.

*-a*
	Show undocumented members.

*-F* _format_
	Select output format (one of "html" or "tty"). The default is "tty".

*-t*
	Disable HTML template (only applies to *-Fhtml*).

*-T* _tagset_
	Set or unset build tags. See *BUILD TAGS* in *hare-module*(5).

# CUSTOMIZING COLORS

Unless the *NO_COLOR* environment variable is set to a non-empty string, colors
are rendered in the terminal with ANSI SGR escape sequences. These sequences can
be customized with the *HAREDOC_COLORS* environment variable, which follows this
whitespace-delimited format:

	HAREDOC\_COLORS='_key_=_seq_ _key_=_seq_ _..._'

Each _key=seq_ entry assigns a valid _seq_ SGR sequence to a _key_ syntax
category. A valid _seq_ must consist only of digits and semicolons, or must be a
single underscore "\_". Here are the initial default entries:

. normal        "0"
. primary       "\_" (-> normal)
. ident         "\_" (-> normal)
. comment       "1"
. constant      "\_" (-> primary)
. function      "\_" (-> primary)
. global        "\_" (-> primary)
. typedef       "\_" (-> primary)
. import_alias  "\_" (-> normal)
. secondary     "\_" (-> normal)
. keyword       "94"
. type          "96"
. attribute     "33"
. operator      "1"
. punctuation   "\_" (-> normal)
. rune_string   "91"
. number        "95"
. label         "\_" (-> normal)

Any number of entries can be specified. If a _seq_ is an underscore "\_", then
the sequence specified for "normal" is used, unless _key_ is "constant",
"function", "global", or "typedef", in which case the sequence specified for
"primary" is used. Otherwise, if a _seq_ is invalid, blank, empty, or absent,
its corresponding default sequence is used.

For example:

	HAREDOC\_COLORS='comment=3 primary=1;4 attribute=41' haredoc log

# ENVIRONMENT

The following environment variables affect *haredoc*'s execution:

|[ *HAREPATH*
:< The list of directories to search for modules in. See *hare-module*(5).
|  *NO_COLOR*
:  Disables all color output when set to a non-empty string.
|  *HAREDOC_COLORS*
:  See *CUSTOMIZING COLORS*.

# SEE ALSO

*haredoc*(5)
