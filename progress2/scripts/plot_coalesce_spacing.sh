#!/usr/bin/env bash
prefix="$1"
max_spacing="$2"
subtitle="$3"
label_prefix="$4"
set -e
shift 4 || 
    (echo 2>&1 "ERROR: prefix max_spacing subtitle label_prefix" && exit 1)

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
for spacing in $(seq 0 $max_spacing); do
    file="$prefix.${spacing}_spacing.txt"
    cat "$file" | perl -lne "$extract_coalesce_sizes_points"
    echo '---------------------------'
    args=("${args[@]}" \
            "$extract_coalesce_sizes_points" \
            "${label_prefix}spacing = $spacing" \
            "$file")
done

echo plot_throughput_vs_bytes_multiple "$@" "$graph" "$title" \
    "${args[@]}" \
