#!/usr/bin/env bash
file="$1"
subtitle="$2"
set -e
shift 2 || 
    (echo 2>&1 "ERROR: file subtitle" && exit 1)

# set -x

cd "$(dirname "$0")"
source ./common.sh
cd -

extract_memcopy_cpu_to_gpu_sizes_points='
if (/^average CPU-to-GPU copy time: ([^ ]+) ms/) { 
    $time = $1;
    $throughput = sprintf("%.2f", $bytes/$time);
    print "$bytes $time $throughput";
} elsif (/^> array size in bytes: (\d+)/) {
    $bytes = $1;
}
'

extract_memcopy_gpu_to_cpu_sizes_points='
if (/^average GPU-to-CPU copy time: ([^ ]+) ms/) { 
    $time = $1;
    $throughput = sprintf("%.2f", $bytes/$time);
    print "$bytes $time $throughput";
} elsif (/^> array size in bytes: (\d+)/) {
    $bytes = $1;
}
'

# set -x
for extractor in "$extract_memcopy_cpu_to_gpu_sizes_points" "$extract_memcopy_gpu_to_cpu_sizes_points"; do
    cat "$file" | perl -lne "$extractor"
    spacer
done
# exit

title="CPU-GPU Communication - $subtitle" 
graph="${file%.*}.eps"
plot_throughput_vs_bytes_multiple "$@" "$graph" "$title" \
    "$extract_memcopy_cpu_to_gpu_sizes_points" "CPU-to-GPU" "$file" \
    "$extract_memcopy_gpu_to_cpu_sizes_points" "GPU-to-CPU" "$file" \
