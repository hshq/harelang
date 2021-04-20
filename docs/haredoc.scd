haredoc(1)

# NAME

haredoc - reads and formats Hare documentation

# SYNOPSIS

*haredoc* [-t] [-F _format_] [_identifiers_...]

# DESCRIPTION

*haredoc* reads documentation for a set of identifiers from Hare source code,
and optionally prepares it for viewing in various output formats. By default,
*haredoc* will format documentation for your terminal.

See *DOCUMENTATION FORMAT* for details on the format.

# OPTIONS

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

# EXAMPLES

Read the documentation for _io_:

	haredoc io

Read the documentation for _hash::fnv_:

	haredoc hash::fnv

Prepare documentation for _hare::parse_ as HTML:

	haredoc -Fhtml hare::parse >parse.html

# SEE ALSO

*hare*(1)
