#!/usr/bin/env bash
file="$1"
set -e
# set -x

cd "$(dirname "$0")"
source ./common.sh

plot_time_vs_bytes $file "Copying Between GPU Device Memory and Main Memory" \
    "$extract_cpu_to_gpu_points" "CPU-to-GPU" \
    "$extract_gpu_to_cpu_points" "GPU-to-CPU"
