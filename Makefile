ifneq ($(KERNELRELEASE),)
	obj-m := mymodule.o
else
	export ARCH          ?= arm64
	export CROSS_COMPILE ?= aarch64-linux-gnu-
	export KERNELDIR     ?= ../Linux_for_Tegra/source/public/kernel/kernel-4.9
default:
	$(MAKE) -j 8 V=1 W=1 -C $(KERNELDIR) M=`pwd` modules
mrproper defconfig:
	$(MAKE) -j 8 V=1 W=1 -C $(KERNELDIR) HOST_EXTRACFLAGS=-fcommon $@
endif
