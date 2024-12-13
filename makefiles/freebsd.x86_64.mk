# generated by cmd/genbootstrap
# DO NOT EDIT BY HAND. run 'make bootstrap' to update
TDENV = env HARE_TD_rt=$(HARECACHE)/rt.td HARE_TD_types=$(HARECACHE)/types.td HARE_TD_bytes=$(HARECACHE)/bytes.td HARE_TD_encoding::utf8=$(HARECACHE)/encoding_utf8.td HARE_TD_sort::cmp=$(HARECACHE)/sort_cmp.td HARE_TD_strings=$(HARECACHE)/strings.td HARE_TD_ascii=$(HARECACHE)/ascii.td HARE_TD_errors=$(HARECACHE)/errors.td HARE_TD_io=$(HARECACHE)/io.td HARE_TD_bufio=$(HARECACHE)/bufio.td HARE_TD_crypto::math=$(HARECACHE)/crypto_math.td HARE_TD_endian=$(HARECACHE)/endian.td HARE_TD_hash=$(HARECACHE)/hash.td HARE_TD_crypto::sha256=$(HARECACHE)/crypto_sha256.td HARE_TD_math=$(HARECACHE)/math.td HARE_TD_memio=$(HARECACHE)/memio.td HARE_TD_path=$(HARECACHE)/path.td HARE_TD_time=$(HARECACHE)/time.td HARE_TD_fs=$(HARECACHE)/fs.td HARE_TD_types::c=$(HARECACHE)/types_c.td HARE_TD_os=$(HARECACHE)/os.td HARE_TD_strconv=$(HARECACHE)/strconv.td HARE_TD_fmt=$(HARECACHE)/fmt.td HARE_TD_encoding::hex=$(HARECACHE)/encoding_hex.td HARE_TD_sort=$(HARECACHE)/sort.td HARE_TD_hare::lex=$(HARECACHE)/hare_lex.td HARE_TD_hare::ast=$(HARECACHE)/hare_ast.td HARE_TD_hare::parse=$(HARECACHE)/hare_parse.td HARE_TD_hare::unparse=$(HARECACHE)/hare_unparse.td HARE_TD_hare::module=$(HARECACHE)/hare_module.td HARE_TD_unix=$(HARECACHE)/unix.td HARE_TD_unix::signal=$(HARECACHE)/unix_signal.td HARE_TD_os::exec=$(HARECACHE)/os_exec.td HARE_TD_shlex=$(HARECACHE)/shlex.td HARE_TD_unix::tty=$(HARECACHE)/unix_tty.td HARE_TD_cmd::hare::build=$(HARECACHE)/cmd_hare_build.td HARE_TD_dirs=$(HARECACHE)/dirs.td HARE_TD_getopt=$(HARECACHE)/getopt.td HARE_TD_cmd::hare=$(HARECACHE)/cmd_hare.td
RTSCRIPT = rt/+freebsd/hare.sc
OBJS = $(HARECACHE)/rt.o $(HARECACHE)/types.o $(HARECACHE)/bytes.o $(HARECACHE)/encoding_utf8.o $(HARECACHE)/sort_cmp.o $(HARECACHE)/strings.o $(HARECACHE)/ascii.o $(HARECACHE)/errors.o $(HARECACHE)/io.o $(HARECACHE)/bufio.o $(HARECACHE)/crypto_math.o $(HARECACHE)/endian.o $(HARECACHE)/hash.o $(HARECACHE)/crypto_sha256.o $(HARECACHE)/math.o $(HARECACHE)/memio.o $(HARECACHE)/path.o $(HARECACHE)/time.o $(HARECACHE)/fs.o $(HARECACHE)/types_c.o $(HARECACHE)/os.o $(HARECACHE)/strconv.o $(HARECACHE)/fmt.o $(HARECACHE)/encoding_hex.o $(HARECACHE)/sort.o $(HARECACHE)/hare_lex.o $(HARECACHE)/hare_ast.o $(HARECACHE)/hare_parse.o $(HARECACHE)/hare_unparse.o $(HARECACHE)/hare_module.o $(HARECACHE)/unix.o $(HARECACHE)/unix_signal.o $(HARECACHE)/os_exec.o $(HARECACHE)/shlex.o $(HARECACHE)/unix_tty.o $(HARECACHE)/cmd_hare_build.o $(HARECACHE)/dirs.o $(HARECACHE)/getopt.o $(HARECACHE)/cmd_hare.o

