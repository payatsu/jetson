module ?= mymodule

ifneq ($(KERNELRELEASE),)
	obj-m := $(module).o
else
	export ARCH          ?= arm64
	export CROSS_COMPILE ?= aarch64-linux-gnu-
	export LOCALVERSION  ?= -tegra
	export KERNELDIR     ?= ../Linux_for_Tegra/source/public/kernel/kernel-4.9

all: build/include/config/auto.conf
	$(MAKE) -C $(KERNELDIR) V=1 W=1 O=`pwd`/build M=`pwd` modules

build/include/config/auto.conf:
	$(MAKE) tegra_defconfig
	$(MAKE) modules_prepare

mrproper tegra_defconfig modules_prepare dtbs:
	$(MAKE) -C $(KERNELDIR) V=1 W=1 O=`pwd`/build HOST_EXTRACFLAGS=-fcommon $@

clean:
	$(RM) -r *.ko *.mod.c *.o .*.ko.cmd .*.mod.o.cmd .*.o.cmd .tmp_versions Module.symvers build modules.order
endif
