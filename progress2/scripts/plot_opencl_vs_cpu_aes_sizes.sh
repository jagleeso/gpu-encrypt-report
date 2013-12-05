#!/usr/bin/env bash
opencl_file="$1"
opencl_label="$2" 

cpu_file="$3"
cpu_label="$4" 

output_graph="$5"
subtitle="$6"

NARGS=6
if [ "$#" -lt $NARGS ]; then
    echo 1>&2 "ERROR: too few arguments"
    exit 1
fi
shift $NARGS

set -e
# set -x

cd "$(dirname "$0")"
source ./common.sh
cd -

# set -x
# cat "$opencl_file" | perl -lne "$extract_opencl_aes_sizes_points"
# cat "$cpu_file" | perl -lne "$extract_cpu_aes_points"
# exit

# plot_time_vs_bytes -l '3' $file "OpenCL AES Encrypt" "$extract_opencl_aes_sizes_points" "AES_encrypt (labeled with bytes/ms)"
title="Encryption Throughput - $subtitle" 
opencl_label="OpenCL - $opencl_label" 
cpu_label="OpenSSL - $cpu_label" 
plot_throughput_vs_bytes_multiple "$@" "$output_graph" "$title" \
    "$extract_opencl_aes_sizes_points" "$opencl_label" "$opencl_file" \
    "$extract_cpu_aes_points" "$cpu_label" "$cpu_file" \

