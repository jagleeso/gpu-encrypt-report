#!/usr/bin/env bash
file="$1"
subtitle="$2"
shift 2

set -e
# set -x

cd "$(dirname "$0")"
source ./common.sh

extract_params='
if (/^> Max input/output array size \(bytes\): ([^\s]+)/) {
    $max_array_size = $1;
} 
END {
    print "$max_array_size";
}
'

# set -x
cat "$file" | perl -lne "$extract_cpu_aes_points"

# max_array_size=$(read_params "$extract_params" | nth_line 1)

plot_throughput_vs_bytes "$@" $file "OpenSSL AES Encrypt - $subtitle" "$extract_cpu_aes_points" "OpenSSL encryption"
