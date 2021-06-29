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

config \
	-e PROFILING \
	-e HAVE_PERF_EVENTS \
	-e PERF_EVENTS \
	|| exit

config \
	-e HAVE_KPROBES \
	-e KPROBES \
	-e HAVE_REGS_AND_STACK_ACCESS_API \
	-e KPROBE_EVENTS \
	-e ARCH_SUPPORTS_UPROBES \
	-e MMU \
	-e UPROBES \
	-e UPROBE_EVENTS \
	|| exit

config \
	-e BPF \
	-e BPF_SYSCALL \
	-e HAVE_EBPF_JIT \
	-e BPF_JIT \
	-e BPF_EVENTS \
	-e IKHEADERS \
	-m NET_CLS_BPF \
	-m NET_ACT_BPF \
	|| exit
