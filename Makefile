#!/usr/bin/make -f

ARCH != uname -m
VERSION = $(s6-rc_version)

PACKAGES = skalibs execline s6 s6-portable-utils s6-rc

ARCHIVE = $(OUTPUT)/s6rc-overlay-$(VERSION)-$(ARCH).tar.bz2

OUTPUT := $(abspath build)
ROOTFS := $(OUTPUT)/rootfs

CONFIGURE_COMMON = --enable-static --disable-shared

CONFIGURE_COMMON_BIN = $(CONFIGURE_COMMON)
CONFIGURE_COMMON_BIN += --with-sysdeps=$(ROOTFS)/usr/lib/skalibs/sysdeps
CONFIGURE_COMMON_BIN += --with-include=$(ROOTFS)/usr/include
CONFIGURE_COMMON_BIN += --with-lib=$(ROOTFS)/usr/lib/skalibs
CONFIGURE_COMMON_BIN += --with-lib=$(ROOTFS)/usr/lib/execline
CONFIGURE_COMMON_BIN += --with-lib=$(ROOTFS)/usr/lib/s6
CONFIGURE_COMMON_BIN += --enable-allstatic --enable-static-libc --enable-absolute-paths 

skalibs_version = 2.4.0.2
skalibs_deps =
skalibs_configure = $(CONFIGURE_COMMON)
skalibs_target = skalibs/libskarnet.a.xyzzy
skalibs_package = $(ROOTFS)/usr/lib/skalibs/libskarnet.a

execline_version = 2.2.0.0
execline_deps = $(skalibs_package)
execline_configure = $(CONFIGURE_COMMON_BIN)
execline_target = execline/libexecline.a.xyzzy
execline_package = $(ROOTFS)/usr/lib/execline/libexecline.a

s6_version = 2.4.0.0
s6_deps = $(execline_package)
s6_configure = $(CONFIGURE_COMMON_BIN)
s6_target = s6/libs6.a.xyzzy
s6_package = $(ROOTFS)/usr/lib/s6/libs6.a

s6-portable-utils_version = 2.1.0.0
s6-portable-utils_deps = $(skalibs_package)
s6-portable-utils_configure = $(CONFIGURE_COMMON_BIN)
s6-portable-utils_target = s6-portable-utils/libs6-portable-utils.a.xyzzy
s6-portable-utils_package = $(ROOTFS)/usr/lib/libs6-portable-utils/libs6-portable-utils.a

s6-rc_version = 0.1.0.0
s6-rc_deps = $(skalibs_package) $(execline_package) $(s6_package)
s6-rc_configure = $(CONFIGURE_COMMON_BIN)
s6-rc_target = s6-rc/libs6rc.a.xyzzy
s6-rc_package = $(ROOTFS)/usr/lib/s6rc/libs6rc.a

.PHONY: all clean distclean packages overlay

all: $(ARCHIVE) $(ARCHIVE).sha512

$(ARCHIVE): $(ROOTFS)/docker-init $(foreach PKG,$(PACKAGES),$($(PKG)_package))
	cd $(ROOTFS) && tar caf $(ARCHIVE) --exclude=usr/include --exclude=usr/lib --owner=root --group=root --no-acls *

$(ARCHIVE).sha512: $(ARCHIVE)
	cd $(<D) && sha512sum $(<F) > $(@F)

overlay: $(ROOTFS)/docker-init | packages

$(ROOTFS)/docker-init: overlay/docker-init | $(ROOTFS)
	cp -r overlay/* $(ROOTFS)

$(ROOTFS):
	mkdir -p $@
	
packages: $(foreach PKG,$(PACKAGES),$($(PKG)_package))

define PACKAGE_TEMPLATE =
$(1)/config.mak: $(1)/configure $($(1)_deps)
	cd $(1); ./configure $($(1)_configure)

$($(1)_target): $(1)/config.mak
	$(MAKE) -C $(1) all

$($(1)_package): $($(1)_target) | $(ROOTFS)
	$(MAKE) -C $(1) install DESTDIR=$(ROOTFS)

endef

$(foreach PKG,$(PACKAGES),$(eval $(call PACKAGE_TEMPLATE,$(PKG))))

clean:
	for PKG in $(PACKAGES); do $(MAKE) -C $$PKG clean; done
	rm -rf $(ROOTFS)

distclean: clean
	for PKG in $(PACKAGES); do $(MAKE) -C $$PKG distclean; done

# vim: noexpandtab ts=4
