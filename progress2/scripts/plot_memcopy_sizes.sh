#!/usr/bin/env bash
graph="$1"
subtitle="$2"
file1="$3"
label_suffix1="$4"
file2="$5"
label_suffix2="$6"

set -e
shift 6 || 
    (echo 2>&1 "ERROR: graph subtitle file1 label_suffix1 file2 label_suffix2" && exit 1)

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
    for file in "$file1" "$file2"; do
        cat "$file" | perl -lne "$extractor"
        spacer
    done
done
# exit

declare -a cpu_gpu_args_return=()
cpu_gpu_args() {
    local file="$1"
    local label_suffix="$2"
    shift 2
    cpu_gpu_args_return=( \
        "$extract_memcopy_gpu_to_cpu_sizes_points" "GPU-to-CPU${label_suffix}" "$file"
        "$extract_memcopy_cpu_to_gpu_sizes_points" "CPU-to-GPU${label_suffix}" "$file"
    )
}

title="CPU-GPU Communication - $subtitle" 
# graph="${file%.*}.eps"

declare -a args=()
cpu_gpu_args "$file1" "$label_suffix1"
args=("${args[@]}" "${cpu_gpu_args_return[@]}")
cpu_gpu_args "$file2" "$label_suffix2"
args=("${args[@]}" "${cpu_gpu_args_return[@]}")

plot_throughput_vs_bytes_multiple "$@" "$graph" "$title" \
    "${args[@]}"
    # "$extract_memcopy_cpu_to_gpu_sizes_points" "CPU-to-GPU" "$file" \
    # "$extract_memcopy_gpu_to_cpu_sizes_points" "GPU-to-CPU" "$file" \
