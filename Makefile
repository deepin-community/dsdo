LANG=da_DK.ISO8859-1

sprog=dansk
sprog_en=Danish
sprog_en_lower_case=danish
language_code=da
country_code=DK

lang=da
version=1.6.36

#-----------------------------------------------------------------------------
# Build rules:

all: words aspell ispell

words: words-$(language_code)

words-$(language_code): words-$(language_code).sq unsq
	./unsq < words-$(language_code).sq > words-$(language_code)

aspell: words
	$(MAKE) -C aspell all

ispell: words
	$(MAKE) -C ispell all

#-----------------------------------------------------------------------------
# Installation rules:

install: install-words install-aspell install-ispell

install-words: words

install-aspell: aspell
	$(MAKE) -C aspell install

install-ispell: ispell
	$(MAKE) -C ispell install

#-----------------------------------------------------------------------------
# Cleanup rules:

clean:
	rm -f words-$(language_code)
	$(MAKE) -C aspell clean
	$(MAKE) -C ispell clean

