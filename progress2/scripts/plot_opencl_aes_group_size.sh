#!/usr/bin/env bash
graph="$1"
file1="$2"
file2="$3"
subtitle="$4"
set -e
shift 4 || 
    (echo 2>&1 "ERROR: $0 graph file1 file2 subtitle" && exit 1)

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
} elsif (/^> GLOBAL = (\d+)/) {
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

file="$file1"
array_size=$(read_params "$extract_params" | nth_line 1)
max_global_worksize=$(read_params "$extract_params" | nth_line 2)

# set -x
cat "$file1" | perl -lne "$extract_aes_local_worksize_points"
echo "--------"
cat "$file2" | perl -lne "$extract_aes_local_worksize_points"
# exit 1

title="OpenCL AES Encrypt - $subtitle ($(( (array_size/1024)/1024 ))MB)" 
xaxis="Group size" 
line_label="OpenCL - work groups = 1"

label1="strided constant T-box - work groups = 1"
label2="strided shared T-box - work groups = 1"

# plot_throughput_vs -x "$xaxis" "$@" "$file" "$title" "$extract_aes_local_worksize_points" "$line_label"
# plot_throughput_vs_multiple -x "$xaxis" -s "$scale" -t "$time_scale" $extra_flags \
#     "$graph" "$title" "${args[@]}"
plot_throughput_vs_multiple -x "$xaxis" "$@" "$graph" "$title" \
    "$extract_aes_local_worksize_points" "$label1" "$file1" \
    "$extract_aes_local_worksize_points" "$label2" "$file2"
