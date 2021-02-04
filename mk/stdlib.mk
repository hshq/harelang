# This file is generated by the gen-stdlib script, do not edit it by hand

# rt
rtscript=$(STDLIB)/rt/hare.sc
stdlib_rt_srcs= \
	$(STDLIB)/rt/$(PLATFORM)/abort.ha \
	$(STDLIB)/rt/$(PLATFORM)/env.ha \
	$(STDLIB)/rt/$(PLATFORM)/errno.ha \
	$(STDLIB)/rt/$(PLATFORM)/start.ha \
	$(STDLIB)/rt/$(PLATFORM)/syscallno$(ARCH).ha \
	$(STDLIB)/rt/$(PLATFORM)/syscalls.ha \
	$(STDLIB)/rt/$(PLATFORM)/segmalloc.ha \
	$(STDLIB)/rt/malloc.ha \
	$(STDLIB)/rt/memcpy.ha \
	$(STDLIB)/rt/memset.ha \
	$(STDLIB)/rt/strcmp.ha \
	$(STDLIB)/rt/start-test.ha 

$(HARECACHE)/rt/rt.ssa: $(stdlib_rt_srcs) $(stdlib_rt)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/rt
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) -o $@ -Nrt \
		-t$(HARECACHE)/rt/rt.td $(stdlib_rt_srcs)

$(HARECACHE)/rt/syscall.o: $(STDLIB)/rt/$(PLATFORM)/syscall$(ARCH).s
	@printf 'AS \t$@\n'
	@mkdir -p $(HARECACHE)/rt
	@as -o $@ $<

$(HARECACHE)/rt/start.o: $(STDLIB)/rt/$(PLATFORM)/start.s
	@printf 'AS \t$@\n'
	@mkdir -p $(HARECACHE)/rt
	@as -o $@ $<

$(HARECACHE)/rt/rt.a: $(HARECACHE)/rt/rt.o $(HARECACHE)/rt/syscall.o
	@printf 'AR\t$@\n'
	@$(AR) -csr $@ $(HARECACHE)/rt/rt.o $(HARECACHE)/rt/syscall.o

stdlib_rt=$(HARECACHE)/rt/rt.a
stdlib_start=$(HARECACHE)/rt/start.o
hare_stdlib_deps+=$(stdlib_rt)

# ascii
stdlib_ascii_srcs= \
	$(STDLIB)/ascii/ctype.ha 

$(HARECACHE)/ascii/ascii.ssa: $(stdlib_ascii_srcs) $(stdlib_rt)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/ascii
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) -o $@ -Nascii \
		-t$(HARECACHE)/ascii/ascii.td $(stdlib_ascii_srcs)

stdlib_stdlib_ascii=$(HARECACHE)/ascii/ascii.o
hare_stdlib_deps+=$(stdlib_stdlib_ascii)

# bytes
stdlib_bytes_srcs= \
	$(STDLIB)/bytes/copy.ha \
	$(STDLIB)/bytes/equal.ha \
	$(STDLIB)/bytes/index.ha \
	$(STDLIB)/bytes/reverse.ha 

$(HARECACHE)/bytes/bytes.ssa: $(stdlib_bytes_srcs) $(stdlib_rt)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/bytes
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) -o $@ -Nbytes \
		-t$(HARECACHE)/bytes/bytes.td $(stdlib_bytes_srcs)

stdlib_stdlib_bytes=$(HARECACHE)/bytes/bytes.o
hare_stdlib_deps+=$(stdlib_stdlib_bytes)

# types
stdlib_types_srcs= \
	$(STDLIB)/types/limits.ha \
	$(STDLIB)/types/classes.ha \
	$(STDLIB)/types/arch$(ARCH).ha 

$(HARECACHE)/types/types.ssa: $(stdlib_types_srcs) $(stdlib_rt)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/types
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) -o $@ -Ntypes \
		-t$(HARECACHE)/types/types.td $(stdlib_types_srcs)

stdlib_stdlib_types=$(HARECACHE)/types/types.o
hare_stdlib_deps+=$(stdlib_stdlib_types)

# strconv
stdlib_strconv_srcs= \
	$(STDLIB)/strconv/itos.ha \
	$(STDLIB)/strconv/utos.ha \
	$(STDLIB)/strconv/numeric.ha 