rt_ha = rt/+freebsd/+x86_64.ha rt/+freebsd/env.ha rt/+freebsd/errno.ha rt/+freebsd/initfini.ha rt/+freebsd/platform_abort.ha rt/+freebsd/platformstart-libc.ha rt/+freebsd/segmalloc.ha rt/+freebsd/signal.ha rt/+freebsd/socket.ha rt/+freebsd/start.ha rt/+freebsd/syscallno.ha rt/+freebsd/syscalls.ha rt/+freebsd/types.ha rt/+x86_64/arch_jmp.ha rt/+x86_64/cpuid.ha rt/abort.ha rt/ensure.ha rt/fenv_defs.ha rt/jmp.ha rt/malloc.ha rt/memcpy.ha rt/memfunc_ptr.ha rt/memmove.ha rt/memset.ha rt/strcmp.ha rt/u64tos.ha rt/unknown_errno.ha
$(HARECACHE)/std/rt.ssa: $(rt_ha)
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/rt.td.tmp -N rt $(rt_ha)

rt_s = $(HARECACHE)/std/rt.s rt/+freebsd/start+x86_64-libc.s rt/+freebsd/syscall+x86_64.s rt/+x86_64/cpuid.s rt/+x86_64/fenv.s rt/+x86_64/longjmp.s rt/+x86_64/setjmp.s
$(HARECACHE)/std/rt.o: $(rt_s)
	@$(AS) $(ASFLAGS) -o $@ $(rt_s)

types_ha = types/arch+x86_64.ha types/classes.ha types/limits.ha
$(HARECACHE)/std/types.ssa: $(types_ha)
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/types.td.tmp -N types $(types_ha)

bytes_ha = bytes/contains.ha bytes/equal.ha bytes/index.ha bytes/reverse.ha bytes/tokenize.ha bytes/trim.ha bytes/two_way.ha bytes/zero.ha
$(HARECACHE)/std/bytes.ssa: $(bytes_ha) $(HARECACHE)/std/rt.td $(HARECACHE)/std/types.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/bytes.td.tmp -N bytes $(bytes_ha)

encoding_utf8_ha = encoding/utf8/decode.ha encoding/utf8/decodetable.ha encoding/utf8/encode.ha encoding/utf8/rune.ha encoding/utf8/types.ha
$(HARECACHE)/std/encoding_utf8.ssa: $(encoding_utf8_ha) $(HARECACHE)/std/bytes.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/encoding_utf8.td.tmp -N encoding::utf8 $(encoding_utf8_ha)

sort_cmp_ha = sort/cmp/cmp.ha
$(HARECACHE)/std/sort_cmp.ssa: $(sort_cmp_ha)
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/sort_cmp.td.tmp -N sort::cmp $(sort_cmp_ha)

encoding_utf8_ha = encoding/utf8/decode.ha encoding/utf8/decodetable.ha encoding/utf8/encode.ha encoding/utf8/rune.ha encoding/utf8/types.ha
$(HARECACHE)/encoding_utf8.ssa: $(encoding_utf8_ha) $(HARECACHE)/bytes.td
	@mkdir -p -- "$(HARECACHE)"
	@printf 'HAREC\t%s\n' "$@"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/encoding_utf8.td.tmp -N encoding::utf8 $(encoding_utf8_ha)

