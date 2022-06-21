haredoc(1)

# NAME

haredoc - reads and formats Hare documentation

# SYNOPSIS

*haredoc* [-at] [-F _format_] [_identifiers_...]

# DESCRIPTION

*haredoc* reads documentation for a set of identifiers from Hare source code,
and optionally prepares it for viewing in various output formats. By default,
*haredoc* will format documentation for your terminal.

See *DOCUMENTATION FORMAT* for details on the format.

# OPTIONS

*-a*
	Show undocumented members (only applies to -Fhare and -Ftty).

*-F* _format_
	Select output format (one of "html", "gemtext", "hare", or "tty").

*-t*
	Disable HTML template.

*-T* _tags_
	Adds additional build tags. See *CUSTOMIZING BUILD TAGS* in *hare*(1).

*-X* _tags_
	Unsets build tags. See *CUSTOMIZING BUILD TAGS* in *hare*(1).

# DOCUMENTATION FORMAT

The Hare formatting markup is a very simple markup language. Text may be written
normally, broken into several lines to conform to the column limit. Repeated
whitespace will be collapsed. To begin a new paragraph, insert an empty line.

Links to Hare symbols may be written in brackets, like this: [[os::stdout]]. A
bulleted list can be started by opening a line with "-". To complete the list,
insert an empty line. Code samples may be used by using more than one space
character at the start of a line (a tab character counts as 8 indents).

This markup language is extracted from Hare comments preceding exported symbols
in your source code, and from a file named "README" in your module directory, if
present.

```
// Foos the bars. See also [[foobar]].
export fn example() int;
```

# TTY COLORS

The TTY output format renders colors in the terminal with ANSI SGR escape
sequences, behaving similarly to this shell command:

	printf '\\033[0;%sm' '_seq_'

These sequences can be customised with the *HAREDOC_COLORS* environment
variable, which follows this whitespace-delimited format:

	HAREDOC\_COLORS='_key_=_seq_ _key_=_seq_ _..._'

where each _key_=_seq_ entry assigns a valid _seq_ SGR sequence to a _key_
syntax category. A valid _seq_ must contain either a single underscore "\_"; or
digits and/or semicolons ";". Here are the initial default _key_=_seq_ entries.

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

# ENVIRONMENT

The following environment variables affect *haredoc*'s execution:

|[ *HAREDOC_COLORS*
:< Customizes TTY format color rendering. See *TTY COLORS*.

# EXAMPLES

Read the documentation for _io_:

	haredoc io

Read the documentation for _hash::fnv_:

	haredoc hash::fnv

Prepare documentation for _hare::parse_ as HTML:

	haredoc -Fhtml hare::parse >parse.html

# SEE ALSO

*hare*(1)
