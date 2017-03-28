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
DISTRIBS ?= $(patsubst $(DOCKER)/Dockerfile.%,%,$(wildcard $(DOCKER)/Dockerfile.*))

SKAWARE_VERSION = 1.19.1
SKAWARE_SOURCE = https://github.com/just-containers/skaware/releases/download/v$(SKAWARE_VERSION)
SKAWARE_ARCHIVES = $(patsubst %,$(CACHE)/%-linux-$(ARCH)-bin.tar.gz,execline-$(execline) s6-$(s6) s6-portable-utils-$(s6-portable-utils) s6-rc-$(s6-rc))
SKAWARE_MANIFEST = $(CACHE)/manifest-portable.txt

-include $(SKAWARE_MANIFEST)

SUEXEC_VERSION = 0.0.2
SUEXEC_MANIFEST_SOURCE = https://github.com/Adirelle/su-exec-musl/releases/download/v$(SUEXEC_VERSION)/manifest.txt
SUEXEC_MANIFEST = $(CACHE)/manifest.txt

-include $(SUEXEC_MANIFEST)

SUEXEC_SOURCE = https://github.com/Adirelle/su-exec-musl/releases/download/v$(SUEXEC_VERSION)/su-exec-$(su-exec)-x86_64-linux
SUEXEC_BIN = $(CACHE)/su-exec-$(su-exec)-x86_64-linux

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
IMAGE_TAGS = $(DISTRIBS)
IMAGES = $(addprefix $(BUILD)/image-,$(IMAGE_TAGS))
TEST_LABEL = test_image_for=s6rc-overlay
TEST_RESULTS = $(addprefix $(BUILD)/test-result-,$(IMAGE_TAGS))
PUSHES = $(addprefix $(BUILD)/pushed-,$(IMAGE_TAGS))

.PHONY: all clean clean-root distclean images test push

all: artifacts

$(SKAWARE_MANIFEST): | $(CACHE)
	$(CURL) -o $@ $(SKAWARE_SOURCE)/$(@F)

$(SUEXEC_MANIFEST): | $(CACHE)
	$(CURL) -o $@ $(SUEXEC_MANIFEST_SOURCE)

distclean: clean
	rm -rf $(CACHE)
	-docker images -q "adirelle/s6rc-overlay:*" | xargs -r docker rmi -f

clean:
	-chmod -R u+rwx $(ROOT)
	rm -rf $(BUILD) $(TESTS)/archive.tar.bz2 $(addprefix $(TESTS)/Dockerfile.,$(IMAGE_TAGS))
	-docker ps -q -f label=$(TEST_LABEL) | xargs -r docker rm -fv
	-docker images -q -f label=$(TEST_LABEL) | xargs -r docker rmi -f

artifacts: $(ARTIFACTS)

$(ARCHIVE): $(SUEXEC_BIN) $(addprefix $(SRC)/,$(SRC_FILES)) $(SKAWARE_ARCHIVES) | $(BUILD)
	@tools/printbanner "Building artifact $@"
	tools/mkartifact $@ $(ROOT) $(SRC) $(SUEXEC_BIN) $(SKAWARE_ARCHIVES)

$(SUEXEC_BIN): | $(CACHE)
	$(CURL) -o $@ $(SUEXEC_SOURCE)

$(CHECKSUM): $(ARCHIVE)
	cd $(<D) && sha512sum $(<F) >$(@F)

$(MANIFEST): $(SKAWARE_MANIFEST) $(SUEXEC_MANIFEST) $(ARCHIVE) | $(BUILD)
	echo s6rc-overlay=$(TAG) >$@
	cat $(SKAWARE_MANIFEST) >>$@
	cat $(SUEXEC_MANIFEST) >>$@

$(CACHE) $(BUILD):
	mkdir -p $@

$(SKAWARE_ARCHIVES): $(CACHE)/%: | $(CACHE)
	$(CURL) -o $@ $(SKAWARE_SOURCE)/$*

images: $(IMAGES)

$(IMAGES): $(BUILD)/image-%: $(DOCKER)/Dockerfile.% $(DOCKER)/archive.tar.bz2
	@tools/printbanner "Building image based on $*"
	docker build --pull -t $(IMAGE_SLUG):$* -f $< $(<D)
	touch $@

$(DOCKER)/archive.tar.bz2: $(ARCHIVE)
	cp -a $< $@

test: $(TEST_RESULTS)

$(TEST_RESULTS): $(BUILD)/test-result-%: $(BUILD)/image-% $(shell find $(TESTS) -type f)
	@tools/printbanner "Running tests for $*"
	tests/run-all $(IMAGE_SLUG):$* $(TEST_LABEL)
	touch $@

push: $(PUSHES) $(BUILD)/pushed-latest

$(BUILD)/pushed-latest: $(BUILD)/image-alpine | $(HOME)/.docker/config.json
	@tools/printbanner "Pushing latest and $(TAG)"
	docker tag $(IMAGE_SLUG):alpine $(IMAGE_SLUG):latest
	docker push $(IMAGE_SLUG):latest
	docker tag $(IMAGE_SLUG):alpine $(IMAGE_SLUG):$(TAG)
	docker push $(IMAGE_SLUG):$(TAG)

$(PUSHES): $(BUILD)/pushed-%: $(BUILD)/image-% | $(HOME)/.docker/config.json
	@tools/printbanner "Pushing $* and $(TAG)-$*"
	docker push $(IMAGE_SLUG):$*
	docker tag $(IMAGE_SLUG):$* $(IMAGE_SLUG):$(TAG)-$*
	docker push $(IMAGE_SLUG):$(TAG)-$*

$(HOME)/.docker/config.json:
	mkdir -p $(@D)
	@echo '{"auths":{"https://index.docker.io/v1/":{"auth":"'$(DOCKER_AUTH_TOKEN)'"}}}' >$@