$(HARECACHE)/strconv/strconv.ssa: $(stdlib_strconv_srcs) $(stdlib_rt) $(stdlib_stdlib_types)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/strconv
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) -o $@ -Nstrconv \
		-t$(HARECACHE)/strconv/strconv.td $(stdlib_strconv_srcs)

stdlib_stdlib_strconv=$(HARECACHE)/strconv/strconv.o
hare_stdlib_deps+=$(stdlib_stdlib_strconv)

# io
stdlib_io_srcs= \
	$(STDLIB)/io/types.ha \
	$(STDLIB)/io/copy.ha \
	$(STDLIB)/io/println.ha \
	$(STDLIB)/io/stream.ha 

$(HARECACHE)/io/io.ssa: $(stdlib_io_srcs) $(stdlib_rt)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/io
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) -o $@ -Nio \
		-t$(HARECACHE)/io/io.td $(stdlib_io_srcs)

stdlib_stdlib_io=$(HARECACHE)/io/io.o
hare_stdlib_deps+=$(stdlib_stdlib_io)

# encoding::utf8
stdlib_encoding_utf8_srcs= \
	$(STDLIB)/encoding/utf8/rune.ha \
	$(STDLIB)/encoding/utf8/decode.ha \
	$(STDLIB)/encoding/utf8/encode.ha 

$(HARECACHE)/encoding/utf8/encoding.utf8.ssa: $(stdlib_encoding_utf8_srcs) $(stdlib_rt) $(stdlib_stdlib_types)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/encoding/utf8
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) -o $@ -Nencoding::utf8 \
		-t$(HARECACHE)/encoding/utf8/encoding.utf8.td $(stdlib_encoding_utf8_srcs)

stdlib_stdlib_encoding_utf8=$(HARECACHE)/encoding/utf8/encoding.utf8.o
hare_stdlib_deps+=$(stdlib_stdlib_encoding_utf8)

# strings
stdlib_strings_srcs= \
	$(STDLIB)/strings/cstrings.ha \
	$(STDLIB)/strings/dup.ha \
	$(STDLIB)/strings/iter.ha \
	$(STDLIB)/strings/utf8.ha 

$(HARECACHE)/strings/strings.ssa: $(stdlib_strings_srcs) $(stdlib_rt) $(stdlib_stdlib_encoding_utf8) $(stdlib_stdlib_types)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/strings
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) -o $@ -Nstrings \
		-t$(HARECACHE)/strings/strings.td $(stdlib_strings_srcs)

stdlib_stdlib_strings=$(HARECACHE)/strings/strings.o
hare_stdlib_deps+=$(stdlib_stdlib_strings)

# os
stdlib_os_srcs= \
	$(STDLIB)/os/$(PLATFORM)/environ.ha \
	$(STDLIB)/os/$(PLATFORM)/errors.ha \
	$(STDLIB)/os/$(PLATFORM)/exit.ha \
	$(STDLIB)/os/$(PLATFORM)/fdstream.ha \
	$(STDLIB)/os/$(PLATFORM)/open.ha \
	$(STDLIB)/os/$(PLATFORM)/stdfd.ha \
	$(STDLIB)/os/environ.ha \
	$(STDLIB)/os/stdfd.ha 

$(HARECACHE)/os/os.ssa: $(stdlib_os_srcs) $(stdlib_rt) $(stdlib_stdlib_strings) $(stdlib_stdlib_types)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/os
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) -o $@ -Nos \
		-t$(HARECACHE)/os/os.td $(stdlib_os_srcs)

stdlib_stdlib_os=$(HARECACHE)/os/os.o
hare_stdlib_deps+=$(stdlib_stdlib_os)

# fmt
stdlib_fmt_srcs= \
	$(STDLIB)/fmt/fmt.ha 

$(HARECACHE)/fmt/fmt.ssa: $(stdlib_fmt_srcs) $(stdlib_rt) $(stdlib_stdlib_io) $(stdlib_stdlib_os) $(stdlib_stdlib_strconv) $(stdlib_stdlib_strings) $(stdlib_stdlib_types)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/fmt
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) -o $@ -Nfmt \
		-t$(HARECACHE)/fmt/fmt.td $(stdlib_fmt_srcs)

stdlib_stdlib_fmt=$(HARECACHE)/fmt/fmt.o
hare_stdlib_deps+=$(stdlib_stdlib_fmt)