sort_cmp_ha = sort/cmp/cmp.ha
$(HARECACHE)/sort_cmp.ssa: $(sort_cmp_ha)
	@mkdir -p -- "$(HARECACHE)"
	@printf 'HAREC\t%s\n' "$@"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/sort_cmp.td.tmp -N sort::cmp $(sort_cmp_ha)

strings_ha = strings/compare.ha strings/concat.ha strings/contains.ha strings/dup.ha strings/index.ha strings/iter.ha strings/pad.ha strings/replace.ha strings/runes.ha strings/sub.ha strings/suffix.ha strings/tokenize.ha strings/trim.ha strings/utf8.ha
$(HARECACHE)/std/strings.ssa: $(strings_ha) $(HARECACHE)/std/bytes.td $(HARECACHE)/std/encoding_utf8.td $(HARECACHE)/std/sort_cmp.td $(HARECACHE)/std/types.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/strings.td.tmp -N strings $(strings_ha)

ascii_ha = ascii/ctype.ha ascii/string.ha ascii/valid.ha
$(HARECACHE)/std/ascii.ssa: $(ascii_ha) $(HARECACHE)/std/encoding_utf8.td $(HARECACHE)/std/sort_cmp.td $(HARECACHE)/std/strings.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/ascii.td.tmp -N ascii $(ascii_ha)

errors_ha = errors/common.ha errors/opaque.ha errors/rt.ha errors/string.ha
$(HARECACHE)/std/errors.ssa: $(errors_ha) $(HARECACHE)/std/rt.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/errors.td.tmp -N errors $(errors_ha)

io_ha = io/+freebsd/dup.ha io/+freebsd/mmap.ha io/+freebsd/platform_file.ha io/+freebsd/sync.ha io/+freebsd/vector.ha io/arch+x86_64.ha io/copy.ha io/drain.ha io/empty.ha io/file.ha io/handle.ha io/limit.ha io/stream.ha io/tee.ha io/types.ha io/util.ha io/zero.ha
$(HARECACHE)/io.ssa: $(io_ha) $(HARECACHE)/bytes.td $(HARECACHE)/errors.td $(HARECACHE)/rt.td $(HARECACHE)/types.td
	@mkdir -p -- "$(HARECACHE)"
	@printf 'HAREC\t%s\n' "$@"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/io.td.tmp -N io $(io_ha)

bufio_ha = bufio/scanner.ha bufio/stream.ha
$(HARECACHE)/std/bufio.ssa: $(bufio_ha) $(HARECACHE)/std/bytes.td $(HARECACHE)/std/encoding_utf8.td $(HARECACHE)/std/errors.td $(HARECACHE)/std/io.td $(HARECACHE)/std/strings.td $(HARECACHE)/std/types.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/bufio.td.tmp -N bufio $(bufio_ha)

crypto_math_ha = crypto/math/arithm.ha crypto/math/bits.ha
$(HARECACHE)/std/crypto_math.ssa: $(crypto_math_ha) $(HARECACHE)/std/types.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/crypto_math.td.tmp -N crypto::math $(crypto_math_ha)

endian_ha = endian/big.ha endian/endian.ha endian/host+x86_64.ha endian/little.ha endian/network.ha
$(HARECACHE)/std/endian.ssa: $(endian_ha)
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/endian.td.tmp -N endian $(endian_ha)

hash_ha = hash/hash.ha
$(HARECACHE)/std/hash.ssa: $(hash_ha) $(HARECACHE)/std/io.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/hash.td.tmp -N hash $(hash_ha)

crypto_sha256_ha = crypto/sha256/sha256.ha
$(HARECACHE)/std/crypto_sha256.ssa: $(crypto_sha256_ha) $(HARECACHE)/std/bytes.td $(HARECACHE)/std/crypto_math.td $(HARECACHE)/std/endian.td $(HARECACHE)/std/hash.td $(HARECACHE)/std/io.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/crypto_sha256.td.tmp -N crypto::sha256 $(crypto_sha256_ha)

