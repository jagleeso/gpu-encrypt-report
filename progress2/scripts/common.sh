plot_throughput_vs() {
    declare -a labels=()
    local width=1
    local height=1
    local xaxis_label=""
    while getopts l:rx: flag; do
        case $flag in
        l)
            labels=("${labels[@]}" "$OPTARG")
            ;;

        r)
            local width=0.45
            local height=0.35
            ;;
        x)
            xaxis_label="$OPTARG"
            ;;
        ?)
            exit;
            ;;
        esac
    done
    shift $(( OPTIND - 1 ));

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
        cat $file | perl -lne  "${extractors[j]}" > "${tmpfiles[j]}"
    done

    plotit() {
        local i=$1
        # lt rgb 'red' 
        # 1 == x axis 
        # 2 == profile time
        # 3 == throughput
        plot_str="'${tmpfiles[i]}' using 1:3 title '${line_titles[i]}' with linespoints pointtype 31 lt rgb '${colors[i]}'"
        if [ ${#labels[@]} != 0 ]; then
            plot_str="$plot_str, '${tmpfiles[i]}' u 1:3:${labels[i]} with labels offset 3,1 notitle"
        fi
        echo "$plot_str"
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
set ylabel "Throughput (bytes/ms)"
set xlabel "$xaxis_label"
set ytics border in scale 1,0.5 nomirror norotate  offset character 0, 0, 0
set term postscript eps 10 solid
set size $width, $height
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

plot_throughput_vs_bytes() {
    declare -a labels=()
    local width=1
    local height=1
    while getopts l:r flag; do
        case $flag in
        l)
            labels=("${labels[@]}" "$OPTARG")
            ;;

        r)
            local width=0.45
            local height=0.35
            ;;
        ?)
            exit;
            ;;
        esac
    done
    shift $(( OPTIND - 1 ));

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
    done

    plotit() {
        local i=$1
        # lt rgb 'red' 
        # 1 == bytes
        # 2 == profile time
        # 3 == throughput
        plot_str="'${tmpfiles[i]}' using 1:3 title '${line_titles[i]}' with linespoints pointtype 31 lt rgb '${colors[i]}'"
        if [ ${#labels[@]} != 0 ]; then
            plot_str="$plot_str, '${tmpfiles[i]}' u 1:3:${labels[i]} with labels offset 3,1 notitle"
        fi
        echo "$plot_str"
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
set ylabel "Throughput (bytes/ms)"
set xlabel "Input size (bytes)"
set ytics border in scale 1,0.5 nomirror norotate  offset character 0, 0, 0
set term postscript eps 10 solid
set size $width, $height
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

plot_time_vs_bytes() {



    declare -a labels=()
    while getopts l: flag; do
        case $flag in
        l)
            labels=("${labels[@]}" "$OPTARG")
            ;;
        ?)
            exit;
            ;;
        esac
    done
    shift $(( OPTIND - 1 ));

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
    done

    plotit() {
        local i=$1
        # lt rgb 'red' 
        plot_str="'${tmpfiles[i]}' using 2:1 title '${line_titles[i]}' with linespoints pointtype 31 lt rgb '${colors[i]}'"
        if [ ${#labels[@]} != 0 ]; then
            plot_str="$plot_str, '${tmpfiles[i]}' u 2:1:${labels[i]} with labels offset 3,1 notitle"
        fi
        echo "$plot_str"
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
set xlabel "Time (ms)"
set ylabel "Input size (bytes)"
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

extract_cpu_to_gpu_points='
if (/^The time to complete CPU-to-GPU input array copy was ([^ ]+) ms/) { 
    $time = $1;
    print "$bytes $time";
} elsif (/^Reading an array input\[(\d+)\]/) {
    $bytes = $1;
}
'

extract_gpu_to_cpu_points='
if (/^The time to complete GPU-to-CPU output array copy was ([^ ]+) ms/) { 
    $time = $1;
    print "$bytes $time";
} elsif (/^Reading an array input\[(\d+)\]/) {
    $bytes = $1;
}
'

extract_aes_points='
if (/^profile time: ([^ ]+) ms/) { 
    $time = $1;
    print "$bytes $time";
} elsif (/^encrypt_cl: count = (\d+)/) {
    $bytes = $1;
}
'

extract_kernel_points='
if (/^The time to complete kernel execution was ([^ ]+) ms/) { 
    $time = $1;
    print "$bytes $time";
} elsif (/^Reading an array input\[(\d+)\]/) {
    $bytes = $1;
}
'

extract_aes_global_worksize_points='
if (/^profile time: ([^ ]+) ms/) { 
    $time = $1;
    print "$global_worksize $bytes $time";
} elsif (/^global is (\d+)/) {
    $global_worksize = $1;
} elsif (/^> Array size \(bytes\): (\d+)/) {
    $bytes = $1;
} elsif (/^> Max global worksize: (\d+)/) {
    $max_global_worksize = $1;
}
'

read_params() {
    local extract_params="$1"
    shift 1
    perl -lne "$extract_params" < $file
}
nth_line() {
    sed "$1q;d"
}
