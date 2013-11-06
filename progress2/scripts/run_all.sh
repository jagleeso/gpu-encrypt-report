#!/usr/bin/env bash
cd $(dirname $0)
set -x
set -e

output_dir="$1"
shift 1

[ -d "$output_dir" ] || echo 2>&1 "$0: No such directory $output_dir"

./plot_cpu_gpu_communication.sh ../$output_dir/sample_cpu_gpu_communication.*_datapoints.txt

./plot_opencl_aes_sizes.sh ../$output_dir/sample_opencl_aes_sizes.txt

./summarize_cpu_gpu_communication.sh ../$output_dir/sample_cpu_gpu_communication.*_datapoints.txt > ../$output_dir/summarize_cpu_gpu_communication.txt
./summarize_gpu_cpu_communication.sh ../$output_dir/sample_cpu_gpu_communication.*_datapoints.txt > ../$output_dir/summarize_gpu_cpu_communication.txt

./summarize_empty_kernel.sh ../$output_dir/sample_empty_kernel.25_times.txt  > ../$output_dir/summarize_empty_kernel.txt

./summarize_opencl_aes_sizes.sh ../$output_dir/sample_opencl_aes_sizes.txt > ../$output_dir/summarize_opencl_aes_sizes.txt
