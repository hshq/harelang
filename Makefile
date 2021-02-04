.POSIX:
.SUFFIXES:
include config.mk
TESTCACHE=$(HARECACHE)/+test
TESTHAREFLAGS=$(HAREFLAGS) -T +test

hare:

.SUFFIXES: .ha .ssa .s .o
.ssa.s:
	@printf 'QBE\t$@\n'
	@$(QBE) -o $@ $<

.s.o:
	@printf 'AS\t$@\n'
	@$(AS) -g -o $@ $<

include mk/stdlib.mk

hare_srcs=\
	main.ha

$(HARECACHE)/hare.ssa: $(hare_srcs)
	@printf 'HAREC\t$@\n'
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) -o $@ $(hare_srcs)

$(TESTCACHE)/hare.ssa: $(hare_srcs)
	@printf 'HAREC\t$@\n'
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) -o $@ $(hare_srcs)

hare: $(stdlib_start) $(hare_stdlib_deps) $(HARECACHE)/hare.o
	@printf 'LD\t$@\n'
	@$(LD) -T $(rtscript) -o $@ \
		$(stdlib_start) $(HARECACHE)/hare.o $(hare_stdlib_deps)

hare-tests: $(testlib_start) $(hare_testlib_deps) $(TESTCACHE)/hare.o
	@printf 'LD\t$@\n'
	@$(LD) -T $(rtscript) -o $@ \
		$(testlib_start) $(TESTCACHE)/hare.o $(hare_testlib_deps)

clean:
	@rm -rf cache
	@rm -f hare hare-tests

check: hare-tests
	@./hare-tests

all: hare

.PHONY: all clean check
