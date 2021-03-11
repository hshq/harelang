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
	plan.ha \
	subcmds.ha \
	main.ha

$(HARECACHE)/hare.ssa: $(hare_srcs) $(hare_stdlib_deps)
	@printf 'HAREC\t$@\n'
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) -o $@ $(hare_srcs)

$(TESTCACHE)/hare.ssa: $(hare_srcs) $(hare_testlib_deps)
	@printf 'HAREC\t$@\n'
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) -o $@ $(hare_srcs)

hare: $(HARECACHE)/hare.o
	@printf 'LD\t$@\n'
	@$(LD) -T $(rtscript) --gc-sections -o $@ \
		$(HARECACHE)/hare.o $(hare_stdlib_deps)

hare-tests: $(TESTCACHE)/hare.o
	@printf 'LD\t$@\n'
	@$(LD) -T $(rtscript) -o $@ \
		$(TESTCACHE)/hare.o $(hare_testlib_deps)

clean:
	@rm -rf cache
	@rm -f hare hare-tests

check: hare-tests
	@./hare-tests

all: hare

.PHONY: all clean check
