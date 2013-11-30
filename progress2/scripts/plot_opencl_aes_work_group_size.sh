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

# set -x
cat "$file" | perl -lne "$extract_aes_work_group_size_points"
# exit

array_size=$(read_params "$extract_params_aes_work_group_size_points" | nth_line 1)
num_work_groups=$(read_params "$extract_params_aes_work_group_size_points" | nth_line 2)
max_work_group_size=$(read_params "$extract_params_aes_work_group_size_points" | nth_line 3)
title="OpenCL AES Encrypt - $subtitle ($(( (array_size/1024)/1024 ))MB, Number of work groups = $num_work_groups)" 
xaxis="Local Worksize" 
line_label="AES_encrypt"

plot_throughput_vs -x "$xaxis" "$@" "$file" "$title" "$extract_aes_work_group_size_points" "$line_label"
