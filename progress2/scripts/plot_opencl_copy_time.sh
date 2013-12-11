#!/usr/bin/env bash
file="$1"
graph="$2"
subtitle="$3"
label="$4"
set -e
shift 4 || 
    (echo 2>&1 "ERROR: file graph subtitle label" && exit 1)

# set -x

cd "$(dirname "$0")"
source ./common.sh
cd -

# set -x
cat "$file" | perl -lne "$extract_opencl_copy_time_points"
# exit

title="OpenCL Copy Time - $subtitle" 
yaxis_label="Copy Rate" 
plot_throughput_vs_bytes_multiple "$@" -y "$yaxis_label" "$graph" "$title" \
    "$extract_opencl_copy_time_points" "$label" "$file"