# rt
testlib_rt_srcs= \
	$(STDLIB)/rt/$(PLATFORM)/abort.ha \
	$(STDLIB)/rt/$(PLATFORM)/env.ha \
	$(STDLIB)/rt/$(PLATFORM)/errno.ha \
	$(STDLIB)/rt/$(PLATFORM)/start.ha \
	$(STDLIB)/rt/$(PLATFORM)/syscallno$(ARCH).ha \
	$(STDLIB)/rt/$(PLATFORM)/syscalls.ha \
	$(STDLIB)/rt/$(PLATFORM)/segmalloc.ha \
	$(STDLIB)/rt/malloc.ha \
	$(STDLIB)/rt/memcpy.ha \
	$(STDLIB)/rt/memset.ha \
	$(STDLIB)/rt/strcmp.ha \
	$(STDLIB)/rt/+test/start.ha 

$(TESTCACHE)/rt/rt.ssa: $(testlib_rt_srcs) $(testlib_rt)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(TESTCACHE)/rt
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) -o $@ -Nrt \
		-t$(TESTCACHE)/rt/rt.td $(testlib_rt_srcs)

$(TESTCACHE)/rt/syscall.o: $(STDLIB)/rt/$(PLATFORM)/syscall$(ARCH).s
	@printf 'AS \t$@\n'
	@mkdir -p $(TESTCACHE)/rt
	@as -o $@ $<

$(TESTCACHE)/rt/start.o: $(STDLIB)/rt/$(PLATFORM)/start.s
	@printf 'AS \t$@\n'
	@mkdir -p $(TESTCACHE)/rt
	@as -o $@ $<

$(TESTCACHE)/rt/rt.a: $(TESTCACHE)/rt/rt.o $(TESTCACHE)/rt/syscall.o
	@printf 'AR\t$@\n'
	@$(AR) -csr $@ $(TESTCACHE)/rt/rt.o $(TESTCACHE)/rt/syscall.o

testlib_rt=$(TESTCACHE)/rt/rt.a
testlib_start=$(TESTCACHE)/rt/start.o
hare_testlib_deps+=$(testlib_rt)

# ascii
testlib_ascii_srcs= \
	$(STDLIB)/ascii/ctype.ha 

$(TESTCACHE)/ascii/ascii.ssa: $(testlib_ascii_srcs) $(testlib_rt)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(TESTCACHE)/ascii
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) -o $@ -Nascii \
		-t$(TESTCACHE)/ascii/ascii.td $(testlib_ascii_srcs)

testlib_testlib_ascii=$(TESTCACHE)/ascii/ascii.o
hare_testlib_deps+=$(testlib_testlib_ascii)

# bytes
testlib_bytes_srcs= \
	$(STDLIB)/bytes/copy.ha \
	$(STDLIB)/bytes/equal.ha \
	$(STDLIB)/bytes/index.ha \
	$(STDLIB)/bytes/reverse.ha 

$(TESTCACHE)/bytes/bytes.ssa: $(testlib_bytes_srcs) $(testlib_rt)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(TESTCACHE)/bytes
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) -o $@ -Nbytes \
		-t$(TESTCACHE)/bytes/bytes.td $(testlib_bytes_srcs)

testlib_testlib_bytes=$(TESTCACHE)/bytes/bytes.o
hare_testlib_deps+=$(testlib_testlib_bytes)

# types
testlib_types_srcs= \
	$(STDLIB)/types/limits.ha \
	$(STDLIB)/types/classes.ha \
	$(STDLIB)/types/arch$(ARCH).ha 

$(TESTCACHE)/types/types.ssa: $(testlib_types_srcs) $(testlib_rt)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(TESTCACHE)/types
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) -o $@ -Ntypes \
		-t$(TESTCACHE)/types/types.td $(testlib_types_srcs)

testlib_testlib_types=$(TESTCACHE)/types/types.o
hare_testlib_deps+=$(testlib_testlib_types)

# strconv
testlib_strconv_srcs= \
	$(STDLIB)/strconv/itos.ha \
	$(STDLIB)/strconv/utos.ha \
	$(STDLIB)/strconv/numeric.ha 

