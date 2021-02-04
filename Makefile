.POSIX:
.SUFFIXES:
include config.mk
HAREC:=HARECACHE=$(HARECACHE) $(HAREC)

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
	@$(HAREC) -o $@ $(hare_srcs)

hare: $(stdlib_start) $(hare_deps) $(HARECACHE)/hare.o
	@printf 'LD\t$@\n'
	@$(LD) -T $(rtscript) -o $@ \
		$(stdlib_start) $(HARECACHE)/hare.o $(hare_deps)

clean:
	@rm -rf cache
	@rm -f hare

all: hare

.PHONY: all clean
