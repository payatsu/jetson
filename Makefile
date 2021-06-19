module ?= mymodule

ifneq ($(KERNELRELEASE),)
	obj-m := $(module).o
else
	export ARCH          ?= arm64
	export CROSS_COMPILE ?= aarch64-linux-gnu-
	export KERNELDIR     ?= ../Linux_for_Tegra/source/public/kernel/kernel-4.9

all: $(KERNELDIR)/include/config/auto.conf
	$(MAKE) V=1 W=1 -C $(KERNELDIR) M=`pwd` modules

$(KERNELDIR)/include/config/auto.conf:
	$(MAKE) defconfig
	$(MAKE) modules_prepare

mrproper defconfig modules_prepare:
	$(MAKE) V=1 W=1 -C $(KERNELDIR) HOST_EXTRACFLAGS=-fcommon $@

clean:
	$(RM) -r *.ko *.mod.c *.o .*.ko.cmd .*.mod.o.cmd .*.o.cmd .tmp_versions Module.symvers modules.order
endif
