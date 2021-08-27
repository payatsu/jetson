module ?= mymodule
obj-m := $(module).o

ifeq ($(KERNELRELEASE),)
export ARCH          ?= arm64
export CROSS_COMPILE ?= $(shell which ccache > /dev/null && echo ccache) aarch64-linux-gnu-
export LOCALVERSION  ?= -tegra

builddir := build
l4t_major ?= 32
l4t_minor ?= 5.1
l4tdir    ?= l4t/r$(l4t_major).$(l4t_minor)
l4ttop    ?= $(l4tdir)/Linux_for_Tegra
kerneldir ?= $(abspath $(l4ttop)/source/public/kernel/kernel-4.9)
cross_toolchain := l4t-gcc-7-3-1-toolchain-64-bit.tar.xz
PATH := $(abspath toolchain/bin):$(PATH)

V ?= 0
ifeq ($(V),1)
Q =
else
Q = @
endif

all: $(module).ko

ifeq ($(realpath /etc/nv_tegra_release),)
export INSTALL_PATH     ?= $(abspath rootfs)/boot
export INSTALL_MOD_PATH ?= $(abspath rootfs)
export INSTALL_HDR_PATH ?= $(abspath rootfs)/usr

install: $(INSTALL_PATH)

$(INSTALL_PATH):
	mkdir -p $@

dtbs_install: $(INSTALL_PATH)
	cp -Tr $(builddir)/arch/$(ARCH)/boot/dts $(INSTALL_PATH)/dtb
	$(RM) -r $(INSTALL_PATH)/dtb/_ddot_

release:
	find $(INSTALL_MOD_PATH) -type l -a \( -name source -o -name build \) -exec rm -fv {} +
	find $(INSTALL_HDR_PATH) -type f -a \( -name .install -o -name ..install.cmd \) -exec rm -fv {} +
	tar cJvf $(module)-`grep -oPe '(?<=^MODULE_VERSION\(")[0-9.]+(?="\);$$)' $(module).c`.$(ARCH).tar.xz \
		--owner root --group root -C rootfs boot lib usr
endif

.PHONY: all mrproper tegra_defconfig olddefconfig diffconfig verifyconfig \
	modules_prepare dtbs Image modules \
	install modules_install headers_install dtbs_install release \
	tags clean distclean setup l4t l4t-src toolchain

$(module).ko: $(builddir)/include/config/auto.conf $(patsubst %.o,%.c,$(obj-m))
	$(MAKE) -C $(kerneldir) V=1 W=1 O=$(abspath $(builddir)) M=`pwd` modules

$(builddir)/include/config/auto.conf: $(builddir)/.config
	$(MAKE) modules_prepare

diffconfig: $(builddir)/.config
	$(Q)python $(kerneldir)/scripts/diffconfig $<.orig $<

verifyconfig: $(builddir)/.config
	$(Q)cd $(dir $<); PATH=$(kerneldir)/scripts:$${PATH}; $(abspath .)/scripts/modifyconfig --verify

$(builddir)/.config: scripts/modifyconfig
	$(MAKE) tegra_defconfig
	[ -f $@.orig ] || cp $@ $@.orig
	cd $(dir $@); PATH=$(kerneldir)/scripts:$${PATH}; $(abspath $<)
	$(MAKE) olddefconfig
	cd $(dir $@); PATH=$(kerneldir)/scripts:$${PATH}; $(abspath $<) --verify

# 'W=1' causes build error '-Werror=missing-include-dirs' about
# 'kernel/nvgpu-next/include' and 'kernel/nvidia-t23x/include',
# therefore do not add 'W=1'.
mrproper tegra_defconfig olddefconfig modules_prepare dtbs Image modules install modules_install headers_install: l4t-src toolchain
	$(MAKE) -C $(kerneldir) V=1 O=$(abspath $(builddir)) HOST_EXTRACFLAGS=-fcommon $@

dtbs Image modules: $(builddir)/.config

tags:
	ctags -R \
		--exclude=Documentation \
		--exclude=tools \
		--exclude=arch \
		--exclude=amd \
		--exclude=radeon \
		--exclude=intel \
		--exclude=realtek \
		*.[ch] \
		$(kerneldir) \
		$(kerneldir)/arch/arm \
		$(kerneldir)/arch/arm64 \
		$(dir $(kerneldir))nvidia

clean:
	$(RM) -r *.ko *.mod.c *.o .*.ko.cmd .*.mod.o.cmd .*.o.cmd .tmp_versions Module.symvers modules.order
	$(RM) -r $(builddir)

distclean: clean
	$(RM) -r tags toolchain rootfs
	[ ! -d l4t ] || find l4t -mindepth 2 -maxdepth 2 -type d -name Linux_for_Tegra -exec rm -fr {} +

setup: l4t l4t-src toolchain

l4t: $(l4ttop)/flash.sh

$(l4ttop)/flash.sh: $(l4tdir)/tegra186_linux_r$(l4t_major).$(l4t_minor)_aarch64.tbz2
	tar xjvf $< -C $(l4tdir)
	touch $@

$(l4tdir)/tegra186_linux_r$(l4t_major).$(l4t_minor)_aarch64.tbz2:
	mkdir -p $(dir $@)
	for url in \
			https://developer.nvidia.com/embedded/l4t/r$(l4t_major)_release_v$(l4t_minor)/r$(l4t_major)_release_v$(l4t_minor)/t186/$(notdir $@) \
			https://developer.nvidia.com/embedded/L4T/r$(l4t_major)_Release_v$(l4t_minor)/T186/$(notdir $@) \
			https://developer.nvidia.com/embedded/L4T/r$(l4t_major)_Release_v$(l4t_minor)/r$(l4t_major)_Release_v$(l4t_minor)-GMC3/T186/$(notdir $@) \
			https://developer.nvidia.com/embedded/L4T/r$(l4t_major)_Release_v$(l4t_minor)/t186ref_release_aarch64/$(notdir $@) \
			; do \
		wget -O $@ $${url} && exit; \
	done

l4t-src: $(kerneldir)/Makefile

$(kerneldir)/Makefile: $(l4ttop)/source/public/kernel_src.tbz2
	tar xjvf $< -C $(dir $<)
	touch $@

$(l4ttop)/source/public/kernel_src.tbz2: $(l4tdir)/public_sources.tbz2
	tar xjvf $< -C $(l4tdir)
	touch $@

$(l4tdir)/public_sources.tbz2:
	mkdir -p $(dir $@)
	for url in \
			https://developer.nvidia.com/embedded/l4t/r$(l4t_major)_release_v$(l4t_minor)/r$(l4t_major)_release_v$(l4t_minor)/sources/t186/$(notdir $@) \
			https://developer.nvidia.com/embedded/L4T/r$(l4t_major)_Release_v$(l4t_minor)/sources/T186/$(notdir $@) \
			https://developer.nvidia.com/embedded/L4T/r$(l4t_major)_Release_v$(l4t_minor)/r$(l4t_major)_Release_v$(l4t_minor)-GMC3/Sources/T186/$(notdir $@) \
			; do \
		wget -O $@ $${url} && exit; \
	done

toolchain: toolchain/bin/aarch64-linux-gnu-gcc

toolchain/bin/aarch64-linux-gnu-gcc: l4t/$(cross_toolchain)
	mkdir -p toolchain
	tar xJvf $< -C toolchain --strip-components 1
	touch $@

l4t/$(cross_toolchain):
	mkdir -p $(dir $@)
	wget -O $@ https://developer.nvidia.com/embedded/dlc/$(patsubst %.tar.xz,%,$(notdir $@))
endif
