module ?= mymodule

ifneq ($(KERNELRELEASE),)
	obj-m := $(module).o
else
	export ARCH          ?= arm64
	export CROSS_COMPILE ?= aarch64-linux-gnu-
	export LOCALVERSION  ?= -tegra
	export KERNELDIR     ?= $(wildcard Linux_for_Tegra/source/public/kernel/kernel-*.*)

	cross_toolchain = l4t-gcc-7-3-1-toolchain-64-bit.tar.xz
	PATH := $(realpath toolchain/bin):$(PATH)

.PHONY: all mrproper tegra_defconfig modules_prepare dtbs toolchain clean

all: build/include/config/auto.conf
	$(MAKE) -C $(KERNELDIR) V=1 W=1 O=`pwd`/build M=`pwd` modules

build/include/config/auto.conf:
	$(MAKE) tegra_defconfig
	$(MAKE) modules_prepare

mrproper tegra_defconfig modules_prepare dtbs:
	$(MAKE) -C $(KERNELDIR) V=1 W=1 O=`pwd`/build HOST_EXTRACFLAGS=-fcommon $@

setup: upstream toolchain

upstream: Linux_for_Tegra/source/public/kernel/nvidia/NVIDIA-REVIEWERS

Linux_for_Tegra/source/public/kernel/nvidia/NVIDIA-REVIEWERS: Linux_for_Tegra/source/public/kernel_src.tbz2
	tar xjvf $< -C $(dir $<)
	touch $@

Linux_for_Tegra/source/public/kernel_src.tbz2: public_sources.tbz2
	tar xjvf $<
	touch $@

public_sources.tbz2:
	wget https://developer.nvidia.com/embedded/l4t/r32_release_v5.1/r32_release_v5.1/sources/t186/$@

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
