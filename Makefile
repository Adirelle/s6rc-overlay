#!/usr/bin/make -f
# vim: noexpandtab ts=4

BUILD = build
CACHE = .cache
SRC = src
DOCKER = docker
TESTS = tests
ROOT = $(BUILD)/$(ARCH)

ARCH ?= amd64
TAG ?= master
REPO_OWNER ?= Adirelle
REPO_SLUG ?= Adirelle/s6rc-overlay

SKAWARE_VERSION = 1.19.1
SKAWARE_SOURCE = https://github.com/just-containers/skaware/releases/download/v$(SKAWARE_VERSION)
SKAWARE_ARCHIVES = $(patsubst %,$(CACHE)/%-linux-$(ARCH)-bin.tar.gz,execline-$(execline) s6-$(s6) s6-portable-utils-$(s6-portable-utils) s6-rc-$(s6-rc))
SKAWARE_MANIFEST = $(CACHE)/manifest-portable.txt

-include $(SKAWARE_MANIFEST)

GOSU_VERSION = 1.10

CURL = curl --silent --show-error --location --remote-time
ifdef $(GITHUB_OAUTH_TOKEN)
CURL += -u$(REPO_OWNER):$(GITHUB_OAUTH_TOKEN)
endif

SRC_FILES = $(shell find $(SRC) -type f -printf "%P\n")

ARCHIVE = $(BUILD)/s6rc-overlay-$(TAG)-$(ARCH).tar.bz2
CHECKSUM = $(ARCHIVE).sha512
MANIFEST = $(BUILD)/manifest.txt
ARTIFACTS = $(ARCHIVE) $(CHECKSUM) $(MANIFEST)

IMAGE_SLUG = $(shell echo $(REPO_SLUG) | tr '[:upper:]' '[:lower:]')
IMAGE_TAGS = $(patsubst $(DOCKER)/Dockerfile.%,%,$(wildcard $(DOCKER)/Dockerfile.*))
IMAGES = $(addprefix $(BUILD)/image-,$(IMAGE_TAGS))
TEST_RESULTS = $(addprefix $(BUILD)/test-result-,$(IMAGE_TAGS))
PUSHES = $(addprefix $(BUILD)/pushed-,$(IMAGE_TAGS))

.PHONY: all clean clean-root distclean images test push

all: artifacts

$(SKAWARE_MANIFEST): | $(CACHE)
	$(CURL) -o $@ $(SKAWARE_SOURCE)/$(@F)

distclean: clean
	rm -rf $(CACHE)

clean:
	-chmod -R u+rwx $(ROOT)
	rm -rf $(BUILD) $(TESTS)/archive.tar.bz2 $(addprefix $(TESTS)/Dockerfile.,$(IMAGE_TAGS))

artifacts: $(ARTIFACTS)

$(ARCHIVE): $(CACHE)/gosu $(addprefix $(SRC)/,$(SRC_FILES)) $(SKAWARE_ARCHIVES) | $(BUILD)
	tools/mkartifact $@ $(ROOT) $(CACHE) $(SRC) $(SKAWARE_ARCHIVES)

$(CHECKSUM): $(ARCHIVE)
	cd $(<D) && sha512sum $(<F) >$(@F)

$(MANIFEST): $(SKAWARE_MANIFEST) $(CACHE)/gosu $(ARCHIVE) | $(BUILD)
	echo s6rc-overlay=$(TAG) >$@
	echo gosu=$(GOSU_VERSION) >>$@
	cat $(SKAWARE_MANIFEST) >>$@

$(CACHE)/gosu: | $(CACHE)
	$(CURL) -o $@ https://github.com/tianon/gosu/releases/download/$(GOSU_VERSION)/gosu-$(ARCH)

$(CACHE) $(BUILD):
	mkdir -p $@

$(SKAWARE_ARCHIVES): $(CACHE)/%: | $(CACHE)
	$(CURL) -o $@ $(SKAWARE_SOURCE)/$*

images: $(IMAGES)

$(IMAGES): $(BUILD)/image-%: $(DOCKER)/Dockerfile.% $(DOCKER)/archive.tar.bz2
	docker build --pull -t $(IMAGE_SLUG):$* -f $< $(<D)
	touch $@

$(DOCKER)/archive.tar.bz2: $(ARCHIVE)
	cp -a $< $@

test: $(TEST_RESULTS)

$(TEST_RESULTS): $(BUILD)/test-result-%: $(TESTS)/Dockerfile.% $(BUILD)/image-% $(shell find $(TESTS) -type f)
	chmod -R a+rX $(TESTS)
	docker build -t test-$* -f $< $(<D)
	docker run --rm test-$*
	touch $@

$(TESTS)/Dockerfile.%: $(TESTS)/template.Dockerfile
	echo "FROM $(IMAGE_SLUG):$*" | cat - $< >$@

push: $(PUSHES) $(BUILD)/pushed-latest

$(BUILD)/pushed-latest: $(BUILD)/image-alpine | $(HOME)/.docker/config.json
	docker tag $(IMAGE_SLUG):alpine $(IMAGE_SLUG):latest
	docker push $(IMAGE_SLUG):latest
	docker tag $(IMAGE_SLUG):alpine $(IMAGE_SLUG):$(TAG)
	docker push $(IMAGE_SLUG):$(TAG)

$(PUSHES): $(BUILD)/pushed-%: $(BUILD)/image-% | $(HOME)/.docker/config.json
	docker push $(IMAGE_SLUG):$*
	docker tag $(IMAGE_SLUG):$* $(IMAGE_SLUG):$(TAG)-$*
	docker push $(IMAGE_SLUG):$(TAG)-$*

$(HOME)/.docker/config.json:
	mkdir -p $(@D)
	@echo '{"auths":{"https://index.docker.io/v1/":{"auth":"'$(DOCKER_AUTH_TOKEN)'"}}}' >$@