$(TESTCACHE)/strconv/strconv.ssa: $(testlib_strconv_srcs) $(testlib_rt) $(testlib_testlib_types)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(TESTCACHE)/strconv
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) -o $@ -Nstrconv \
		-t$(TESTCACHE)/strconv/strconv.td $(testlib_strconv_srcs)

testlib_testlib_strconv=$(TESTCACHE)/strconv/strconv.o
hare_testlib_deps+=$(testlib_testlib_strconv)

# io
testlib_io_srcs= \
	$(STDLIB)/io/types.ha \
	$(STDLIB)/io/copy.ha \
	$(STDLIB)/io/println.ha \
	$(STDLIB)/io/stream.ha 

$(TESTCACHE)/io/io.ssa: $(testlib_io_srcs) $(testlib_rt)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(TESTCACHE)/io
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) -o $@ -Nio \
		-t$(TESTCACHE)/io/io.td $(testlib_io_srcs)

testlib_testlib_io=$(TESTCACHE)/io/io.o
hare_testlib_deps+=$(testlib_testlib_io)

# encoding::utf8
testlib_encoding_utf8_srcs= \
	$(STDLIB)/encoding/utf8/rune.ha \
	$(STDLIB)/encoding/utf8/decode.ha \
	$(STDLIB)/encoding/utf8/encode.ha 

$(TESTCACHE)/encoding/utf8/encoding.utf8.ssa: $(testlib_encoding_utf8_srcs) $(testlib_rt) $(testlib_testlib_types)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(TESTCACHE)/encoding/utf8
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) -o $@ -Nencoding::utf8 \
		-t$(TESTCACHE)/encoding/utf8/encoding.utf8.td $(testlib_encoding_utf8_srcs)

testlib_testlib_encoding_utf8=$(TESTCACHE)/encoding/utf8/encoding.utf8.o
hare_testlib_deps+=$(testlib_testlib_encoding_utf8)

# strings
testlib_strings_srcs= \
	$(STDLIB)/strings/cstrings.ha \
	$(STDLIB)/strings/dup.ha \
	$(STDLIB)/strings/iter.ha \
	$(STDLIB)/strings/utf8.ha 

$(TESTCACHE)/strings/strings.ssa: $(testlib_strings_srcs) $(testlib_rt) $(testlib_testlib_encoding_utf8) $(testlib_testlib_types)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(TESTCACHE)/strings
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) -o $@ -Nstrings \
		-t$(TESTCACHE)/strings/strings.td $(testlib_strings_srcs)

testlib_testlib_strings=$(TESTCACHE)/strings/strings.o
hare_testlib_deps+=$(testlib_testlib_strings)

# os
testlib_os_srcs= \
	$(STDLIB)/os/$(PLATFORM)/environ.ha \
	$(STDLIB)/os/$(PLATFORM)/errors.ha \
	$(STDLIB)/os/$(PLATFORM)/exit.ha \
	$(STDLIB)/os/$(PLATFORM)/fdstream.ha \
	$(STDLIB)/os/$(PLATFORM)/open.ha \
	$(STDLIB)/os/$(PLATFORM)/stdfd.ha \
	$(STDLIB)/os/environ.ha \
	$(STDLIB)/os/stdfd.ha 

$(TESTCACHE)/os/os.ssa: $(testlib_os_srcs) $(testlib_rt) $(testlib_testlib_strings) $(testlib_testlib_types)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(TESTCACHE)/os
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) -o $@ -Nos \
		-t$(TESTCACHE)/os/os.td $(testlib_os_srcs)

testlib_testlib_os=$(TESTCACHE)/os/os.o
hare_testlib_deps+=$(testlib_testlib_os)

# fmt
testlib_fmt_srcs= \
	$(STDLIB)/fmt/fmt.ha 

$(TESTCACHE)/fmt/fmt.ssa: $(testlib_fmt_srcs) $(testlib_rt) $(testlib_testlib_io) $(testlib_testlib_os) $(testlib_testlib_strconv) $(testlib_testlib_strings) $(testlib_testlib_types)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(TESTCACHE)/fmt
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) -o $@ -Nfmt \
		-t$(TESTCACHE)/fmt/fmt.td $(testlib_fmt_srcs)

testlib_testlib_fmt=$(TESTCACHE)/fmt/fmt.o
hare_testlib_deps+=$(testlib_testlib_fmt)

