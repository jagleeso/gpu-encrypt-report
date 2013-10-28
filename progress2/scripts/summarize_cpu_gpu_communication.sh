#!/usr/bin/env bash
file="$1"
set -e
# set -x

cd "$(dirname "$0")"
source ./common.sh

cat $file | perl -lne "$extract_cpu_to_gpu_points" | \
    # bytes / time => kbs / time
    # awk '{print ($1/1024.0)/$2}'
    awk '{print $2}' | ./summary.sh
