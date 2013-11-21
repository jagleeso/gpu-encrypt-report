#!/usr/bin/env bash
file="$1"
subtitle="$2"
shift 2

set -e

prev_dir="$PWD"
cd "$(dirname "$0")"
source ./common.sh
script_dir="$PWD"
cd "$prev_dir"

extract_aes_local_worksize_points='
if (/^profile time: ([^ ]+) ms/) { 
    $time = $1;
    $throughput = sprintf("%.2f", $bytes/$time);
    print "$global_worksize $time $throughput";
} elsif (/^global is (\d+)/) {
    $global_worksize = $1;
} elsif (/^> Array size \(bytes\): (\d+)/) {
    $bytes = $1;
} elsif (/^> Max global worksize: (\d+)/) {
    $max_global_worksize = $1;
}
'

extract_params='
if (/^> Array size \(bytes\): (\d+)/) {
    $array_size = $1;
} elsif (/^> Max global worksize: (\d+)/) {
    $max_global_worksize = $1;
}
END {
    print "$array_size";
    print "$max_global_worksize";
}
'

set -x
cat "$file" | perl -lne "$extract_aes_local_worksize_points"
# exit

array_size=$(read_params "$extract_params" | nth_line 1)
max_global_worksize=$(read_params "$extract_params" | nth_line 2)
title="OpenCL AES Encrypt - $subtitle ($(( (array_size/1024)/1024 ))MB)" 
xaxis="Group size" 
line_label="OpenCL - work groups = 1"

plot_throughput_vs -x "$xaxis" "$@" "$file" "$title" "$extract_aes_local_worksize_points" "$line_label"
