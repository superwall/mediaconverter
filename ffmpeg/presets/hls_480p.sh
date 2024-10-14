#!/bin/bash

set -ex

ffmpeg -i "$input_video" \
-vf "scale=-2:480" \
-c:v libx264 \
-b:v 700k \
-maxrate 700k \
-bufsize 700k \
-pix_fmt yuv420p \
-g 60 \
-keyint_min 60 \
-sc_threshold 0 \
-refs 3 \
-profile:v main \
-x264-params "aq-mode=2:qpmin=0:qpmax=51:me=umh:subme=7:bframes=0" \
-framerate 30 \
-r 30 \
-c:a aac \
-b:a 128k \
-ac 2 \
-ar 44100 \
-f hls \
-hls_time 9 \
-hls_list_size 0 \
-hls_segment_type mpegts \
-hls_flags delete_segments \
-master_pl_name master_480p.m3u8 \
-hls_segment_filename "$output_dir/index_480p_%05d.ts" \
"$output_dir/index_480p.m3u8"
