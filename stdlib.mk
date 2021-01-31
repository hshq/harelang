# TODO: Write a script to generate this file

# rt
librt_srcs=$(STDLIB)/rt/$(PLATFORM)/abort.ha \
	$(STDLIB)/rt/$(PLATFORM)/env.ha \
	$(STDLIB)/rt/$(PLATFORM)/errno.ha \
	$(STDLIB)/rt/$(PLATFORM)/start.ha \
	$(STDLIB)/rt/$(PLATFORM)/syscallno$(ARCH).ha \
	$(STDLIB)/rt/$(PLATFORM)/syscalls.ha \
	$(STDLIB)/rt/$(PLATFORM)/segmalloc.ha \
	$(STDLIB)/rt/memcpy.ha \
	$(STDLIB)/rt/malloc.ha

$(HARECACHE)/rt/rt.ssa: $(librt_srcs)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/rt
	@$(HAREC) -o $@ -Nrt -t$(HARECACHE)/rt/rt.td $(librt_srcs)

$(HARECACHE)/rt/start.o: $(STDLIB)/rt/$(PLATFORM)/start.s
	@printf 'AS \t$@\n'
	@mkdir -p $(HARECACHE)/rt
	@as -o $@ $<

$(HARECACHE)/rt/syscall.o: $(STDLIB)/rt/$(PLATFORM)/syscall$(ARCH).s
	@printf 'AS \t$@\n'
	@mkdir -p $(HARECACHE)/rt
	@as -o $@ $<

$(HARECACHE)/rt/rt.a: $(HARECACHE)/rt/rt.o $(HARECACHE)/rt/syscall.o
	@printf 'AR\t$@\n'
	@$(AR) -csr $@ $(HARECACHE)/rt/rt.o $(HARECACHE)/rt/syscall.o

stdlib_rt=$(HARECACHE)/rt/rt.a
stdlib_start=$(HARECACHE)/rt/start.o

# bytes
libbytes_srcs=\
	$(STDLIB)/bytes/equal.ha \
	$(STDLIB)/bytes/index.ha \
	$(STDLIB)/bytes/reverse.ha

$(HARECACHE)/bytes/bytes.ssa: $(libbytes_srcs) $(stdlib_rt)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/bytes
	@$(HAREC) -o $@ -Nbytes -t$(HARECACHE)/bytes/bytes.td $(libbytes_srcs)

stdlib_bytes=$(HARECACHE)/bytes/bytes.o

# types
libtypes_srcs=\
	$(STDLIB)/types/limits.ha \
	$(STDLIB)/types/classes.ha \
	$(STDLIB)/types/arch$(ARCH).ha

$(HARECACHE)/types/types.ssa: $(libtypes_srcs) $(stdlib_rt)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/types
	@$(HAREC) -o $@ -Ntypes -t$(HARECACHE)/types/types.td $(libtypes_srcs)

stdlib_types=$(HARECACHE)/types/types.o

# strconv
libstrconv_srcs=\
	$(STDLIB)/strconv/itos.ha \
	$(STDLIB)/strconv/utos.ha \
	$(STDLIB)/strconv/numeric.ha

$(HARECACHE)/strconv/strconv.ssa: $(libstrconv_srcs)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/strconv
	@$(HAREC) -o $@ -Nstrconv -t$(HARECACHE)/strconv/strconv.td $(libstrconv_srcs)

$(HARECACHE)/strconv/strconv.ssa: $(stdlib_rt) $(stdlib_bytes) $(stdlib_types)

stdlib_strconv=$(HARECACHE)/strconv/strconv.o

# io
libio_srcs=\
	$(STDLIB)/io/println.ha
	# TODO:
	#$(STDLIB)/io/types.ha \
	#$(STDLIB)/io/stream.ha

$(HARECACHE)/io/io.ssa: $(libio_srcs) $(stdlib_rt)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/io
	@$(HAREC) -o $@ -Nio -t$(HARECACHE)/io/io.td $(libio_srcs)

stdlib_io=$(HARECACHE)/io/io.o

# strings
libstrings_srcs=\
	$(STDLIB)/strings/cstrings.ha \
	$(STDLIB)/strings/utf8.ha

libstrings_deps=$(stdlib_rt) $(stdlib_types)

$(HARECACHE)/strings/strings.ssa: $(libstrings_srcs) $(libstrings_deps)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/strings
	@$(HAREC) -o $@ -Nstrings -t$(HARECACHE)/strings/strings.td $(libstrings_srcs)

stdlib_strings=$(HARECACHE)/strings/strings.o

# os
libos_srcs=\
	$(STDLIB)/os/$(PLATFORM)/environ.ha \
	$(STDLIB)/os/$(PLATFORM)/exit.ha \
	$(STDLIB)/os/environ.ha

libos_deps=$(stdlib_rt) $(stdlib_strings) $(stdlib_types)

$(HARECACHE)/os/os.ssa: $(libos_srcs) $(libos_deps)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/os
	@$(HAREC) -o $@ -Nos -t$(HARECACHE)/os/os.td $(libos_srcs)

stdlib_os=$(HARECACHE)/os/os.o
