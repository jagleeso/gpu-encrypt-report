#!/usr/bin/env bash
file="$1"
set -e
# set -x

cd "$(dirname "$0")"
source ./common.sh

cat $file | perl -lne "$extract_kernel_points" | \
    awk '{print $2}' | \
    ./summary.sh
