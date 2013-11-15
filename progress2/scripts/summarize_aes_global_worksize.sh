#!/usr/bin/env bash
# summarize the throughput over a different number of GPU cores
file="$1"
set -e
# set -x

prev_dir="$PWD"
cd "$(dirname "$0")"
source ./common.sh
script_dir="$PWD"
cd "$prev_dir"

cat $file | perl -lne "$extract_aes_global_worksize_points" | \
    # awk '{print $1/1024.0, $2, ($1/1024.0)/$2}'
    # bytes / time
    # $1 = global worksize
    # $2 = bytes
    # $3 = time
    awk '{print $2/$3}' | \
    $script_dir/summary.sh