math_ha = math/fenv+x86_64.ha math/fenv_func.ha math/floats.ha math/ints.ha math/math.ha math/trig.ha math/uints.ha
$(HARECACHE)/std/math.ssa: $(math_ha) $(HARECACHE)/std/rt.td $(HARECACHE)/std/types.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/math.td.tmp -N math $(math_ha)

memio_ha = memio/ops.ha memio/stream.ha
$(HARECACHE)/std/memio.ssa: $(memio_ha) $(HARECACHE)/std/bytes.td $(HARECACHE)/std/encoding_utf8.td $(HARECACHE)/std/errors.td $(HARECACHE)/std/io.td $(HARECACHE)/std/strings.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/memio.td.tmp -N memio $(memio_ha)

path_ha = path/+freebsd.ha path/buffer.ha path/error.ha path/ext_stack.ha path/iter.ha path/posix.ha path/prefix.ha path/stack.ha
$(HARECACHE)/std/path.ssa: $(path_ha) $(HARECACHE)/std/bytes.td $(HARECACHE)/std/strings.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/path.td.tmp -N path $(path_ha)

time_ha = time/+freebsd/functions.ha time/arithm.ha time/conv.ha time/types.ha
$(HARECACHE)/std/time.ssa: $(time_ha) $(HARECACHE)/std/errors.td $(HARECACHE)/std/math.td $(HARECACHE)/std/rt.td $(HARECACHE)/std/types.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/time.td.tmp -N time $(time_ha)

fs_ha = fs/fs.ha fs/types.ha fs/util.ha
$(HARECACHE)/std/fs.ssa: $(fs_ha) $(HARECACHE)/std/encoding_utf8.td $(HARECACHE)/std/errors.td $(HARECACHE)/std/io.td $(HARECACHE)/std/path.td $(HARECACHE)/std/strings.td $(HARECACHE)/std/time.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/fs.td.tmp -N fs $(fs_ha)

types_c_ha = types/c/arch+x86_64.ha types/c/strings.ha types/c/types.ha
$(HARECACHE)/std/types_c.ssa: $(types_c_ha) $(HARECACHE)/std/encoding_utf8.td $(HARECACHE)/std/types.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/types_c.td.tmp -N types::c $(types_c_ha)

os_ha = os/+freebsd/dirfdfs.ha os/+freebsd/exit.ha os/+freebsd/fcntl.ha os/+freebsd/fs.ha os/+freebsd/memfd.ha os/+freebsd/platform_environ.ha os/+freebsd/shm.ha os/+freebsd/status.ha os/+freebsd/stdfd.ha os/environ.ha os/os.ha
$(HARECACHE)/os.ssa: $(os_ha) $(HARECACHE)/bufio.td $(HARECACHE)/errors.td $(HARECACHE)/fs.td $(HARECACHE)/io.td $(HARECACHE)/path.td $(HARECACHE)/rt.td $(HARECACHE)/strings.td $(HARECACHE)/time.td $(HARECACHE)/types_c.td
	@mkdir -p -- "$(HARECACHE)"
	@printf 'HAREC\t%s\n' "$@"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/os.td.tmp -N os $(os_ha)

strconv_ha = strconv/decimal.ha strconv/ftos.ha strconv/ftos_ryu.ha strconv/itos.ha strconv/stof.ha strconv/stof_data.ha strconv/stoi.ha strconv/stou.ha strconv/types.ha strconv/utos.ha
$(HARECACHE)/strconv.ssa: $(strconv_ha) $(HARECACHE)/ascii.td $(HARECACHE)/bytes.td $(HARECACHE)/io.td $(HARECACHE)/math.td $(HARECACHE)/memio.td $(HARECACHE)/strings.td $(HARECACHE)/types.td
	@mkdir -p -- "$(HARECACHE)"
	@printf 'HAREC\t%s\n' "$@"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/strconv.td.tmp -N strconv $(strconv_ha)

