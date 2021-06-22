module ?= mymodule

ifneq ($(KERNELRELEASE),)
	obj-m := $(module).o
else
	export ARCH          ?= arm64
	export CROSS_COMPILE ?= aarch64-linux-gnu-
	export LOCALVERSION  ?= -tegra
	export KERNELDIR     ?= Linux_for_Tegra/source/public/kernel/kernel-4.9

	L4T_MAJOR := 32
	L4T_MINOR := 5.1
	cross_toolchain = l4t-gcc-7-3-1-toolchain-64-bit.tar.xz
	PATH := $(realpath toolchain/bin):$(PATH)

.PHONY: all mrproper tegra_defconfig modules_prepare dtbs toolchain clean

all: $(module).ko

$(module).ko: build/include/config/auto.conf
	$(MAKE) -C $(KERNELDIR) V=1 W=1 O=`pwd`/build M=`pwd` modules

build/include/config/auto.conf: setup
	$(MAKE) tegra_defconfig
	$(MAKE) modules_prepare

mrproper tegra_defconfig modules_prepare dtbs: setup
	$(MAKE) -C $(KERNELDIR) V=1 W=1 O=`pwd`/build HOST_EXTRACFLAGS=-fcommon $@

setup: l4t l4t-src toolchain

l4t: Linux_for_Tegra/flash.sh

Linux_for_Tegra/flash.sh: tegra186_linux_r$(L4T_MAJOR).$(L4T_MINOR)_aarch64.tbz2
	tar xjvf $<
	touch $@

tegra186_linux_r$(L4T_MAJOR).$(L4T_MINOR)_aarch64.tbz2:
	wget https://developer.nvidia.com/embedded/l4t/r$(L4T_MAJOR)_release_v$(L4T_MINOR)/r$(L4T_MAJOR)_release_v$(L4T_MINOR)/t186/$@

l4t-src: Linux_for_Tegra/source/public/kernel/nvidia/NVIDIA-REVIEWERS

Linux_for_Tegra/source/public/kernel/nvidia/NVIDIA-REVIEWERS: Linux_for_Tegra/source/public/kernel_src.tbz2
	tar xjvf $< -C $(dir $<)
	touch $@

Linux_for_Tegra/source/public/kernel_src.tbz2: public_sources.tbz2
	tar xjvf $<
	touch $@

public_sources.tbz2:
	wget https://developer.nvidia.com/embedded/l4t/r$(L4T_MAJOR)_release_v$(L4T_MINOR)/r$(L4T_MAJOR)_release_v$(L4T_MINOR)/sources/t186/$@

toolchain: toolchain/bin/aarch64-linux-gnu-gcc

toolchain/bin/aarch64-linux-gnu-gcc: $(cross_toolchain)
	mkdir -p toolchain
	tar xJvf $< -C toolchain --strip-components 1
	touch $@

$(cross_toolchain):
	wget -O $@ https://developer.nvidia.com/embedded/dlc/$(patsubst %.tar.xz,%,$@)

clean:
	$(RM) -r *.ko *.mod.c *.o .*.ko.cmd .*.mod.o.cmd .*.o.cmd .tmp_versions Module.symvers build modules.order
endif
