plot_time_vs_bytes() {
    local file="$1"
    local title="$2"
    shift 2
    local num_lines=$(($# / 2))
    declare -a line_titles=()
    declare -a extractors=()
    declare -a colors=(red blue violet)
    while [ "$#" -gt 0 ]; do
        extractors=("${extractors[@]}" "$1")
        line_titles=("${line_titles[@]}" "$2")
        shift 2
    done

    declare -a tmpfiles=()
    for i in $(seq 1 $num_lines); do
        tmpfile="$(mktemp -u)"
        tmpfiles=("${tmpfiles[@]}" "$tmpfile")
    done

    cleanup() {
        echo ">> Cleaning up"
        for FIFO in "${tmpfiles[@]}"; do
            [ -e "$FIFO" ] && rm -f "$FIFO" 
        done
    }
    trap cleanup EXIT INT TERM HUP

    local graph="${file%.*}.eps"
    # points=$(cat $file | perl -lne "$extract_points")
    for j in $(seq 0 $((num_lines-1))); do
        echo cat $file \| perl -lne  "${extractors[j]}" \> "${tmpfiles[j]}"
        cat $file | perl -lne  "${extractors[j]}" > "${tmpfiles[j]}"
        echo '============'
        cat $file | perl -lne  "${extractors[j]}" 
        echo '============'
    done

    plotit() {
        local i=$1
        # lt rgb 'red' 
        echo "'${tmpfiles[i]}' title '${line_titles[i]}' with linespoints pointtype 31 lt rgb '${colors[i]}'"
    }
    to_plot=$(plotit 0)
    for i in $(seq 1 $((num_lines-1))); do
        to_plot="$to_plot, $(plotit $i)"
    done

    # > Max input/output array size (bytes): 8192
    # > Error in max input/output (bytes): 8192
    # > Sample input/ouput size increment (bytes): powers of two starting at 128, ending at 8192
    # > Samples: 7

# set size 0.45, 0.35
    gnuplot <<EOF
set title "$title"
set xlabel "Input size (bytes)"
set ylabel "Time (ms)"
set ytics border in scale 1,0.5 nomirror norotate  offset character 0, 0, 0
set term postscript eps 10 solid
set size 1, 1
set output "$graph"

set border 2 front linetype 1 linewidth 1.000
set boxwidth 300
set style fill   solid 0.25 border lt -1
set key outside bottom center Left nobox
set pointsize 0.5

plot $to_plot
set yrange [GPVAL_DATA_Y_MIN:GPVAL_DATA_Y_MAX]

EOF
}
