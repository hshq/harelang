haredoc(1)

# NAME

haredoc - create documentation from hare source code

# SYNOPSIS

*haredoc* [-hat] [-F _format_] [-T _tagset_] [_identifiers_...]

# DESCRIPTION

*haredoc* reads documentation for a set of identifiers from Hare source code,
and optionally prepares it for viewing in various output formats. By default,
*haredoc* will format documentation for your terminal. See *hare-doc*(5) for
details on the format.

# OPTIONS

*-h*
	Prints the help text.

*-a*
	Show undocumented members (only applies to -Fhare and -Ftty).

*-F* _format_
	Select output format (one of "html", "hare", or "tty").

*-t*
	Disable HTML template.

*-T* _tags_
	Sets or unsets build tags. See *CUSTOMIZING BUILD TAGS*.

# TTY COLORS

The TTY output format of *haredoc* renders colors in the terminal with ANSI
SGR escape sequences, behaving similarly to this shell command:

	printf '\\033[0;%sm' '_seq_'

These sequences can be customised with the *HAREDOC_COLORS* environment
variable, which follows this whitespace-delimited format:

	HAREDOC\_COLORS='_key_=_seq_ _key_=_seq_ _..._'

where each _key_=_seq_ entry assigns a valid _seq_ SGR sequence to a _key_
syntax category. A valid _seq_ must contain either a single underscore "\_"; or
digits and/or semicolons ";". Here are the initial default entries.
; TODO: what even is this wording

. normal        "0"
. comment       "1"
. primary       "0"
. secondary     "0"
. keyword       "94"
. type          "96"
. attribute     "33"
. operator      "1"
. punctuation   "0"
. constant      "91"
. string        "91"
. number        "95"

Any number of entries can be specified. If a _seq_ is an underscore "\_", the
sequence specified for "normal" is used. Otherwise, if a _seq_ is invalid,
blank, empty or absent, its corresponding default sequence is used.

For example:

	HAREDOC\_COLORS='comment=3 primary=1;4 attribute=41' haredoc -Ftty log

# SEE ALSO

*hare*(1), *hare-doc*(5)
