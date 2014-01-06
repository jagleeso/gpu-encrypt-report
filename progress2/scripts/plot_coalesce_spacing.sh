#!/usr/bin/env bash
prefix="$1"
min_spacing="$2"
max_spacing="$3"
subtitle="$4"
label_prefix="$5"
set -e
shift 5 || 
    (echo 2>&1 "ERROR: prefix min_spacing max_spacing subtitle label_prefix" && exit 1)

# set -x

cd "$(dirname "$0")"
source ./common.sh
cd -

# set -x
# cat "$file" | perl -lne "$extract_coalesce_sizes_points"
# exit

title="Coalesce - $subtitle" 
# plot_throughput_vs_bytes "$@" $file "$extract_coalesce_sizes_points" "AES_encrypt" 
graph="$prefix.eps"
declare -a args=()
for spacing in $(seq $min_spacing $max_spacing); do
    file="$prefix.${spacing}_spacing.txt"
    cat "$file" | perl -lne "$extract_coalesce_sizes_points"
    echo '---------------------------'
    args=("${args[@]}" \
            "$extract_coalesce_sizes_points" \
            "${label_prefix}spacing = $spacing" \
            "$file")
done

plot_throughput_vs_bytes_multiple "$@" "$graph" "$title" \
    "${args[@]}" \
