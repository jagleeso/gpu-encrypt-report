#!/usr/bin/env bash
file="$1"
set -e
set -x

cd "$(dirname "$0")"
source ./common.sh

extract_points='
if (/^profile time: ([^ ]+) ms/) { 
    $time = $1;
    print "$bytes $time";
} elsif (/^encrypt_cl: count = (\d+)/) {
    $bytes = $1;
}
'

plot_time_vs_bytes $file "OpenCL AES Encrypt" "$extract_points" "AES_encrypt"
