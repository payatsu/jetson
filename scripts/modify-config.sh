#!/bin/sh

config \
	-e DEBUG_KERNEL \
	-e DEBUG_INFO \
	-e FRAME_POINTER \
	-e EXPERT \
	-e PROC_FS \
	-e IKCONFIG \
	-e IKCONFIG_PROC \
	-e KALLSYMS \
	|| exit

# KGDB
config \
	-e HAVE_ARCH_KGDB \
	-e KGDB \
	-E KGDB KGDB_SERIAL_CONSOLE \
	-E KGDB KGDB_KDB \
	|| exit

config \
	-e TRACEPOINTS \
	|| exit

# kprobes, uprobes
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

# perf
config \
	-e PROFILING \
	-e HAVE_PERF_EVENTS \
	-e PERF_EVENTS \
	-e HAVE_PERF_REGS \
	-e HAVE_PERF_USER_STACK_DUMP \
	|| exit

# eBPF
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
