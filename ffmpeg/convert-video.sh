#!/bin/bash

set -e

# Ensure required arguments are set
if [[ -z "$input_video" ]] || [[ -z "$output_dir" ]]; then
    echo "Error: input_video and output_dir are required."
    exit 1
fi

# Ensure at least one of the hls_480p, hls_720p, or hls_1080p is set to 1
if [[ "$hls_480p" != "1" && "$hls_720p" != "1" && "$hls_1080p" != "1" ]]; then
    echo "Error: At least one of hls_480p, hls_720p, or hls_1080p must be set to 1."
    exit 1
fi

# Export input_video and output_dir to be accessible in the preset scripts
export input_video
export output_dir

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Initialize the master playlist content
master_playlist_content="#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-INDEPENDENT-SEGMENTS"

# Function to get stream information using ffprobe
get_stream_info() {
  local playlist_file="$1"

  # Extract video and audio codec information
  local video_codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,profile -of csv=p=0 "$playlist_file" | awk -F',' '{print $1"."$2}')
  local audio_codec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$playlist_file")

  # Extract bandwidth from video stream
  local bandwidth=$(ffprobe -v error -select_streams v:0 -show_entries format=bit_rate -of csv=p=0 "$playlist_file" | awk '{print $1}')  # In bits per second
  local average_bandwidth=$((bandwidth * 90 / 100))  # Estimate 90% of peak bandwidth

  # Extract frame rate
  local frame_rate=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$playlist_file" | bc)

  # Extract actual resolution
  local resolution=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$playlist_file")

  # Output master playlist info for this stream
  echo "#EXT-X-STREAM-INF:BANDWIDTH=$bandwidth,AVERAGE-BANDWIDTH=$average_bandwidth,CODECS=\"${video_codec},${audio_codec}\",RESOLUTION=$resolution,FRAME-RATE=$frame_rate"
}


# Process 480p if requested
if [[ "$hls_480p" == "1" ]]; then
  echo "Processing 480p..."
  bash "$(dirname "$0")/presets/hls_480p.sh"
  stream_info=$(get_stream_info "$output_dir/master_480p.m3u8")
  master_playlist_content+="\n$(tail -n 3 "$output_dir/master_480p.m3u8")"
fi

# Process 720p if requested
if [[ "$hls_720p" == "1" ]]; then
  echo "Processing 720p..."
  bash "$(dirname "$0")/presets/hls_720p.sh"
  stream_info=$(get_stream_info "$output_dir/master_720p.m3u8")
  master_playlist_content+="\n$(tail -n 3 "$output_dir/master_720p.m3u8")"
fi

# Process 1080p if requested
if [[ "$hls_1080p" == "1" ]]; then
  echo "Processing 1080p..."
  bash "$(dirname "$0")/presets/hls_1080p.sh"
  stream_info=$(get_stream_info "$output_dir/master_1080p.m3u8")
  master_playlist_content+="\n$(tail -n 3 "$output_dir/master_1080p.m3u8")"
fi

# Write the combined master playlist to index.m3u8 in the output directory
echo -e "$master_playlist_content" > "$output_dir/index.m3u8"

echo "Master playlist created at $output_dir/index.m3u8"
