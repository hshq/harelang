# rt
librt_srcs=$(STDLIB)/rt/$(PLATFORM)/abort.ha \
	$(STDLIB)/rt/$(PLATFORM)/env.ha \
	$(STDLIB)/rt/$(PLATFORM)/errno.ha \
	$(STDLIB)/rt/$(PLATFORM)/start.ha \
	$(STDLIB)/rt/$(PLATFORM)/syscallno$(ARCH).ha \
	$(STDLIB)/rt/$(PLATFORM)/syscalls.ha

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

# io
libio_srcs=\
	$(STDLIB)/io/println.ha

$(HARECACHE)/io/io.ssa: $(libio_srcs) $(stdlib_rt)
	@printf 'HAREC \t$@\n'
	@mkdir -p $(HARECACHE)/io
	@$(HAREC) -o $@ -Nio -t$(HARECACHE)/io/io.td $(libio_srcs)

stdlib_io=$(HARECACHE)/io/io.o
