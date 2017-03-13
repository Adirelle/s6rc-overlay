#!/usr/bin/make -f
# vim: noexpandtab ts=4

BUILD = build
CACHE = cache
OVERLAY = overlay
DOCKER = docker/base
TESTS = docker/tests
ROOT = $(BUILD)/$(ARCH)

include $(CACHE)/manifest.txt

ARCH ?= amd64
TAG ?= master
REPO_OWNER ?= Adirelle
REPO_SLUG ?= Adirelle/s6rc-overlay

SKAWARE_VERSION = 1.19.1
SKAWARE_SOURCE = https://github.com/just-containers/skaware/releases/download/v$(SKAWARE_VERSION)
SKAWARE_ARCHIVES = $(patsubst %,$(CACHE)/%-linux-$(ARCH)-bin.tar.gz,execline-$(execline) s6-$(s6) s6-portable-utils-$(s6-portable-utils) s6-rc-$(s6-rc))

GOSU_VERSION = 1.10

CURL = curl --silent --show-error --location --remote-time
ifdef $(GITHUB_OAUTH_TOKEN)
CURL += -u$(REPO_OWNER):$(GITHUB_OAUTH_TOKEN)
endif

OVERLAY_FILES = $(shell find $(OVERLAY) -type f -printf "%P\n")

ARTIFACT = $(BUILD)/s6rc-overlay-$(TAG)-$(ARCH).tar.bz2

IMAGE_SLUG = $(shell echo $(REPO_SLUG) | tr '[:upper:]' '[:lower:]')
IMAGE_TAGS = $(patsubst $(DOCKER)/Dockerfile.%,%,$(wildcard $(DOCKER)/Dockerfile.*))
IMAGES = $(addprefix $(BUILD)/image-,$(IMAGE_TAGS))
TEST_RESULTS = $(addprefix $(BUILD)/test-result-,$(IMAGE_TAGS))

.PHONY: all clean distclean images test

all: artifacts images test

$(CACHE)/manifest.txt: | $(CACHE)
	$(CURL) -o $@ $(SKAWARE_SOURCE)/manifest.txt

distclean: clean
	rm -rf $(CACHE)

clean:
	rm -rf $(BUILD) $(TESTS)/archive.tar.bz2 $(addprefix $(TESTS)/Dockerfile.,$(IMAGE_TAGS))

artifacts: $(ARTIFACT) $(ARTIFACT).sha512

$(ARTIFACT): $(CACHE)/gosu $(addprefix $(OVERLAY)/,$(OVERLAY_FILES)) $(SKAWARE_ARCHIVES) | $(BUILD)
	rm -rf $(ROOT)
	cp -a $(OVERLAY) $(ROOT)
	cp $(CACHE)/gosu $(ROOT)/bin/gosu && chmod 4555 $(ROOT)/bin/gosu
	for A in $(SKAWARE_ARCHIVES); do tar xaf $$A -C $(ROOT); done
	tar caf $@ -C $(ROOT) --owner=0 --group=0 .

$(CACHE)/gosu: | $(CACHE)
	$(CURL) -o $@ https://github.com/tianon/gosu/releases/download/$(GOSU_VERSION)/gosu-$(ARCH)

$(CACHE) $(BUILD):
	mkdir -p $@

$(SKAWARE_ARCHIVES): $(CACHE)/%: | $(CACHE)
	$(CURL) -o $@ $(SKAWARE_SOURCE)/$*

$(ARTIFACT).sha512: $(ARTIFACT)
	cd $(<D) && sha512sum $(<F) >../$@

images: $(IMAGES)

$(IMAGES): $(BUILD)/image-%: $(DOCKER)/Dockerfile.% $(DOCKER)/archive.tar.bz2
	docker build -t $(IMAGE_SLUG):$* -f $< $(<D)
	touch $@

$(DOCKER)/archive.tar.bz2: $(ARTIFACT)
	cp -a $< $@

test: $(TEST_RESULTS)

$(TEST_RESULTS): $(BUILD)/test-result-%: $(TESTS)/Dockerfile.% $(BUILD)/image-% $(shell find $(TESTS) -type f)
	docker build -t test-$* -f $< $(<D)
	docker run --rm test-$*
	touch $@

$(TESTS)/Dockerfile.%: $(TESTS)/suffix.Dockerfile
	echo "FROM $(IMAGE_SLUG):$*" | cat - $< >$@