fmt_ha = fmt/iter.ha fmt/print.ha fmt/wrappers.ha
$(HARECACHE)/std/fmt.ssa: $(fmt_ha) $(HARECACHE)/std/ascii.td $(HARECACHE)/std/encoding_utf8.td $(HARECACHE)/std/io.td $(HARECACHE)/std/math.td $(HARECACHE)/std/memio.td $(HARECACHE)/std/os.td $(HARECACHE)/std/strconv.td $(HARECACHE)/std/strings.td $(HARECACHE)/std/types.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/fmt.td.tmp -N fmt $(fmt_ha)

encoding_hex_ha = encoding/hex/hex.ha
$(HARECACHE)/std/encoding_hex.ssa: $(encoding_hex_ha) $(HARECACHE)/std/ascii.td $(HARECACHE)/std/bytes.td $(HARECACHE)/std/errors.td $(HARECACHE)/std/fmt.td $(HARECACHE)/std/io.td $(HARECACHE)/std/memio.td $(HARECACHE)/std/os.td $(HARECACHE)/std/strconv.td $(HARECACHE)/std/strings.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/encoding_hex.td.tmp -N encoding::hex $(encoding_hex_ha)

sort_ha = sort/bisect.ha sort/search.ha sort/sort.ha sort/types.ha
$(HARECACHE)/std/sort.ssa: $(sort_ha) $(HARECACHE)/std/math.td $(HARECACHE)/std/types.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/sort.td.tmp -N sort $(sort_ha)

hare_lex_ha = hare/lex/lex.ha hare/lex/token.ha
$(HARECACHE)/std/hare_lex.ssa: $(hare_lex_ha) $(HARECACHE)/std/ascii.td $(HARECACHE)/std/bufio.td $(HARECACHE)/std/encoding_utf8.td $(HARECACHE)/std/fmt.td $(HARECACHE)/std/io.td $(HARECACHE)/std/memio.td $(HARECACHE)/std/path.td $(HARECACHE)/std/sort.td $(HARECACHE)/std/sort_cmp.td $(HARECACHE)/std/strconv.td $(HARECACHE)/std/strings.td $(HARECACHE)/std/types.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/hare_lex.td.tmp -N hare::lex $(hare_lex_ha)

hare_ast_ha = hare/ast/decl.ha hare/ast/expr.ha hare/ast/ident.ha hare/ast/import.ha hare/ast/type.ha hare/ast/unit.ha
$(HARECACHE)/std/hare_ast.ssa: $(hare_ast_ha) $(HARECACHE)/std/hare_lex.td $(HARECACHE)/std/strings.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/hare_ast.td.tmp -N hare::ast $(hare_ast_ha)

hare_parse_ha = hare/parse/decl.ha hare/parse/expr.ha hare/parse/ident.ha hare/parse/import.ha hare/parse/parse.ha hare/parse/type.ha hare/parse/unit.ha
$(HARECACHE)/std/hare_parse.ssa: $(hare_parse_ha) $(HARECACHE)/std/ascii.td $(HARECACHE)/std/bufio.td $(HARECACHE)/std/fmt.td $(HARECACHE)/std/hare_ast.td $(HARECACHE)/std/hare_lex.td $(HARECACHE)/std/io.td $(HARECACHE)/std/math.td $(HARECACHE)/std/memio.td $(HARECACHE)/std/strings.td $(HARECACHE)/std/types.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/hare_parse.td.tmp -N hare::parse $(hare_parse_ha)

hare_unparse_ha = hare/unparse/decl.ha hare/unparse/expr.ha hare/unparse/ident.ha hare/unparse/import.ha hare/unparse/syn.ha hare/unparse/type.ha hare/unparse/unit.ha hare/unparse/util.ha
$(HARECACHE)/std/hare_unparse.ssa: $(hare_unparse_ha) $(HARECACHE)/std/fmt.td $(HARECACHE)/std/hare_ast.td $(HARECACHE)/std/hare_lex.td $(HARECACHE)/std/io.td $(HARECACHE)/std/memio.td $(HARECACHE)/std/strings.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/hare_unparse.td.tmp -N hare::unparse $(hare_unparse_ha)

