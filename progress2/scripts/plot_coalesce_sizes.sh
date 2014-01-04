#!/usr/bin/env bash
file="$1"
subtitle="$2"
label="$3"
set -e
shift 3 || 
    (echo 2>&1 "ERROR: file subtitle label" && exit 1)

# set -x

cd "$(dirname "$0")"
source ./common.sh
cd -

extract_coalesce_sizes_points='
if (/^average profile time: ([^ ]+) ms/) { 
    $time = $1;
    $throughput = sprintf("%.2f", $bytes/$time);
    print "$bytes $time $throughput";
} elsif (/^> array size in bytes: (\d+)/) {
    $bytes = $1;
}
'

# set -x
cat "$file" | perl -lne "$extract_coalesce_sizes_points"
# exit

title="Coalesce - $subtitle" 
# plot_throughput_vs_bytes "$@" $file "$extract_coalesce_sizes_points" "AES_encrypt" 
graph="${file%.*}.eps"
plot_throughput_vs_bytes_multiple "$@" "$graph" "$title" \
    "$extract_coalesce_sizes_points" "$label" "$file"
