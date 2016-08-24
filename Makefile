.PHONY: clean requirements

PATH := build/bin:$(PATH)

shells = build/bin/bash+

bash1_version = 1.14.7
shells += build/bin/bash1

bash25_version = 2.05.0
shells += build/bin/bash25
#bash25a_version = 2.05a.0
#shells += build/bin/bash25a
bash25b_version = 2.05b.13
shells += build/bin/bash25b

bash30_version = 3.0.22
shells += build/bin/bash30
bash31_version = 3.1.23
shells += build/bin/bash31
bash32_version = 3.2.57
shells += build/bin/bash32

bash40_version = 4.0.44
shells += build/bin/bash40
bash41_version = 4.1.17
shells += build/bin/bash41
bash42_version = 4.2.53
shells += build/bin/bash42
bash43_version = 4.3.46
shells += build/bin/bash43

dash_version = 0.5.9
shells += build/bin/dash

posh_version = 0.12.3
shells += build/bin/posh

#awks = build/bin/gawk3 build/bin/gawk4 build/bin/mawk \
#       build/bin/nawk build/bin/oawk
awks = build/bin/oawk build/bin/nawk

locales += build/locales/en_US.UTF-8
locales += build/locales/nb_NO.UTF-8
locales += build/locales/de_DE.UTF-8

initramfs.cpio.gz: requirements initramfs
	{ cd initramfs && pax -x sv4cpio -w .; } | gzip -9 > initramfs.cpio.gz

requirements: build/bin/pax
	@bash -c '\
	# These commands must be available \
	type aclocal autoconf bison flex gcc git gzip make pax \
	'

