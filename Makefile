.POSIX:
.SUFFIXES:
include config.mk
TESTCACHE=$(HARECACHE)/+test
TESTHAREFLAGS=$(HAREFLAGS) -T +test
STDLIB=.

all:

.SUFFIXES: .ha .ssa .s .o .scd .1
.ssa.s:
	@printf 'QBE\t$@\n'
	@$(QBE) -o $@ $<

.s.o:
	@printf 'AS\t$@\n'
	@$(AS) -g -o $@ $<

.scd.1:
	@printf 'SCDOC\t$@\n'
	@$(SCDOC) < $< > $@

include stdlib.mk

hare_srcs=\
	./cmd/hare/plan.ha \
	./cmd/hare/subcmds.ha \
	./cmd/hare/schedule.ha \
	./cmd/hare/main.ha

harec_srcs=\
	./cmd/harec/main.ha \
	./cmd/harec/errors.ha

haredoc_srcs=\
	./cmd/haredoc/main.ha \
	./cmd/haredoc/errors.ha \
	./cmd/haredoc/unparse.ha

$(HARECACHE)/hare.ssa: $(hare_srcs) $(hare_stdlib_deps)
	@printf 'HAREC\t$@\n'
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) \
		-D PLATFORM:str='"'"$$(./scripts/platform)"'"' \
		-D VERSION:str='"'"$$(./scripts/version)"'"' \
		-D HAREPATH:str='"'"$(HAREPATH)"'"' \
		-o $@ $(hare_srcs)

$(TESTCACHE)/hare.ssa: $(hare_srcs) $(hare_testlib_deps)
	@printf 'HAREC\t$@\n'
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) \
		-D PLATFORM:str='"'"$$(./scripts/platform)"'"' \
		-D VERSION:str='"'"$$(./scripts/version)"'"' \
		-D HAREPATH:str='"'"$(HAREPATH)"'"' \
		-o $@ $(hare_srcs)

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

.bin/harec: .bin/hare $(harec_srcs)
	@mkdir -p .bin
	@printf 'HARE\t$@\n'
	@env HAREPATH=. ./.bin/hare build -o .bin/harec ./cmd/harec

.bin/haredoc: .bin/hare $(haredoc_srcs)
	@mkdir -p .bin
	@printf 'HARE\t$@\n'
	@env HAREPATH=. ./.bin/hare build -o .bin/haredoc ./cmd/haredoc

docs/hare.1: docs/hare.scd

docs: docs/hare.1

clean:
	@rm -rf .cache .bin

check: .bin/hare-tests
	@./.bin/hare-tests

all: .bin/hare .bin/harec .bin/haredoc

.PHONY: all clean check
