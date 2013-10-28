#!/usr/bin/env bash
file="$1"
set -e
# set -x

cd "$(dirname "$0")"
source ./common.sh

cat $file | perl -lne "$extract_aes_points" | \
    # awk '{print $1/1024.0, $2, ($1/1024.0)/$2}'
    # bytes / time
    awk '{print $1/$2}' | \
    ./summary.sh