hare_module_ha = hare/module/cache.ha hare/module/deps.ha hare/module/format.ha hare/module/srcs.ha hare/module/types.ha hare/module/util.ha
$(HARECACHE)/hare_module.ssa: $(hare_module_ha) $(HARECACHE)/ascii.td $(HARECACHE)/bufio.td $(HARECACHE)/bytes.td $(HARECACHE)/encoding_utf8.td $(HARECACHE)/fmt.td $(HARECACHE)/fs.td $(HARECACHE)/hare_ast.td $(HARECACHE)/hare_lex.td $(HARECACHE)/hare_parse.td $(HARECACHE)/hare_unparse.td $(HARECACHE)/io.td $(HARECACHE)/memio.td $(HARECACHE)/os.td $(HARECACHE)/path.td $(HARECACHE)/sort.td $(HARECACHE)/sort_cmp.td $(HARECACHE)/strings.td $(HARECACHE)/time.td
	@mkdir -p -- "$(HARECACHE)"
	@printf 'HAREC\t%s\n' "$@"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/hare_module.td.tmp -N hare::module $(hare_module_ha)

unix_ha = unix/+freebsd/creds.ha unix/+freebsd/nice.ha unix/+freebsd/pipe.ha unix/+freebsd/umask.ha
$(HARECACHE)/std/unix.ssa: $(unix_ha) $(HARECACHE)/std/errors.td $(HARECACHE)/std/fs.td $(HARECACHE)/std/io.td $(HARECACHE)/std/rt.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/unix.td.tmp -N unix $(unix_ha)

unix_signal_ha = unix/signal/+freebsd.ha unix/signal/types.ha
$(HARECACHE)/std/unix_signal.ssa: $(unix_signal_ha) $(HARECACHE)/std/errors.td $(HARECACHE)/std/rt.td $(HARECACHE)/std/time.td $(HARECACHE)/std/unix.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/unix_signal.td.tmp -N unix::signal $(unix_signal_ha)

os_exec_ha = os/exec/+freebsd/exec.ha os/exec/+freebsd/platform_cmd.ha os/exec/+freebsd/process.ha os/exec/cmd.ha os/exec/types.ha
$(HARECACHE)/std/os_exec.ssa: $(os_exec_ha) $(HARECACHE)/std/errors.td $(HARECACHE)/std/fmt.td $(HARECACHE)/std/fs.td $(HARECACHE)/std/io.td $(HARECACHE)/std/os.td $(HARECACHE)/std/path.td $(HARECACHE)/std/rt.td $(HARECACHE)/std/strings.td $(HARECACHE)/std/time.td $(HARECACHE)/std/types_c.td $(HARECACHE)/std/unix.td $(HARECACHE)/std/unix_signal.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/os_exec.td.tmp -N os::exec $(os_exec_ha)

shlex_ha = shlex/escape.ha shlex/split.ha
$(HARECACHE)/std/shlex.ssa: $(shlex_ha) $(HARECACHE)/std/ascii.td $(HARECACHE)/std/encoding_utf8.td $(HARECACHE)/std/io.td $(HARECACHE)/std/memio.td $(HARECACHE)/std/strings.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/shlex.td.tmp -N shlex $(shlex_ha)

unix_tty_ha = unix/tty/+freebsd/isatty.ha unix/tty/+freebsd/open.ha unix/tty/+freebsd/pgid.ha unix/tty/+freebsd/pty.ha unix/tty/+freebsd/termios.ha unix/tty/+freebsd/winsize.ha unix/tty/types.ha
$(HARECACHE)/unix_tty.ssa: $(unix_tty_ha) $(HARECACHE)/errors.td $(HARECACHE)/fmt.td $(HARECACHE)/fs.td $(HARECACHE)/io.td $(HARECACHE)/os.td $(HARECACHE)/os_exec.td $(HARECACHE)/rt.td $(HARECACHE)/types_c.td
	@mkdir -p -- "$(HARECACHE)"
	@printf 'HAREC\t%s\n' "$@"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/unix_tty.td.tmp -N unix::tty $(unix_tty_ha)

