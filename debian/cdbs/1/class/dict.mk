# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2004-2007 Jonas Smedegaard <dr@jones.dk>
# Description: Install various dictionaries
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# TODO: Support overriding settings per package (needed for german and
#   swiss dictionaries from same source).

# TODO: Support arch:all ispell packages: if compelete wordlist is
#   provided(/detected) instead of hash, install it instead, depend on
#   ispell and run buildhash in postinst.

# TODO: Check Depends (in addition to Provides)

# TODO: Check more strictly (search within same '^Package:')

_cdbs_scripts_path ?= /usr/lib/cdbs
_cdbs_rules_path ?= /usr/share/cdbs/1/rules
_cdbs_class_path ?= /usr/share/cdbs/1/class

ifndef _cdbs_class_dict
_cdbs_class_dict := 1

include $(_cdbs_rules_path)/buildcore.mk$(_cdbs_makefile_suffix)

DEB_WORDLIST_PACKAGES := $(strip $(filter w%,$(DEB_ALL_PACKAGES)))
DEB_ISPELL_PACKAGES := $(strip $(filter i%,$(DEB_ALL_PACKAGES)))
DEB_ASPELL_PACKAGES := $(strip $(filter aspell-%,$(DEB_ALL_PACKAGES)))
DEB_MYSPELL_PACKAGES := $(strip $(filter myspell-%,$(DEB_ALL_PACKAGES)))

ifneq ($(DEB_ASPELL_PACKAGES),)
CDBS_BUILD_DEPENDS := $(CDBS_BUILD_DEPENDS), aspell (>= 0.60.3-2), dictionaries-common-dev (>= 1.10.5)
else
CDBS_BUILD_DEPENDS := $(CDBS_BUILD_DEPENDS), dictionaries-common-dev (>= 1.10.5)
endif

# Set these!
#DEB_DICT_LANG = 
#DEB_DICT_NATIVELANG = 
#DEB_DICT_LANGCODE = 
#DEB_DICT_COUNTRYCODE = 

# Override these if needed
DEB_WORDLIST_DIR = .
DEB_ISPELL_DIR = ispell
DEB_ASPELL_DIR = aspell
DEB_MYSPELL_DIR = myspell
DEB_WORDLIST_FILE = $(DEB_WORDLIST_DIR)/words-$(DEB_DICT_LANGCODE)
DEB_ISPELL_AFFFILE = $(DEB_ISPELL_DIR)/$(DEB_DICT_NATIVELANG).aff
DEB_ISPELL_HASHFILE = $(DEB_ISPELL_DIR)/$(DEB_DICT_NATIVELANG).hash
DEB_ASPELL_DATFILE = $(DEB_ASPELL_DIR)/$(DEB_DICT_LANGCODE).dat
DEB_ASPELL_PHONETDATFILE = $(DEB_ASPELL_DIR)/$(DEB_DICT_LANGCODE)_phonet.dat
DEB_ASPELL_MASTERFILE = $(DEB_ASPELL_DIR)/$(DEB_DICT_LANGCODE).rws
DEB_MYSPELL_DICFILE = $(DEB_MYSPELL_DIR)/$(DEB_DICT_LANGCODE)_$(DEB_DICT_COUNTRYCODE).dic
DEB_MYSPELL_AFFFILE = $(DEB_MYSPELL_DIR)/$(DEB_DICT_LANGCODE)_$(DEB_DICT_COUNTRYCODE).aff
DEB_DICT_LANGALIASES = $(DEB_DICT_LANG) $(DEB_DICT_NATIVELANG)

### No servicable parts below this line

DEB_PHONY_RULES += dict-sanity-check

$(patsubst %,install/%,$(DEB_WORDLIST_PACKAGES)):: dict-sanity-check
dict-sanity-check:
	@if test -z "$(DEB_DICT_LANG)" || test -z "$(DEB_DICT_NATIVELANG)" || test -z "$(DEB_DICT_LANGCODE)" || test -z "$(DEB_DICT_COUNTRYCODE)"; then \
		echo 'You must define all of DEB_DICT_LANG DEB_DICT_NATIVELANG DEB_DICT_LANGCODE DEB_DICT_COUNTRYCODE!'; \
		exit 1; \
	fi

$(patsubst %,install/%,$(DEB_WORDLIST_PACKAGES)):: install/% :
	echo "Checking that wordlist package provides wordlist..."
	egrep -q 'Provides:.* wordlist' debian/control && echo "OK"
	mkdir -p "debian/$(cdbs_curpkg)/usr/share/dict"
	install -o root -g root -m 644 "$(if $(DEB_WORDLIST_FILE_$(cdbs_curpkg)),$(DEB_WORDLIST_FILE_$(cdbs_curpkg)),$(DEB_WORDLIST_FILE))" "debian/$(cdbs_curpkg)/usr/share/dict/$(DEB_DICT_LANG)"
	for alias in $(filter-out $(DEB_DICT_LANG),$(DEB_DICT_LANGALIASES)); do \
		ln -fs "$(DEB_DICT_LANG)" "debian/$(cdbs_curpkg)/usr/share/dict/$$alias"; \
	done

	installdeb-wordlist -p$(cdbs_curpkg)

