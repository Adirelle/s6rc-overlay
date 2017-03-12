#!/usr/bin/make -f
# vim: noexpandtab ts=4

ARCH ?= amd64
TAG ?= master

SKAWARE_VERSION = 1.19.1
SKAWARE_SOURCE = https://github.com/just-containers/skaware/releases/download/v$(SKAWARE_VERSION)
SKAWARE_ARCHIVES = $(patsubst %,$(CACHE)/%-linux-$(ARCH)-bin.tar.gz,execline-$(EXECLINE) s6-$(S6) s6-portable-utils-$(S6-PORTABLE-UTILS) s6-rc-$(S6-RC))

GOSU_VERSION = 1.10

BUILD = build
CACHE = cache
OVERLAY = overlay
ROOT = $(BUILD)/$(ARCH)

include $(CACHE)/manifest.mak

ARTIFACT = $(BUILD)/s6rc-overlay-$(TAG)-$(ARCH).tar.bz2

CURL = curl --silent --show-error --location --remote-time
ifdef $(GITHUB_OAUTH_TOKEN)
CURL += -uAdirelle:$(GITHUB_OAUTH_TOKEN)
endif

OVERLAY_FILES = $(shell find $(OVERLAY) -type f -printf "%P\n")

.PHONY: all clean distclean

all: $(ARTIFACT) $(ARTIFACT).sha512

clean:
	rm -rf $(BUILD)

distclean: clean
	rm -rf $(CACHE)

$(ARTIFACT).sha512: $(ARTIFACT)
	cd $(<D) && sha512sum $(<F) >../$@

$(ARTIFACT): $(CACHE)/gosu $(addprefix $(OVERLAY)/,$(OVERLAY_FILES)) $(SKAWARE_TARS) | $(BUILD)
	rm -rf $(ROOT)
	cp -a $(OVERLAY) $(ROOT)
	cp $(CACHE)/gosu $(ROOT)/bin/gosu && chmod 4555 $(ROOT)/bin/gosu
	for A in $(SKAWARE_ARCHIVES); do tar xaf $$A -C $(ROOT); done
	tar caf $@ -C $(ROOT) --owner=0 --group=0 .

$(CACHE)/manifest.mak: $(CACHE)/manifest.txt
	awk '{print toupper($$0)}' $< > $@

$(CACHE)/manifest.txt: | $(CACHE)
	$(CURL) -o $@ $(SKAWARE_SOURCE)/manifest.txt

$(SKAWARE_ARCHIVES): $(CACHE)/%: | $(CACHE)
	$(CURL) -o $@ $(SKAWARE_SOURCE)/$*

$(CACHE)/gosu: | $(CACHE)
	$(CURL) -o $@ https://github.com/tianon/gosu/releases/download/$(GOSU_VERSION)/gosu-$(ARCH)

$(CACHE) $(BUILD):
	mkdir -p $@