cmd_hare_build_ha = cmd/hare/build/gather.ha cmd/hare/build/platform.ha cmd/hare/build/queue.ha cmd/hare/build/types.ha cmd/hare/build/util.ha
$(HARECACHE)/std/cmd_hare_build.ssa: $(cmd_hare_build_ha) $(HARECACHE)/std/crypto_sha256.td $(HARECACHE)/std/encoding_hex.td $(HARECACHE)/std/fmt.td $(HARECACHE)/std/fs.td $(HARECACHE)/std/hare_ast.td $(HARECACHE)/std/hare_module.td $(HARECACHE)/std/hare_unparse.td $(HARECACHE)/std/hash.td $(HARECACHE)/std/io.td $(HARECACHE)/std/memio.td $(HARECACHE)/std/os.td $(HARECACHE)/std/os_exec.td $(HARECACHE)/std/path.td $(HARECACHE)/std/shlex.td $(HARECACHE)/std/sort.td $(HARECACHE)/std/strings.td $(HARECACHE)/std/unix_tty.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/cmd_hare_build.td.tmp -N cmd::hare::build $(cmd_hare_build_ha)

dirs_ha = dirs/xdg.ha
$(HARECACHE)/std/dirs.ssa: $(dirs_ha) $(HARECACHE)/std/errors.td $(HARECACHE)/std/fmt.td $(HARECACHE)/std/fs.td $(HARECACHE)/std/os.td $(HARECACHE)/std/path.td $(HARECACHE)/std/unix.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/dirs.td.tmp -N dirs $(dirs_ha)

getopt_ha = getopt/getopts.ha
$(HARECACHE)/std/getopt.ssa: $(getopt_ha) $(HARECACHE)/std/fmt.td $(HARECACHE)/std/io.td $(HARECACHE)/std/os.td $(HARECACHE)/std/strings.td
	@mkdir -p -- "$(HARECACHE)/std"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/std/getopt.td.tmp -N getopt $(getopt_ha)

cmd_hare_ha = cmd/hare/arch.ha cmd/hare/build.ha cmd/hare/cache.ha cmd/hare/deps.ha cmd/hare/error.ha cmd/hare/main.ha cmd/hare/util.ha cmd/hare/version.ha
$(HARECACHE)/cmd_hare.ssa: $(cmd_hare_ha) $(HARECACHE)/ascii.td $(HARECACHE)/bufio.td $(HARECACHE)/cmd_hare_build.td $(HARECACHE)/crypto_sha256.td $(HARECACHE)/dirs.td $(HARECACHE)/errors.td $(HARECACHE)/fmt.td $(HARECACHE)/fs.td $(HARECACHE)/getopt.td $(HARECACHE)/hare_ast.td $(HARECACHE)/hare_lex.td $(HARECACHE)/hare_module.td $(HARECACHE)/hare_parse.td $(HARECACHE)/hash.td $(HARECACHE)/io.td $(HARECACHE)/memio.td $(HARECACHE)/os.td $(HARECACHE)/os_exec.td $(HARECACHE)/path.td $(HARECACHE)/shlex.td $(HARECACHE)/sort.td $(HARECACHE)/sort_cmp.td $(HARECACHE)/strconv.td $(HARECACHE)/strings.td $(HARECACHE)/unix_tty.td
	@mkdir -p -- "$(HARECACHE)"
	@printf 'HAREC\t%s\n' "$@"
	@$(TDENV) $(HAREC) $(HARECFLAGS) -o $@ -t $(HARECACHE)/cmd_hare.td.tmp $(HARE_DEFINES)  $(cmd_hare_ha)
