#!/usr/bin/env bash

VIDEO_FULL_PATH=$1
VIDEO_NAME=$(basename $VIDEO_FULL_PATH)

get_duration() {
    echo "[INFO] Getting recording duration"
    EXACT_VIDEO_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $VIDEO_FULL_PATH)
    VIDEO_DURATION=$(echo ${EXACT_VIDEO_DURATION} | cut -d'.' -f1)
}

calculate_frame_intervals() {
    echo "[INFO] Calculating frame intervals"
    SCREENSHOT_INTERVAL=$(expr $VIDEO_DURATION / 9)
}

capture_frames() {
    echo "[INFO] Capturing Frames"
    VIDEO_DIRECTORY=$(dirname ${VIDEO_FULL_PATH})
    INTERVALS=()
    for ((i=0 ; i <= $VIDEO_DURATION ; i+=$SCREENSHOT_INTERVAL)); do
        UTC_FORMAT_TIMESTAMP=$(date -d@${i} -u +%H:%M:%S)
        INTERVALS+=($i)
        ffmpeg -ss $UTC_FORMAT_TIMESTAMP -loglevel quiet -i $VIDEO_FULL_PATH -frames:v 1 -q:v 2 $VIDEO_DIRECTORY/$i.jpg
    done
}

create_collage() {
    echo "[INFO] Creating collage"
    H_ARRAY=()
    H_FRAMES=()
    for j in "${INTERVALS[@]}"; do
        if [ ${#H_ARRAY[@]} -eq 3 ]; then
            ffmpeg -loglevel quiet \
                   -i $VIDEO_DIRECTORY/${H_ARRAY[0]}.jpg \
                   -i $VIDEO_DIRECTORY/${H_ARRAY[1]}.jpg \
                   -i $VIDEO_DIRECTORY/${H_ARRAY[2]}.jpg \
                   -filter_complex "[0][1][2]hstack=inputs=3" $VIDEO_DIRECTORY/h_$j.jpg        
            H_ARRAY=()
            H_FRAMES+=("h_$j")
        fi
        H_ARRAY+=("$j")
    done
    
    ffmpeg -loglevel quiet \
            -i $VIDEO_DIRECTORY/${H_FRAMES[0]}.jpg \
            -i $VIDEO_DIRECTORY/${H_FRAMES[1]}.jpg \
            -i $VIDEO_DIRECTORY/${H_FRAMES[2]}.jpg \
            -filter_complex "[0][1][2]vstack=inputs=3" $VIDEO_DIRECTORY/${VIDEO_NAME//.mp4}.jpeg  
}

remove_temporary_screenshots() {
    rm $VIDEO_DIRECTORY/*.jpg
}

main() {
    get_duration
    calculate_frame_intervals
    capture_frames
    create_collage
    remove_temporary_screenshots
}

main