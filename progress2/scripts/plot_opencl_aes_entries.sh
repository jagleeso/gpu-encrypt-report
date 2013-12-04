#!/usr/bin/env bash
graph="$1"
main_title="$2"
subtitle="$3"
shift 3

set -e

prev_dir="$PWD"
cd "$(dirname "$0")"
source ./common.sh
script_dir="$PWD"
cd "$prev_dir"

extract_aes_entries_points='
if (/^profile time: ([^ ]+) ms/) { 
    $time = $1;
    $throughput = sprintf("%.2f", $bytes/$time);
    print "$entries $time $throughput";
} elsif (/^entries == (\d+)/) {
    $entries = $1;
} elsif (/^> Array size \(bytes\): (\d+)/) {
    $bytes = $1;
}
'

extract_params_aes_entries='
BEGIN {
    use Carp::Assert;
}

if (/^> Array size \(bytes\): (.*)/) {
    $array_size = $1;
} elsif (/^> LOCAL = (\d+)/) {
    if (defined $max_work_group_size) {
        assert($1 == $max_work_group_size);
    } else {
        $max_work_group_size = $1;
    }
}

END {
    print "$array_size";
    print "$max_work_group_size";
}
'

# set -x
# cat "$file" | perl -lne "$extract_aes_entries_points"
# exit

argv=( "$@" )
# make read_params work...
file="${argv[${#argv[@]} - 1]}"

array_size=$(read_params "$extract_params_aes_entries" | nth_line 1)
# Assume we are using the max group size for all
max_work_group_size=$(read_params "$extract_params_aes_entries" | nth_line 2)
title="$main_title - $subtitle ($(( (array_size/1024)/1024 ))MB)" 
xaxis="Number of 16 Byte Entries Per Work Item"

declare -a line_label_files=()
parse_plot_throughput_vs_args "$@"
for i in $(seq $((OPTIND - 1)) 2 $(($# - 1))); do
    line_label="${argv[i]} - group size = $max_work_group_size"
    file="${argv[i+1]}"
    line_label_files=("${line_label_files[@]}" "$line_label" "$file")
done

declare -a args=()
line_label_file_args "$extract_aes_entries_points" "${line_label_files[@]}"

plot_throughput_vs_multiple -x "$xaxis" -s "$scale" -t "$time_scale" $extra_flags \
    "$graph" "$title" "${args[@]}"
