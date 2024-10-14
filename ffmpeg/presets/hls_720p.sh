#!/bin/bash

set -ex

ffmpeg -i "$input_video" \
-vf "scale=-2:720" \
-c:v libx264 \
-b:v 1000k \
-maxrate 1000k \
-bufsize 1000k \
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
-master_pl_name master_720p.m3u8 \
-hls_segment_filename "$output_dir/index_720p_%05d.ts" \
"$output_dir/index_720p.m3u8"
