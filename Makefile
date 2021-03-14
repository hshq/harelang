.POSIX:
.SUFFIXES:
include config.mk
TESTCACHE=$(HARECACHE)/+test
TESTHAREFLAGS=$(HAREFLAGS) -T +test
STDLIB=.

.bin/hare:

.SUFFIXES: .ha .ssa .s .o
.ssa.s:
	@printf 'QBE\t$@\n'
	@$(QBE) -o $@ $<

.s.o:
	@printf 'AS\t$@\n'
	@$(AS) -g -o $@ $<

include stdlib.mk

hare_srcs=\
	./cmd/hare/plan.ha \
	./cmd/hare/subcmds.ha \
	./cmd/hare/schedule.ha \
	./cmd/hare/main.ha

$(HARECACHE)/hare.ssa: $(hare_srcs) $(hare_stdlib_deps)
	@printf 'HAREC\t$@\n'
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) -o $@ $(hare_srcs)

$(TESTCACHE)/hare.ssa: $(hare_srcs) $(hare_testlib_deps)
	@printf 'HAREC\t$@\n'
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) -o $@ $(hare_srcs)

.bin/hare: $(HARECACHE)/hare.o
	@mkdir -p .bin
	@printf 'LD\t$@\n'
	@$(LD) -T $(rtscript) --gc-sections -o $@ \
		$(HARECACHE)/hare.o $(hare_stdlib_deps)

.bin/hare-tests: $(TESTCACHE)/hare.o
	@mkdir -p .bin
	@printf 'LD\t$@\n'
	@$(LD) -T $(rtscript) -o $@ \
		$(TESTCACHE)/hare.o $(hare_testlib_deps)

clean:
	@rm -rf cache .bin

check: .bin/hare-tests
	@./.bin/hare-tests

all: .bin/hare

.PHONY: all clean check
