#!/bin/sh

config \
	-e DEBUG_KERNEL \
	-e DEBUG_INFO \
	|| exit

config \
	-e FRAME_POINTER \
	-e EXPERT \
	-e KALLSYMS \
	-e HAVE_ARCH_KGDB \
	-e KGDB \
	-E KGDB KGDB_SERIAL_CONSOLE \
	-E KGDB KGDB_KDB \
	|| exit
