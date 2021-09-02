#!/bin/sh

if [ `whoami` != root ]; then
	echo ERROR. \'`basename ${0}`\' must be run as \'root\'. >&2
	exit 1
fi

# @see https://elinux.org/Jetson/l4t/Camera_BringUp

change_clock()
{
	clk=/sys/kernel/debug/bpmp/debug/clk
	for m in vi isp nvcsi; do
		echo 1 > ${clk}/${m}/mrq_rate_locked || return
		cat ${clk}/${m}/max_rate | tee ${clk}/${m}/rate || return
	done
}

enable_dynamic_debug()
{
	dynamic_debug=/sys/kernel/debug/dynamic_debug
	echo file csi5_fops.c +p > ${dynamic_debug}/control || return
}

enable_v4l2_messages()
{
	echo 7 > /sys/class/video4linux/video0/dev_debug || return
}

change_clock || exit
enable_dynamic_debug || exit
# enable_v4l2_messages || exit
