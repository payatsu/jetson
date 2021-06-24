module ?= mymodule

ifneq ($(KERNELRELEASE),)
	obj-m := $(module).o
else
	export ARCH          ?= arm64
	export CROSS_COMPILE ?= $(shell which ccache > /dev/null && echo ccache) aarch64-linux-gnu-
	export LOCALVERSION  ?= -tegra
	export KERNELDIR     ?= Linux_for_Tegra/source/public/kernel/kernel-4.9

	builddir  := $(abspath build)
	l4t_major := 32
	l4t_minor := 5.1
	cross_toolchain = l4t-gcc-7-3-1-toolchain-64-bit.tar.xz
	PATH := $(abspath toolchain/bin):$(PATH)

.PHONY: all mrproper tegra_defconfig modules_prepare dtbs setup l4t l4t-src toolchain clean distclean

all: $(module).ko

$(module).ko: $(builddir)/include/config/auto.conf
	$(MAKE) -C $(KERNELDIR) V=1 W=1 O=$(builddir) M=`pwd` modules

$(builddir)/include/config/auto.conf:
	$(MAKE) tegra_defconfig
	$(MAKE) modules_prepare

mrproper tegra_defconfig modules_prepare dtbs: $(KERNELDIR)/Makefile
	$(MAKE) -C $(KERNELDIR) V=1 W=1 O=$(builddir) HOST_EXTRACFLAGS=-fcommon $@

tags:
	ctags -R *.[ch] $(KERNELDIR) $(KERNELDIR)/../nvidia

setup: l4t l4t-src toolchain

l4t: Linux_for_Tegra/flash.sh

Linux_for_Tegra/flash.sh: tegra186_linux_r$(l4t_major).$(l4t_minor)_aarch64.tbz2
	tar xjvf $<
	touch $@

tegra186_linux_r$(l4t_major).$(l4t_minor)_aarch64.tbz2:
	wget https://developer.nvidia.com/embedded/l4t/r$(l4t_major)_release_v$(l4t_minor)/r$(l4t_major)_release_v$(l4t_minor)/t186/$@

l4t-src: $(KERNELDIR)/Makefile

$(KERNELDIR)/Makefile: Linux_for_Tegra/source/public/kernel_src.tbz2
	tar xjvf $< -C $(dir $<)
	touch $@

Linux_for_Tegra/source/public/kernel_src.tbz2: public_sources.tbz2
	tar xjvf $<
	touch $@

public_sources.tbz2:
	wget https://developer.nvidia.com/embedded/l4t/r$(l4t_major)_release_v$(l4t_minor)/r$(l4t_major)_release_v$(l4t_minor)/sources/t186/$@

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
	$(RM) -r tags Linux_for_Tegra toolchain $(builddir)
endif
