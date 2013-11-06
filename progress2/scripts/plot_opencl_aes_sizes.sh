#!/usr/bin/env bash
file="$1"
set -e
# set -x

cd "$(dirname "$0")"
source ./common.sh

extract_aes_points='
if (/^profile time: ([^ ]+) ms/) { 
    $time = $1;
    $throughput = sprintf("%.2f", $bytes/$time);
    print "$bytes $time $throughput";
} elsif (/^encrypt_cl: count = (\d+)/) {
    $bytes = $1;
}
'

# plot_time_vs_bytes -l '3' $file "OpenCL AES Encrypt" "$extract_aes_points" "AES_encrypt (labeled with bytes/ms)"
plot_throughput_vs_bytes $file "OpenCL AES Encrypt - MotoX" "$extract_aes_points" "AES_encrypt"
