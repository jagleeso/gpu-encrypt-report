#!/usr/bin/env bash
graph="$1"
subtitle="$2"
set -e
if ! shift 2 || [ -z "$files" ] || [ -z "$lbls" ]; then  
    echo 2>&1 "ERROR: [lbls=(...), files=(...)] $0 graph subtitle" && exit 1
fi

# set -x

cd "$(dirname "$0")"
source ./common.sh
cd -

# set -x
# cat "$file" | perl -lne "$extract_opencl_aes_sizes_points"
# exit

# plot_time_vs_bytes -l '3' $file "OpenCL AES Encrypt" "$extract_opencl_aes_sizes_points" "AES_encrypt (labeled with bytes/ms)"
# plot_throughput_vs_bytes "$@" $file "OpenCL AES Encrypt - $subtitle" "$extract_opencl_aes_sizes_points" "AES_encrypt" 

title="OpenCL AES Encrypt - $subtitle" 
xaxis="Input size (MB)"

declare -a line_label_files=()
declare -a files=($files)
declare -a lbls=($lbls)
for i in $( seq 0 $((${#lbls[@]} - 1)) ); do
    echo $i
    line_label="$(sed 's/_/ /g' <<<"${lbls[i]}")"
    file="${files[i]}"
    echo "line_label = $line_label"
    echo "file = $file"
    line_label_files=("${line_label_files[@]}" "$line_label" "$file")
done

declare -a args=()
line_label_file_args "$extract_opencl_aes_sizes_points" "${line_label_files[@]}"


# plot_throughput_vs_bytes_multiple \
#     -s MB -t second -r \
#     "some/output/graph.eps" "Some Title" \
#     ["$perl_extract_fields_script" "$line_label" "$input_file"]+
# set -x
plot_throughput_vs_bytes_multiple "$@" "$graph" "$title" "${args[@]}"
