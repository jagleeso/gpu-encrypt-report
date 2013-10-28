#!/usr/bin/env bash
file="$1"
set -e
# set -x

cd "$(dirname "$0")"
source ./common.sh

extract_cpu_to_gpu_points='
if (/^The time to complete CPU-to-GPU input array copy was ([^ ]+) ms/) { 
    $time = $1;
    print "$bytes $time";
} elsif (/^Reading an array input\[(\d+)\]/) {
    $bytes = $1;
}
'

extract_gpu_to_cpu_points='
if (/^The time to complete GPU-to-CPU output array copy was ([^ ]+) ms/) { 
    $time = $1;
    print "$bytes $time";
} elsif (/^Reading an array input\[(\d+)\]/) {
    $bytes = $1;
}
'

plot_time_vs_bytes $file "Copying Between GPU Device Memory and Main Memory" \
    "$extract_cpu_to_gpu_points" "CPU-to-GPU" \
    "$extract_gpu_to_cpu_points" "GPU-to-CPU"
