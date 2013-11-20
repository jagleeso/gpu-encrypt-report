#!/usr/bin/env bash
file="$1"
subtitle="$2"
shift 2

set -e
# set -x

cd "$(dirname "$0")"
source ./common.sh
cd -

# set -x
cat "$file" | perl -lne "$extract_opencl_aes_sizes_points"
# exit

# plot_time_vs_bytes -l '3' $file "OpenCL AES Encrypt" "$extract_opencl_aes_sizes_points" "AES_encrypt (labeled with bytes/ms)"
plot_throughput_vs_bytes "$@" $file "OpenCL AES Encrypt - $subtitle" "$extract_opencl_aes_sizes_points" "AES_encrypt" 
