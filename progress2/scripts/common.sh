plot_throughput_vs() {
    declare -a labels=()
    local width=1
    local height=1
    local xaxis_label=""
    local scale="bytes"
    local time_scale="ms"
    while getopts l:rx:s:t: flag; do
        case $flag in
        l)
            labels=("${labels[@]}" "$OPTARG")
            ;;

        r)
            local width=0.45
            local height=0.35
            ;;
        s)
            scale="$OPTARG"
            ;;
        t)
            time_scale="$OPTARG"
            ;;
        x)
            xaxis_label="$OPTARG"
            ;;
        ?)
            echo 2>&1 "ERROR: bad arguments";
            exit 1;
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


    local convert_scale='
        ($xaxis, $ms, $bytes_per_ms) = @F;
        if ("'$scale'" eq "bytes") {
            $throughput = $bytes_per_ms;
        } elsif ("'$scale'" eq "MB") {
            $throughput = (($bytes_per_ms/1024)/1024);
        } else {
            die "bad scale: '$scale'";
        }

        if ("'$time_scale'" eq "ms") {
            # already UNIT / ms
        } elsif ("'$time_scale'" eq "second") {
            # make it UNIT / second
            $throughput = $throughput * 1000;
        } else {
            die "bad time_scale: '$time_scale'";
        }

        $throughput_rounded = sprintf("%.2f", $throughput);
        print "$xaxis $ms $throughput_rounded $throughput";
    '

    local graph="${file%.*}.eps"
    # points=$(cat $file | perl -lne "$extract_points")
    for j in $(seq 0 $((num_lines-1))); do
        echo "RAW"
        cat "$file" | perl -lne  "${extractors[j]}"
        echo "SCALE"
        cat "$file" | perl -lne  "${extractors[j]}" | \
            perl -lane "$convert_scale"
        cat "$file" | perl -lne  "${extractors[j]}" | \
            perl -lane "$convert_scale" > "${tmpfiles[j]}"
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
set ylabel "Throughput ($scale/$time_scale)"
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

plot_throughput_vs_bytes_multiple() {
    declare -a labels=()
    local width=1
    local height=1
    local scale="bytes"
    local time_scale="ms"
    while getopts l:rs:t: flag; do
        case $flag in
        l)
            labels=("${labels[@]}" "$OPTARG")
            ;;

        r)
            local width=0.45
            local height=0.35
            ;;
        s)
            scale="$OPTARG"
            ;;
        t)
            time_scale="$OPTARG"
            ;;
        ?)
            exit;
            ;;
        esac
    done
    shift $(( OPTIND - 1 ));

    local graph="$1"
    local title="$2"
    shift 2
    local num_lines=$(($# / 3))
    declare -a line_titles=()
    declare -a extractors=()
    declare -a colors=(red blue violet)
    declare -a files=()
    while [ "$#" -gt 0 ]; do
        extractors=("${extractors[@]}" "$1")
        line_titles=("${line_titles[@]}" "$2")
        files=("${files[@]}" "$3")
        shift 3
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

    local convert_scale='
        ($bytes, $ms, $throughput) = @F;
        if ("'$scale'" eq "bytes") {
            $size = $bytes;
        } elsif ("'$scale'" eq "MB") {
            $size = (($bytes/1024)/1024);
        } else {
            die "bad scale: '$scale'";
        }

        if ("'$time_scale'" eq "ms") {
            $time = $ms;
        } elsif ("'$time_scale'" eq "second") {
            $time = $ms / 1000;
        } else {
            die "bad time_scale: '$time_scale'";
        }

        $throughput = sprintf("%.2f", $size/$time);
        print "$size $time $throughput";
    '

    # local graph="${file%.*}.eps"
    # points=$(cat $file | perl -lne "$extract_points")
    for j in $(seq 0 $((num_lines-1))); do
        cat "${files[j]}" | perl -lne  "${extractors[j]}" | \
            perl -lane "$convert_scale" > "${tmpfiles[j]}"
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
set ylabel "Throughput ($scale/$time_scale)"
set xlabel "Input size ($scale)"
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

extract_opencl_aes_sizes_points='
if (/^profile time: ([^ ]+) ms/) { 
    $time = $1;
    $throughput = sprintf("%.2f", $bytes/$time);
    print "$bytes $time $throughput";
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

extract_cpu_aes_points='
if (/^> Encryption time \(ms\): ([^\s]+)/) { 
    $time = $1;
    if ($time != 0) {
        $throughput = sprintf("%.2f", $bytes/$time);
        print join(" ", $bytes, $time, $throughput);
    }
} elsif (/^> Array input size \(bytes\): ([^\s]+)/) {
    $bytes = $1;
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
