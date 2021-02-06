mod_path() {
	printf '%s\n' "$1" | tr -s '::' '/'
}
mod_file() {
	printf '%s\n' "$1" | tr -s '::' '.'
}
mod_var() {
	printf '%s_%s\n' "$stdlib" "$1" | tr -s '::' '_'
}

gen_srcs() {
	mod="$1"
	path="$(mod_path "$mod")"
	var="$(mod_var "$mod")"
	shift
	printf '%s_srcs= \\\n' "$var"
	while [ $# -ne 0 ]
	do
		if [ $# -eq 1 ]
		then
			printf '\t$(STDLIB)/%s/%s\n\n' "$path" "$1"
		else
			printf '\t$(STDLIB)/%s/%s \\\n' "$path" "$1"
		fi
		shift
	done
}

gen_ssa() {
	mod="$1"
	path=$(mod_path "$mod")
	file=$(mod_file "$mod")
	var=$(mod_var "$mod")
	shift

	printf "\$($cache)/$path/$file.ssa: \$(${var}_srcs) \$(${stdlib}_rt)"
	for dep in $*
	do
		printf ' $(%s)' "$(mod_var "$dep")"
	done
	printf '\n'

	cat <<EOF
	@printf 'HAREC \t\$@\n'
	@mkdir -p \$($cache)/$path
	@HARECACHE=\$($cache) \$(HAREC) \$($flags) -o \$@ -N$mod \\
		-t\$($cache)/$path/$file.td \$(${var}_srcs)

EOF
}

gen_lib() {
	mod="$1"
	path=$(mod_path "$mod")
	file=$(mod_file "$mod")
	var=$(mod_var "$mod")
	printf "%s=\$(%s)/%s/%s.o\n" "$var" "$cache" "$path" "$file"
	printf 'hare_%s_deps+=$(%s)\n\n' "$stdlib" "$var"
}

genrules() {
	if [ $# -gt 0 ] && [ "$1" = "test" ]
	then
		cache=TESTCACHE
		flags=TESTHAREFLAGS
		testing=1
		stdlib=testlib
	else
		cache=HARECACHE
		flags=HAREFLAGS
		testing=0
		stdlib=stdlib
	fi
	stdlib
}