clean:
	rm -rf build/*/ initramfs/
	rm -f initramfs.cpio.gz fifo *~

sources/mircpio:
	git clone https://github.com/MirBSD/mircpio.git "$@"

build/mircpio: sources/mircpio
	rm -rf "$@"
	mkdir -p "$@"
	scripts/lndir "../../$<" "$@"
	cd "$@" && \
	for opts in '-flto=jobserver' '-fwhole-program --combine' ''; do \
		${CC} -DLONG_OFF_T -fno-strict-aliasing $$opts \
		    -Wl,--as-needed -o pax ar.c ar_io.c ar_subs.c buf_subs.c \
		    cache.c cpio.c file_subs.c ftree.c gen_subs.c \
		    getoldopt.c options.c pat_rep.c pax.c sel_subs.c \
		    tables.c tar.c tty_subs.c; \
		test -x pax && exit 0; \
	done; echo >&2 Compiling failed.; exit 1


build/bin/pax: build/mircpio
	mkdir -p "$(@D)"
	cp "$</pax" "$@"

## mksh

sources += sources/mksh
shells += build/bin/mksh
manpages += build/man/man1/mksh.1

build/dash-%: sources/dash
	scripts/extract-from-git "$@"
	touch "$@"

build/posh-%: sources/posh
	scripts/extract-from-git "$@"
	touch "$@"

sources/dash:
	git clone git://git.kernel.org/pub/scm/utils/dash/dash.git "$@"

sources/posh:
	git clone git://anonscm.debian.org/users/clint/posh.git "$@"

sources/mksh:
	git clone https://github.com/MirBSD/mksh.git "$@"

build/mksh: sources/mksh
	rm -rf "$@"
	mkdir -p "$@"
	cd "$@" && sh "../../$</Build.sh"

build/bin/mksh: build/mksh
	mkdir -p "$(@D)"
	cp "$</mksh" "$@"
	scripts/add-trigger 'm#' "setsid mksh -l" "mksh $$("$@" -c 'echo "$${KSH_VERSION#* * }"')"

build/man/man1/mksh.1: sources/mksh
	mkdir -p "$(@D)"
	cp "$</mksh.1" "$@"

## bash

sources += sources/bash


sources/bash:
	git clone git://git.savannah.gnu.org/bash.git "$@"

build/bash-%: sources/bash
	rm -rf "$@"
	scripts/extract-from-git "$@"

build/bin/posh: build/posh-$(posh_version)
	scripts/build-shell posh "$(posh_version)" posh
	scripts/add-trigger 'p#' 'setsid posh -l' "posh-$(posh_version)"

build/bin/dash: build/dash-$(dash_version)
	scripts/build-shell dash "$(dash_version)" dash
	scripts/add-trigger 'd#'  'setsid dash -l' "dash-$(dash_version)" \
	                    'sh#' 'setsid sh -l'   "d#"
build/bin/bash1: build/bash-$(bash1_version)
	scripts/build-shell bash $(bash1_version) bash1
	scripts/add-trigger '1#' "ln -sf bash1 /bin/bash;setsid bash -login" bash-1.14
build/bin/bash25: build/bash-$(bash25_version)
	scripts/build-shell bash $(bash25_version) bash25
	scripts/add-trigger '25#' "ln -sf bash25 /bin/bash;setsid bash --login" bash-2.05
build/bin/bash25a: build/bash-$(bash25a_version)
	scripts/build-shell bash $(bash25a_version) bash25a
	scripts/add-trigger '25a#' "ln -sf bash25a /bin/bash;setsid bash --login" bash-2.05a
build/bin/bash25b: build/bash-$(bash25b_version)
	scripts/build-shell bash $(bash25b_version) bash25b
	scripts/add-trigger '25b#' "ln -sf bash25b /bin/bash;setsid bash -l" bash-2.05b \
	                    '2#'   "ln -sf bash2 /bin/bash;setsid bash -l"   "25b#"
build/bin/bash30: build/bash-$(bash30_version)
	scripts/build-shell bash $(bash30_version) bash30
	scripts/add-trigger '30#' "ln -sf bash30 /bin/bash;setsid bash -l" bash-3.0
build/bin/bash31: build/bash-$(bash31_version)
	scripts/build-shell bash $(bash31_version) bash31
	scripts/add-trigger '31#' "ln -sf bash31 /bin/bash;setsid bash -l" bash-3.1
build/bin/bash32: build/bash-$(bash32_version)
	scripts/build-shell bash $(bash32_version) bash32
	scripts/add-trigger '32#' "ln -sf bash32 /bin/bash;setsid bash -l" bash-3.2 \
	                    '3#'  "ln -sf bash3 /bin/bash;setsid bash -l"  "32#"
build/bin/bash40: build/bash-$(bash40_version)
	scripts/build-shell bash $(bash40_version) bash40
	scripts/add-trigger '40#' "ln -sf bash40 /bin/bash;setsid bash -l" bash-4.0
build/bin/bash41: build/bash-$(bash41_version)
	scripts/build-shell bash $(bash41_version) bash41
	scripts/add-trigger '41#' "ln -sf bash41 /bin/bash;setsid bash -l" bash-4.1
build/bin/bash42: build/bash-$(bash42_version)
	scripts/build-shell bash $(bash42_version) bash42
	scripts/add-trigger '42#' "ln -sf bash42 /bin/bash;setsid bash -l" bash-4.2
build/bin/bash43: build/bash-$(bash43_version)
	scripts/build-shell bash $(bash43_version) bash43
	scripts/add-trigger '43#' "ln -sf bash43 /bin/bash;setsid bash -l" bash-4.3 \
	                    '4#'  "ln -sf bash4 /bin/bash;setsid bash -l"  "43#" \
	                    '#'   "setsid bash -l"  "43#"

build/bin/bash+: build/bash-devel
	scripts/build-shell bash devel bash+
	scripts/add-trigger '+#' "ln -sf bash+ /bin/bash; setsid bash -l" "bash-devel"

## gawk

sources/gawk:
	git clone git://git.savannah.gnu.org/gawk.git "$@"

sources += sources/gawk

build/gawk-%: sources/gawk
	scripts/extract-from-git "$@"
	cd "$@" && ./configure && make

build/bin/gawk3: build/gawk-3.1.8
	cp "$</gawk" "$@"
build/man/man1/gawk3.1: build/gawk-3.1.8
	cp "$</doc/gawk.1" "$@"
awks += build/bin/gawk3
manpages += build/man/man1/gawk3.1

build/bin/gawk4: build/gawk-4.1.1
	cp "$</gawk" "$@"
build/man/man1/gawk4.1: build/gawk-4.1.1
	cp "$</doc/gawk.1" "$@"
awks += build/bin/gawk4
manpages += build/man/man1/gawk4.1


## heirloom-sh
sources += sources/heirloom-project
shells += build/bin/bsh build/bin/jsh
manpages += build/man/man1/bsh.1 build/man/man1/jsh.1

sources/heirloom-project/%:
	git clone https://github.com/eunuchs/heirloom-project.git sources/heirloom-project

build/heirloom-sh: sources/heirloom-project/heirloom/heirloom-sh
	rm -rf "$@"
	mkdir -p "$@"
	cd "$@" && ln -s "../../$<"/* ./
	make -C "$@"

build/bin/bsh: build/heirloom-sh
	cp "$</sh" "$@"
	scripts/add-trigger 'b#' 'sh -c ". /etc/profile";read -r;PS1= exec bsh -ic "\x24REPLY;echo o>/proc/sysrq-trigger"'      bourne

build/man/man1/bsh.1: build/heirloom-sh
	cp "$</sh.1" "$@"

build/bin/jsh: build/bin/bsh
	ln -s "$(<F)" "$@"
	scripts/add-trigger 'j#' 'sh -c ". /etc/profile";read -r;PS1= exec jsh -ic "\x24REPLY;echo o>/proc/sysrq-trigger"'     'bourne(w/job)'

build/man/man1/jsh.1: build/man/man1/bsh.1
	ln -s "$(<F)" "$@"

build/heirloom/%: build/heirloom
	mkdir -p "$@"
	$(MAKE) SHELL=/bin/sh -C "$(@D)" "$(@F)/Makefile"
	$(MAKE) SHELL=/bin/sh -C "$@"

build/heirloom: sources/heirloom-project/heirloom/heirloom
	rm -rf "$@"
	mkdir -p "$@"
	scripts/lndir "../../$<" "$@"

build/bin/oawk: build/heirloom/libcommon build/heirloom/libuxre build/heirloom/oawk build/heirloom/oawk/awk
	cp build/heirloom/oawk/awk "$@"

build/man/man1/oawk.1: build/heirloom/oawk/
	cp "$</awk.1" "$@"

sources/onetrueawk:
	git clone https://github.com/onetrueawk/awk "$@"

build/onetrueawk: sources/onetrueawk/
	rm -rf "$@"
	mkdir -p "$@"
	{ cd "$<" && git archive --format=tar HEAD; } | { cd "$@" && pax -r; }
	$(MAKE) -C "$@" 'YACC=bison -d -y'


build/bin/nawk: build/onetrueawk/
	cp "$</a.out" "$@"

build/man/man1/nawk.1: build/onetrueawk/
	cp "$</awk.1" "$@"

build/bin/adu:
	scripts/build-adu
build/bin/ex:
	scripts/build-ex-vi

build/locales:
	mkdir -p "$@"

build/locales/%: build/locales
	set -x; \
	x="$@" locale=$${x##*/} lang=$${locale%.*} enc=$${locale#"$$lang."}; \
	localedef --no-archive -c -i "$$lang" -f "$$enc" "$@"

sources/bash-builtins:
	git clone https://github.com/geirha/bash-builtins.git "$@"
build/bash-builtins: sources/bash-builtins build/bash-devel
	rm -rf "$@"
	mkdir -p "$@"
	{ cd "$<" && git archive --format=tar HEAD; } | { cd "$@" && pax -r; }
	$(MAKE) -C build/bash-devel prefix="../bash-headers" install-headers
	$(MAKE) -C build/bash-devel/examples/loadables prefix="../../../bash-headers" install-dev
	$(MAKE) -C "$@" prefix="../bash-headers"
	for file in "$@"/*; do \
	    [ -x "$$file" ] && [ -f "$$file" ] || continue; \
	    cp -v "$$file" build/loadables/; \
	done

initramfs: $(shells) $(awks) $(manpages) build/bin/adu build/bin/ex scripts/generate-initramfs $(locales) build/bash-builtins
	scripts/generate-initramfs