$(patsubst %,install/%,$(DEB_ISPELL_PACKAGES)) :: install/% :
	echo "Checking that ispell package provides ispell-dictionary..."
	egrep -q 'Provides:.* ispell-dictionary' debian/control && echo "OK"
	mkdir -p "debian/$(cdbs_curpkg)/usr/lib/ispell"
	install -o root -g root -m 644 "$(if $(DEB_ISPELL_AFFFILE_$(cdbs_curpkg)),$(DEB_ISPELL_AFFFILE_$(cdbs_curpkg)),$(DEB_ISPELL_AFFFILE))" "debian/$(cdbs_curpkg)/usr/lib/ispell/$(DEB_DICT_LANG).aff"
	install -o root -g root -m 644 "$(if $(DEB_ISPELL_HASHFILE_$(cdbs_curpkg)),$(DEB_ISPELL_HASHFILE_$(cdbs_curpkg)),$(DEB_ISPELL_HASHFILE))" "debian/$(cdbs_curpkg)/usr/lib/ispell/$(DEB_DICT_LANG).hash"
	for alias in $(filter-out $(DEB_DICT_LANG),$(DEB_DICT_LANGALIASES)); do \
		ln -fs "$(DEB_DICT_LANG).aff" "debian/$(cdbs_curpkg)/usr/lib/ispell/$$alias.aff"; \
		ln -fs "$(DEB_DICT_LANG).hash" "debian/$(cdbs_curpkg)/usr/lib/ispell/$$alias.hash"; \
	done

	installdeb-ispell -p$(cdbs_curpkg)

$(patsubst %,install/%,$(DEB_ASPELL_PACKAGES)) :: install/% :
	### Temporarily disable aspell6a-dictionary check. Trying to build arch:all with aspell-autobuildhash.
        ### and for is aspell-dictionary what is provided.
	# echo "Checking that aspell package provides aspell6a-dictionary..."
	# egrep -q 'Provides:.* aspell6a-dictionary' debian/control && echo "OK"
	mkdir -p "debian/$(cdbs_curpkg)/usr/lib/aspell"
	echo "add $(DEB_DICT_LANGCODE).rws" > "debian/$(cdbs_curpkg)/usr/lib/aspell/$(DEB_DICT_LANGCODE).multi"
	chmod 644 "debian/$(cdbs_curpkg)/usr/lib/aspell/$(DEB_DICT_LANGCODE).multi"
	for alias in $(DEB_DICT_LANGALIASES); do \
		echo "add $(DEB_DICT_LANGCODE).multi" > "debian/$(cdbs_curpkg)/usr/lib/aspell/$$alias.alias"; \
		chmod 644 "debian/$(cdbs_curpkg)/usr/lib/aspell/$$alias.alias"; \
	done
	install -o root -g root -m 644 "$(if $(DEB_ASPELL_DATFILE_$(cdbs_curpkg)),$(DEB_ASPELL_DATFILE_$(cdbs_curpkg)),$(DEB_ASPELL_DATFILE))" "debian/$(cdbs_curpkg)/usr/lib/aspell/$(DEB_DICT_LANGCODE).dat"
	install -o root -g root -m 644 "$(if $(DEB_ASPELL_PHONETDATFILE_$(cdbs_curpkg)),$(DEB_ASPELL_PHONETDATFILE_$(cdbs_curpkg)),$(DEB_ASPELL_PHONETDATFILE))" "debian/$(cdbs_curpkg)/usr/lib/aspell/$(DEB_DICT_LANGCODE)_phonet.dat"
	install -o root -g root -m 644 "$(if $(DEB_ASPELL_MASTERFILE_$(cdbs_curpkg)),$(DEB_ASPELL_MASTERFILE_$(cdbs_curpkg)),$(DEB_ASPELL_MASTERFILE))" "debian/$(cdbs_curpkg)/usr/lib/aspell/$(DEB_DICT_LANGCODE).rws"
# FIXME: Is this needed?
#	installdeb-aspell -p$(cdbs_curpkg)

$(patsubst %,install/%,$(DEB_MYSPELL_PACKAGES)) :: install/% :
	echo "Checking that myspell package provides myspell-dictionary..."
	egrep -q 'Provides:.* myspell-dictionary' debian/control && echo "OK"
	mkdir -p "debian/$(cdbs_curpkg)/usr/share/hunspell"
	install -o root -g root -m 644 "$(if $(DEB_MYSPELL_DICFILE_$(cdbs_curpkg)),$(DEB_MYSPELL_DICFILE_$(cdbs_curpkg)),$(DEB_MYSPELL_DICFILE))" "debian/$(cdbs_curpkg)/usr/share/hunspell/$(DEB_DICT_LANGCODE)_$(DEB_DICT_COUNTRYCODE).dic"
	install -o root -g root -m 644 "$(if $(DEB_MYSPELL_AFFFILE_$(cdbs_curpkg)),$(DEB_MYSPELL_AFFFILE_$(cdbs_curpkg)),$(DEB_MYSPELL_AFFFILE))" "debian/$(cdbs_curpkg)/usr/share/hunspell/$(DEB_DICT_LANGCODE)_$(DEB_DICT_COUNTRYCODE).aff"

	installdeb-myspell -p$(cdbs_curpkg)

endif
