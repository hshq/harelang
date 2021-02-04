mod_path() {
	printf '%s\n' "$1" | tr -s '::' '/'
}
mod_file() {
	printf '%s\n' "$1" | tr -s '::' '.'
}
mod_var() {
	printf '%s\n' "$1" | tr -s '::' '_'
}

gen_srcs() {
	mod="$1"
	path="$(mod_path "$mod")"
	var="$(mod_var "$mod")"
	shift
	printf 'lib%s_srcs= \\\n' "$var"
	while [ $# -ne 0 ]
	do
		if [ $# -eq 1 ]
		then
			printf '\t$(STDLIB)/%s/%s \n\n' "$path" "$1"
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

	printf "\$($cache)/$path/$file.ssa: \$(lib${var}_srcs) \$(stdlib_rt)"
	for dep in $*
	do
		printf ' $(stdlib_%s)' "$(mod_var "$dep")"
	done
	printf '\n'

	cat <<EOF
	@printf 'HAREC \t\$@\n'
	@mkdir -p \$($cache)/$path
	@\$(HAREC) \$(HAREFLAGS) -o \$@ -N$mod \\
		-t\$($cache)/$path/$file.td \$(lib${var}_srcs)

EOF
}

gen_lib() {
	mod="$1"
	path=$(mod_path "$mod")
	file=$(mod_file "$mod")
	var=$(mod_var "$mod")
	printf "stdlib_$var=\$($cache)/$path/$file.o\n"
	printf 'hare_deps+=$(stdlib_%s)\n\n' "$var"
}

