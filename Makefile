#!/usr/bin/make -f

PACKAGES = skalibs execline s6 s6-portable-utils s6-rc

OUTPUT = build

PACKAGE_DIR = $(OUTPUT)/package
ABS_PACKAGE_DIR = $(abspath $(PACKAGE_DIR))

INCLUDES = $(wildcard $(ABS_PACKAGE_DIR)/*/*/include)
LIBS = $(wildcard $(ABS_PACKAGE_DIR)/*/*/library)
SYSDEPS = $(wildcard $(ABS_PACKAGE_DIR)/*/*/sysdeps)

CONFIGURE_COMMON = --enable-static --disable-shared --enable-slashpackage=$(abspath $(PACKAGE_DIR)/..)

CONFIGURE_DIRS = $(addprefix --with-include=,$(INCLUDES)) $(addprefix --with-sysdeps=,$(SYSDEPS)) $(addprefix --with-lib=,$(LIBS))
CONFIGURE_COMMON_BIN = $(CONFIGURE_COMMON) $(CONFIGURE_DIRS) --enable-allstatic --enable-static-libc --enable-absolute-paths 

skalibs_version = 2.4.0.2
skalibs_deps =
skalibs_configure = $(CONFIGURE_COMMON)
skalibs_target = skalibs/libskarnet.a.xyzzy
skalibs_package = $(PACKAGE_DIR)/prog/skalibs-$(skalibs_version)

execline_version = 2.2.0.0
execline_deps = $(skalibs_package)
execline_configure = $(CONFIGURE_COMMON_BIN)
execline_target = execline/libexecline.a.xyzzy
execline_package = $(PACKAGE_DIR)/admin/execline-$(execline_version)

s6_version = 2.4.0.0
s6_deps = $(execline_package)
s6_configure = $(CONFIGURE_COMMON_BIN)
s6_target = s6/libs6.a.xyzzy
s6_package = $(PACKAGE_DIR)/admin/s6-$(s6_version)

s6-portable-utils_version = 2.1.0.0
s6-portable-utils_deps = $(skalibs_package)
s6-portable-utils_configure = $(CONFIGURE_COMMON_BIN)
s6-portable-utils_target = s6-portable-utils/libs6-portable-utils.a.xyzzy
s6-portable-utils_package = $(PACKAGE_DIR)/admin/s6-portable-utils-$(s6-portable-utils_version)

s6-rc_version = 0.1.0.0
s6-rc_deps = $(skalibs_package) $(execline_package) $(s6_package)
s6-rc_configure = $(CONFIGURE_COMMON_BIN)
s6-rc_target = s6-rc/libs6rc.a.xyzzy
s6-rc_package = $(PACKAGE_DIR)/admin/s6-rc-$(s6-rc_version)

.PHONY: all clean distclean packages overlay

all: packages overlay
	
packages: $(foreach PKG,$(PACKAGES),$($(PKG)_package))

define PACKAGE_TEMPLATE =
$(1)/config.mak: $(1)/configure $($(1)_deps)
	cd $(1); ./configure $($(1)_configure)

$($(1)_target): $(1)/config.mak
	$(MAKE) -C $(1) all

$($(1)_package): $($(1)_target)
	$(MAKE) -C $(1) install

endef

$(foreach PKG,$(PACKAGES),$(eval $(call PACKAGE_TEMPLATE,$(PKG))))

BINARIES=$(foreach BIN,$(wildcard $(PACKAGE_DIR)/*/*/command/*),$(basename $(BIN)))

tests:
	echo $(wildcard $(PACKAGE_DIR)/*/*/command/*)

overlay: $(OUTPUT)/rootfs/docker-init $(addprefix $(OUTPUT)/rootfs/bin/,$(BINARIES))

$(OUTPUT)/rootfs/docker-init:
	cp -r overlay $(OUTPUT)/rootfs 

clean:
	for PKG in $(PACKAGES); do $(MAKE) -C $$PKG clean; done
	rm -rf $(OUTPUT)

distclean: clean
	for PKG in $(PACKAGES); do $(MAKE) -C $$PKG distclean; done
