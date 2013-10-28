#!/usr/bin/env bash
cd $(dirname $0)
set -x
set -e

./plot_cpu_gpu_communication.sh ../sample_cpu_gpu_communication.100_datapoints.txt

./plot_opencl_aes_sizes.sh ../sample_opencl_aes_sizes.txt

./summarize_cpu_gpu_communication.sh ../sample_cpu_gpu_communication.100_datapoints.txt > ../summarize_cpu_gpu_communication.txt
./summarize_gpu_cpu_communication.sh ../sample_cpu_gpu_communication.100_datapoints.txt > ../summarize_gpu_cpu_communication.txt

./summarize_empty_kernel.sh ../sample_empty_kernel.25_times.txt  > ../summarize_empty_kernel.txt

./summarize_opencl_aes_sizes.sh ../sample_opencl_aes_sizes.txt > ../summarize_opencl_aes_sizes.txt
