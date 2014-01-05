declare -a gnuplot_colors=(red blue orange)

plot_throughput_vs() {
    # rewrite in terms of plot_throughput_vs_multiple
    parse_plot_throughput_vs_args "$@"
    shift $(( OPTIND - 1 ));

    local file="$1"
    local title="$2"
    shift 2

    local graph="${file%.*}.eps"

    # ["$perl_extract_fields_script" "$line_label" "$file"]+
    plot_throughput_vs_multiple \
        -x "$xaxis_label" \
        -s "$scale" -t "$time_scale" $extra_flags \
        "$graph" "$title" \
        "$@" "$file"
}

declare -a labels=()
parse_plot_throughput_vs_args() {
    labels=()
    width=1
    height=1
    xaxis_label=""
    yaxis_label="Throughput"
    scale="bytes"
    time_scale="ms"
    extra_flags=""
    # OPTIND is initially set to 1, and needs to be re-set to 1 if you want to parse anything again with 
    # getopts
    # http://wiki.bash-hackers.org/howto/getopts_tutorial
    OPTIND=1
    while getopts l:rx:s:t:y: flag; do
        case $flag in
        l)
            labels=("${labels[@]}" "$OPTARG")
            ;;

        r)
            width=0.45
            height=0.35
            extra_flags=" -r"
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
        y)
            yaxis_label="$OPTARG"
            ;;
        ?)
            echo 2>&1 "ERROR: bad arguments";
            exit 1;
            ;;
        esac
    done
    shift $(( OPTIND - 1 ));
    option_d=$OPTIND
    
}

line_label_file_args() {
    # extractor [line_label file]+ -> args=[extractor line_label file]+
    local extractor="$1"
    shift 1
    while [ "$#" -gt 0 ]; do
        local line_label="$1"
        local file="$2"
        args=("${args[@]}" "$extractor" "$line_label" "$file")
        shift 2
    done
}

plot_throughput_vs_multiple() {
    # plot_throughput_vs \
    #     -x "Number of 16 Byte Entries Per Work Item" \
    #     -s MB -t second -r \
    #     "$graph" "$title" \
    #     ["$perl_extract_fields_script" "$line_label" "$file"]+

    parse_plot_throughput_vs_args "$@"
    shift $((option_d - 1))

    local graph="$1"
    local title="$2"
    shift 2

    local num_lines=$(($# / 3))
    declare -a line_titles=()
    declare -a extractors=()
    declare -a colors=()
    colors=("${gnuplot_colors[@]}")
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

    # local graph="${file%.*}.eps"
    # points=$(cat $file | perl -lne "$extract_points")
    for j in $(seq 0 $((num_lines-1))); do
        cat "${files[j]}" | perl -lne  "${extractors[j]}" | \
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
set ylabel "$yaxis_label ($scale/$time_scale)"
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

plot_throughput_vs() {
    # plot_throughput_vs \
    #     -x "Number of 16 Byte Entries Per Work Item" \
    #     -s MB -t second -r \
    #     "$file" "$title" \
    #     ["$perl_extract_fields_script" "$line_label"]+

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
    declare -a colors=()
    colors=("${gnuplot_colors[@]}")
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
    # plot_throughput_vs_bytes_multiple \
    #     -s MB -t second -r \
    #     "some/output/graph.eps" "Some Title" \
    #     ["$perl_extract_fields_script" "$line_label" "$input_file"]+

    declare -a labels=()
    local width=1
    local height=1
    local scale="bytes"
    local time_scale="ms"
    local yaxis_label="Throughput"
    while getopts l:rs:t:w:h:y: flag; do
        case $flag in
        l)
            labels=("${labels[@]}" "$OPTARG")
            ;;

        r)
            width=0.45
            height=0.35
            ;;
        w)
            width="$OPTARG"
            ;;
        h)
            height="$OPTARG"
            ;;
        s)
            scale="$OPTARG"
            ;;
        t)
            time_scale="$OPTARG"
            ;;
        y)
            yaxis_label="$OPTARG"
            ;;
        ?)
            echo 2>&1 "ERROR: bad arguments";
            exit 1;
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
    declare -a colors=()
    colors=("${gnuplot_colors[@]}")
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
set ylabel "$yaxis_label ($scale/$time_scale)"
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
    declare -a colors=()
    colors=("${gnuplot_colors[@]}")
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
    declare -a colors=()
    colors=("${gnuplot_colors[@]}")
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
if (/^profile time 2: ([^ ]+) ms/) { 
    $time = $1;
    print "$bytes $time";
} elsif (/^encrypt_cl: count = (\d+)/) {
    $bytes = $1;
}
'

extract_opencl_aes_sizes_points='
if (/^profile time 2: ([^ ]+) ms/) { 
    $time = $1;
    $throughput = sprintf("%.2f", $bytes/$time);
    print "$bytes $time $throughput";
} elsif (/^encrypt_cl: count = (\d+)/) {
    $bytes = $1;
}
'

extract_opencl_copy_time_points='
if (/^copy time: ([^ ]+) ms/) { 
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
if (/^profile time 2: ([^ ]+) ms/) { 
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

# plot_aes_work_group_size / plot_aes_entries

extract_aes_work_group_size_points='
if (/^profile time 2: ([^ ]+) ms/) { 
    $time = $1;
    $throughput = sprintf("%.2f", $bytes/$time);
    print "$work_group_size $time $throughput";
} elsif (/^> LOCAL = (\d+)/) {
    $work_group_size = $1;
} elsif (/^> Array size \(bytes\): (\d+)/) {
    $bytes = $1;
}
'

extract_params_aes_work_group_size_points='
if (/^> Array size \(bytes\): (.*)/) {
    $array_size = $1;
} elsif (/^> Number of work groups: (.*)/) {
    $num_work_groups = $1;
} elsif (/^> Max work group size: (.*)/) {
    $max_work_group_size = $1;
}

END {
    print "$array_size";
    print "$num_work_groups";
    print "$max_work_group_size";
}
'

extract_coalesce_sizes_points='
if (/^average profile time: ([^ ]+) ms/) { 
    $time = $1;
    $throughput = sprintf("%.2f", $bytes/$time);
    print "$bytes $time $throughput";
} elsif (/^> array size in bytes: (\d+)/) {
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

plot_all_with_extractor() {
    # plot_with_extractor $graph "Title" "X Axis" $extractor line_label_func $plot_throughput_vs_multiple_args

    local graph="$1"
    local title="$2"
    local xaxis="$3"
    local extractor="$4"
    local line_label_func="$5"
    shift 5

    local argv=( "$@" )

    declare -a line_label_files=()
    parse_plot_throughput_vs_args "$@"
    for i in $(seq $((OPTIND - 1)) 2 $(($# - 1))); do
        # line_label="${argv[i]} - group size = $max_work_group_size"
        line_label="$($line_label_func "${argv[i]}")"
        file="${argv[i+1]}"
        line_label_files=("${line_label_files[@]}" "$line_label" "$file")
    done

    declare -a args=()
    line_label_file_args "$extractor" "${line_label_files[@]}"

    plot_throughput_vs_multiple -x "$xaxis" -s "$scale" -t "$time_scale" $extra_flags \
        "$graph" "$title" "${args[@]}"
}
