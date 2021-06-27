module ?= mymodule
obj-m := $(module).o

ifeq ($(KERNELRELEASE),)
	export ARCH          ?= arm64
	export CROSS_COMPILE ?= $(shell which ccache > /dev/null && echo ccache) aarch64-linux-gnu-
	export LOCALVERSION  ?= -tegra

	builddir := $(abspath build)
	l4t_major ?= 32
	l4t_minor ?= 5.1
	kerneldir ?= $(abspath Linux_for_Tegra/source/public/kernel/kernel-4.9)
	cross_toolchain := l4t-gcc-7-3-1-toolchain-64-bit.tar.xz
	PATH := $(abspath toolchain/bin):$(PATH)

ifeq ($(realpath /etc/nv_tegra_release),)
	export INSTALL_PATH     ?= $(abspath rootfs)
	export INSTALL_MOD_PATH ?= $(abspath rootfs)
	export INSTALL_HDR_PATH ?= $(abspath rootfs)/usr
endif

.PHONY: all mrproper tegra_defconfig olddefconfig modules_prepare dtbs Image modules install modules_install headers_install setup l4t l4t-src toolchain clean distclean

all: $(module).ko

$(module).ko: $(builddir)/include/config/auto.conf $(patsubst %.o,%.c,$(obj-m))
	$(MAKE) -C $(kerneldir) V=1 W=1 O=$(builddir) M=`pwd` modules

$(builddir)/include/config/auto.conf: $(builddir)/.config
	$(MAKE) modules_prepare

$(builddir)/.config: scripts/modify-config.sh
	$(MAKE) tegra_defconfig
	cp $@ $@.orig
	cd $(dir $@); \
		PATH=$(kerneldir)/scripts:$${PATH}; \
		$(abspath $<)
	$(MAKE) olddefconfig
	$(kerneldir)/scripts/diffconfig $@.orig $@

# 'W=1' causes build error '-Werror=missing-include-dirs' about
# 'kernel/nvgpu-next/include' and 'kernel/nvidia-t23x/include',
# therefore do not add 'W=1'.
mrproper tegra_defconfig olddefconfig modules_prepare dtbs Image modules install modules_install headers_install: l4t-src toolchain
	$(MAKE) -C $(kerneldir) V=1 O=$(builddir) HOST_EXTRACFLAGS=-fcommon $@

dtbs Image modules: $(builddir)/.config

tags:
	ctags -R *.[ch] $(kerneldir) $(kerneldir)/../nvidia

setup: l4t l4t-src toolchain

l4t: Linux_for_Tegra/flash.sh

Linux_for_Tegra/flash.sh: tegra186_linux_r$(l4t_major).$(l4t_minor)_aarch64.tbz2
	tar xjvf $<
	touch $@

tegra186_linux_r$(l4t_major).$(l4t_minor)_aarch64.tbz2:
	for url in \
			https://developer.nvidia.com/embedded/l4t/r$(l4t_major)_release_v$(l4t_minor)/r$(l4t_major)_release_v$(l4t_minor)/t186/$@ \
			https://developer.nvidia.com/embedded/L4T/r$(l4t_major)_Release_v$(l4t_minor)/T186/$@ \
			https://developer.nvidia.com/embedded/L4T/r$(l4t_major)_Release_v$(l4t_minor)/r$(l4t_major)_Release_v$(l4t_minor)-GMC3/T186/$@ \
			; do \
		wget $${url} && exit; \
	done

l4t-src: $(kerneldir)/Makefile

$(kerneldir)/Makefile: Linux_for_Tegra/source/public/kernel_src.tbz2
	tar xjvf $< -C $(dir $<)
	touch $@

Linux_for_Tegra/source/public/kernel_src.tbz2: public_sources.tbz2
	tar xjvf $<
	touch $@

public_sources.tbz2:
	for url in \
			https://developer.nvidia.com/embedded/l4t/r$(l4t_major)_release_v$(l4t_minor)/r$(l4t_major)_release_v$(l4t_minor)/sources/t186/$@ \
			https://developer.nvidia.com/embedded/L4T/r$(l4t_major)_Release_v$(l4t_minor)/sources/T186/$@ \
			https://developer.nvidia.com/embedded/L4T/r$(l4t_major)_Release_v$(l4t_minor)/r$(l4t_major)_Release_v$(l4t_minor)-GMC3/Sources/T186/$@ \
			; do \
		wget $${url} && exit; \
	done

toolchain: toolchain/bin/aarch64-linux-gnu-gcc

toolchain/bin/aarch64-linux-gnu-gcc: $(cross_toolchain)
	mkdir -p toolchain
	tar xJvf $< -C toolchain --strip-components 1
	touch $@

$(cross_toolchain):
	wget -O $@ https://developer.nvidia.com/embedded/dlc/$(patsubst %.tar.xz,%,$@)

clean:
	$(RM) -r *.ko *.mod.c *.o .*.ko.cmd .*.mod.o.cmd .*.o.cmd .tmp_versions Module.symvers modules.order

distclean: clean
	$(RM) -r tags Linux_for_Tegra toolchain rootfs $(builddir)
endif
