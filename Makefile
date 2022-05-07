.POSIX:
.SUFFIXES:
include config.mk
TESTCACHE = $(HARECACHE)/+test
TESTHAREFLAGS = $(HAREFLAGS) -T
STDLIB = .

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

hare_srcs = \
	./cmd/hare/main.ha \
	./cmd/hare/plan.ha \
	./cmd/hare/progress.ha \
	./cmd/hare/release.ha \
	./cmd/hare/schedule.ha \
	./cmd/hare/subcmds.ha

harec_srcs = \
	./cmd/harec/main.ha \
	./cmd/harec/errors.ha

haredoc_srcs = \
	./cmd/haredoc/main.ha \
	./cmd/haredoc/errors.ha \
	./cmd/haredoc/env.ha \
	./cmd/haredoc/hare.ha \
	./cmd/haredoc/html.ha \
	./cmd/haredoc/sort.ha \
	./cmd/haredoc/resolver.ha

$(HARECACHE)/hare.ssa: $(hare_srcs) $(stdlib_deps_any) $(stdlib_deps_$(PLATFORM))
	@printf 'HAREC\t$@\n'
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) \
		-D PLATFORM:str='"'"$$(./scripts/platform)"'"' \
		-D VERSION:str='"'"$$(./scripts/version)"'"' \
		-D HAREPATH:str='"'"$(HAREPATH)"'"' \
		-o $@ $(hare_srcs)

$(TESTCACHE)/hare.ssa: $(hare_srcs) $(testlib_deps_any) $(testlib_deps_$(PLATFORM))
	@printf 'HAREC\t$@\n'
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) \
		-D PLATFORM:str='"'"$$(./scripts/platform)"'"' \
		-D VERSION:str='"'"$$(./scripts/version)"'"' \
		-D HAREPATH:str='"'"$(HAREPATH)"'"' \
		-o $@ $(hare_srcs)

.bin/hare: $(HARECACHE)/hare.o
	@mkdir -p .bin
	@printf 'LD\t$@\n'
	@$(LD) --gc-sections -T $(rtscript) -o $@ \
		$(HARECACHE)/hare.o $(stdlib_deps_any) $(stdlib_deps_$(PLATFORM))

.bin/hare-tests: $(TESTCACHE)/hare.o
	@mkdir -p .bin
	@printf 'LD\t$@\n'
	@$(LD) -T $(rtscript) -o $@ \
		$(TESTCACHE)/hare.o $(testlib_deps_any) $(testlib_deps_$(PLATFORM))

.bin/harec2: .bin/hare $(harec_srcs)
	@mkdir -p .bin
	@printf 'HARE\t$@\n'
	@env HAREPATH=. HAREC=$(HAREC) QBE=$(QBE) ./.bin/hare build -o .bin/harec2 ./cmd/harec

.bin/haredoc: .bin/hare $(haredoc_srcs)
	@mkdir -p .bin
	@printf 'HARE\t$@\n'
	@env HAREPATH=. HAREC=$(HAREC) QBE=$(QBE) ./.bin/hare build \
		-D HAREPATH:str='"'"$(HAREPATH)"'"' \
		-o .bin/haredoc ./cmd/haredoc

docs/hare.1: docs/hare.scd
docs/haredoc.1: docs/haredoc.scd

docs: docs/hare.1 docs/haredoc.1

clean:
	rm -rf .cache .bin docs/hare.1 docs/haredoc.1

check: .bin/hare-tests
	@./.bin/hare-tests

scripts/gen-docs: scripts/gen-stdlib
scripts/gen-stdlib: scripts/gen-stdlib.sh

all: .bin/hare .bin/harec2 .bin/haredoc

install: docs scripts/install-mods
	mkdir -p $(DESTDIR)$(BINDIR) $(DESTDIR)$(MANDIR)/man1 \
		$(DESTDIR)$(SRCDIR)/hare/stdlib $(DESTDIR)$(LOCALSRCDIR)
	install -m755 .bin/hare $(DESTDIR)$(BINDIR)/hare
	install -m755 .bin/haredoc $(DESTDIR)$(BINDIR)/haredoc
	install -m644 docs/hare.1 $(DESTDIR)$(MANDIR)/man1/hare.1
	install -m644 docs/haredoc.1 $(DESTDIR)$(MANDIR)/man1/haredoc.1
	./scripts/install-mods "$(DESTDIR)$(SRCDIR)/hare/stdlib"

.PHONY: all clean check install .bin/harec2 .bin/haredoc
