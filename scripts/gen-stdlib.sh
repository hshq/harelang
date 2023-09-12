mod_path() {
	printf '%s\n' "$1" | tr -s '::' '/'
}
mod_file() {
	printf '%s\n' "$1" | tr -s '::' '_'
}
mod_var() {
	printf '%s_%s_%s\n' "$stdlib" "$1" "$2" | tr -s '::' '_'
}

gen_srcs() {
	platform=any
	OPTIND=1
	while getopts p: name
	do
		case $name in
		p)
			platform="$OPTARG"
			;;
		?)
			printf 'Invalid use of gen_srcs' >&2
			exit 1
			;;
		esac
	done
	shift $(($OPTIND - 1))

	mod="$1"
	shift

	path="$(mod_path "$mod")"
	var="$(mod_var "$mod" "$platform")"

	printf '# %s (+%s)\n' "$mod" "$platform"
	printf '%s_srcs = \\\n' "$var"
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
	platform=any
	OPTIND=1
	while getopts p: name
	do
		case $name in
		p)
			platform="$OPTARG"
			;;
		?)
			printf 'Invalid use of gen_ssa' >&2
			exit 1
			;;
		esac
	done
	shift $(($OPTIND - 1))

	mod="$1"
	shift

	path=$(mod_path "$mod")
	file=$(mod_file "$mod")
	var=$(mod_var "$mod" "$platform")

	printf "\$($cache)/$path/$file-$platform.ssa: \$(${var}_srcs) \$(${stdlib}_rt)"
	for dep in $*
	do
		printf ' $(%s)' "$(mod_var "$dep" \$"(PLATFORM)")"
	done
	printf '\n'

	cat <<EOF
	@printf 'HAREC \t\$@\n'
	@mkdir -p \$($cache)/$path
	@\$(${stdlib}_env) \$(HAREC) \$($flags) -o \$@ -N$mod \\
		-t\$($cache)/$path/$file.td \$(${var}_srcs)

EOF
}

gen_lib() {
	platform=any
	OPTIND=1
	while getopts p: name
	do
		case $name in
		p)
			platform="$OPTARG"
			;;
		?)
			printf 'Invalid use of gen_lib' >&2
			exit 1
			;;
		esac
	done
	shift $(($OPTIND - 1))

	printf "# gen_lib $1 ($platform)\n"

	mod="$1"
	path=$(mod_path "$mod")
	file=$(mod_file "$mod")
	var=$(mod_var "$mod" "$platform")
	printf "%s = \$(%s)/%s/%s-%s.o\n" "$var" "$cache" "$path" "$file" "$platform"
	printf "%s_env += HARE_TD_%s=\$(%s)/%s/%s.td\n" "$stdlib" "$mod" "$cache" "$path" "$file"
	printf '%s_deps_%s += $(%s)\n' "$stdlib" "$platform" "$var"
	if [ "$platform" = "any" ]
	then
		for p in $all_platforms
		do
			printf '%s = $(%s)\n' "$(mod_var "$mod" "$p")" "$var"
		done
	fi
	printf '\n'
}

genrules() {
	if [ $# -gt 0 ] && [ "$1" = "test" ]
	then
		cache=TESTCACHE
		flags=TESTHARECFLAGS
		testing=1
		stdlib=testlib
	else
		cache=HARECACHE
		flags=HARECFLAGS
		testing=0
		stdlib=stdlib
	fi
	stdlib
}
