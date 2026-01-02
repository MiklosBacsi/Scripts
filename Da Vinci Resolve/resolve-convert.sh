#!/bin/bash

# Configuration
INPUT_DIR="./Convert_from"
TO_RESOLVE_DIR="./To_Resolve"
FROM_RESOLVE_DIR="./From_Resolve"

# Color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' 

# Create input dir if missing
mkdir -p "$INPUT_DIR"

# ENABLE NULLGLOB: This prevents the "*.mkv" error
shopt -s nullglob
shopt -s nocaseglob

clear
echo -e "${BLUE}========================================"
echo -e "      DaVinci Resolve Video Tool"
echo -e "========================================${NC}"
echo "Input Folder: $INPUT_DIR"
echo "----------------------------------------"
echo "1. TO RESOLVE (Convert from $INPUT_DIR to DNxHR .mov)"
echo "2. FROM RESOLVE (Convert from $INPUT_DIR to H.264)"
echo "3. Exit"
echo -n "Select an option [1-3]: "
read main_opt

case $main_opt in
    1)
        echo -e "${BLUE}Select Quality:${NC}"
        echo "1. High Quality (DNxHR HQ - Large files)"
        echo "2. Fast Editing (DNxHR LB - Small files, easier on HDD)"
        echo -n "Select [1-2]: "
        read qual_opt
        
        if [ "$qual_opt" == "2" ]; then
            profile="dnxhr_lb"
            suffix="_LB"
            msg="Low Bandwidth (LB)"
        else
            profile="dnxhr_hq"
            suffix=""
            msg="High Quality (HQ)"
        fi
        
        # Create an array of all mp4 and mkv files
        files=("$INPUT_DIR"/*.mp4 "$INPUT_DIR"/*.mkv)
        
        if [ ${#files[@]} -gt 0 ]; then
            echo -e "${GREEN}\nStarting conversion to $msg...${NC}"
            mkdir -p "$TO_RESOLVE_DIR"
            for f in "${files[@]}"; do
                filename=$(basename "$f")
                base="${filename%.*}"
                echo -e "Processing: $filename -> ${base}${suffix}.mov"
                # Use selected profile
                ffmpeg -i "$f" -c:v dnxhd -profile:v "$profile" -pix_fmt yuv422p -c:a pcm_s16le "$TO_RESOLVE_DIR/${base}${suffix}.mov" -y -stats -loglevel warning
            done
            notify-send -u critical "Video Tool" "Finished converting ${#files[@]} files to $msg." -i video-x-generic
            paplay /usr/share/sounds/freedesktop/stereo/complete.oga
        else
            echo -e "${RED}No .mp4 or .mkv files found in $INPUT_DIR${NC}"
        fi
        ;;

    2)
        files=("$INPUT_DIR"/*.mov)
        
        if [ ${#files[@]} -gt 0 ]; then
            echo -e "${BLUE}\nConvert FROM Resolve to:${NC}"
            echo "1. .mkv (H.264 GPU)"
            echo "2. .mp4 (H.264 GPU)"
            echo -n "Select format [1-2]: "
            read format_opt
            
            if [ "$format_opt" == "1" ]; then ext="mkv"; else ext="mp4"; fi
            
            echo -e "${GREEN}\nStarting GPU accelerated export...${NC}"
            mkdir -p "$FROM_RESOLVE_DIR"
            for f in "${files[@]}"; do
                filename=$(basename "$f")
                echo -e "Processing: $filename"
                # Using VAAPI for AMD RX 5700 XT
                ffmpeg -vaapi_device /dev/dri/renderD128 -i "$f" \
                       -vf 'format=nv12,hwupload' \
                       -c:v h264_vaapi -qp 18 \
                       -color_primaries bt709 -color_trc bt709 -colorspace bt709 \
                       -c:a aac -b:a 192k \
                       "$FROM_RESOLVE_DIR/${filename%.*}.$ext" -y -stats -loglevel warning
            done
            notify-send -u critical "Video Tool" "Finished GPU export of ${#files[@]} files to $ext." -i video-x-generic
            paplay /usr/share/sounds/freedesktop/stereo/complete.oga
        else
            echo -e "${RED}No .mov files found in $INPUT_DIR${NC}"
        fi
        ;;

    3)
        exit 0
        ;;

    *)
        echo -e "${RED}Invalid option.${NC}"
        ;;
esac

# Turn off the special glob settings before exiting
shopt -u nullglob
shopt -u nocaseglob
