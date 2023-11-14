#!/bin/bash
# @author: Peter Bubestinger
# @date: 28.March.2011
# @description: 
#   - Generates the DVA Profession testvideo (generate)
#   - And performs automated checks on a recorded testvideo (run_test)

# @history:
#   pb  03.AUG.2011     - Added "readlink()" for BASE_DIR to obsolete "pwd"
#   pb  01.MAR.2011     - Started.


# ------ Miscellaneous:
RETURN_OK=0
RETURN_ERROR=1
TIMESTAMP=$(date +%Y-%m-%dT%Hh%Mm)
TIMESTAMP_ISO=$(date +%Y-%m-%dT%H:%M)

# ------ Applications:
FFMPEG="/home/pb/install/ffmpeg/ffmpeg-fidelity/ffmpeg"
IM_COMPOSITE="/usr/bin/composite"
IM_CONVERT="/usr/bin/convert"
IM_COMPARE="/usr/bin/compare"

# ------ Graphic / image information:
IMAGE_TYPE="png"
RECTANGLE_POSITION="+600+6"
TIMECODE_POSITION="+0+159"
COLOR_SQUARE_SIZE="16x16"
COLOR_BAR_SIZE="92x154"
VIDEO_SIZE="720x576"            # Default is pal: 720x576
CROP_RECTANGLE="16:96:640:152"  # width:height:x:y

COLOR_REFERENCE[1]='#ff0000';   # red
COLOR_REFERENCE[2]='#00ff00';   # green
COLOR_REFERENCE[3]='#0000ff';   # blue
COLOR_REFERENCE[4]='#ffffff';   # white

COLOR_BAR[1]='#cccccc';         # gray
COLOR_BAR[2]='#ffff00';         # yellow
COLOR_BAR[3]='#00ffff';         #
COLOR_BAR[4]='#00ff00';         # green
COLOR_BAR[5]='#ff00ff';         # 
COLOR_BAR[6]='#ff0000';         # red
COLOR_BAR[7]='#0000ff';         # blue

# ------ Image comparison parameters:
COMPARE_METRIC="AE"     # Absolute Error
COMPARE_FUZZ="40"        # Color deviation tolerance ('fuzz') in percent


# ------ Directories / folders:
BASE_DIR=`pwd`"/x"
IMAGE_SOURCE_DIR="source/images/image_source"
COLOR_REFERENCE_DIR="color_reference"
FROM_VIDEO_DIR="from_video"
FRAMES_DIR="frames"
FIELDS_DIR="fields"
COLOR_SQUARE_DIR="color_squares"

# ------ Filenames:
RECTANGLE_MASK="rect_%03d.$IMAGE_TYPE"
BACKGROUND_IMAGE="grid.$IMAGE_TYPE"
LOGO_IMAGE="mthk_oem_logo.$IMAGE_TYPE"
FRAME_MASK="%06d.$IMAGE_TYPE"
FRAME_DIR_MASK="frame_%02d"
FIELD_MASK="%s.$IMAGE_TYPE"
COLOR_SQUARE_MASK="%s-%s.$IMAGE_TYPE"
COLORBAR_MASK="colorbars.$IMAGE_TYPE"
SIGNAL_PLACEHOLDER="signal_placeholder.$IMAGE_TYPE"
LOG_FILE="dva_pro-generator-$TIMESTAMP.log"
TESTVIDEO_MASK="dva_profession-testvideo-%s_%s-%sframes_at_%sfps.avi"

# ------ Video information:
TESTVIDEO_COLORSPACE="yuv422p"
TESTVIDEO_VCODEC="ffv1"
TESTVIDEO_VERSION="0.1"

FRAME_COUNT=4  # How many frames are to be tested
FPS=25
FIELD_TOP='t'
FIELD_BOTTOM='b'
TIMECODE_MASK="%02d:%02d:%02d:%02d "



function pause
{
    PAUSE="$1"
    echo "Waiting $PAUSE seconds..."
    echo ""
    sleep $PAUSE
}

function keypress
{
    read -p "Press any key to continue."
    echo ""
}


function start_logfile 
{
    echo "====== $(date) ======" > "$LOG_FILE"
}

function log_message
{
    local LOG_MSG="$1"
    echo "$LOG_MSG"
    echo "$LOG_MSG" >> "$LOG_FILE"
}

function log_message_silent
{
    local LOG_MSG="$1"
    echo "$LOG_MSG" >> "$LOG_FILE"
}

function write_error
{
    local MSG="$1"
    echo "ERROR: $MSG"
}


# ----------------------------------------------[ GENERATE VIDEO ]

function generate_color_reference_images
{
    local IMAGE_OUTPUT_DIR="$1"
    local COLOR_DEPTH="PNG8:"

    echo ""
    echo "---------------"
    echo "Generating reference color images into folder '$IMAGE_OUTPUT_DIR'..."
    echo "---------------"

    mkdir -p $IMAGE_OUTPUT_DIR

    for i in {1..4}; do
        COLOR=${COLOR_REFERENCE[$i]}
        IMAGE_OUT=$IMAGE_OUTPUT_DIR/$(printf "%s.$IMAGE_TYPE" $COLOR)

        echo " - color: '$COLOR'"

        cmd="$IM_CONVERT -size $COLOR_SQUARE_SIZE xc:$COLOR $COLOR_DEPTH$IMAGE_OUT"
        #echo $cmd
        eval $cmd
    done
}


##
# Creates folders with file symlinks for color reference comparison.
#
# Current order:
#       Top     Bottom
#   1:  A/B     A/C
#   2:  B/A     B/C
#   3:  A/B     A/D
#   4:  B/A     B/D
##
function generate_color_reference_links
{
    local IMAGE_INPUT_DIR=$1
    local IMAGE_OUTPUT_DIR=$2

    echo ""
    echo "---------------"
    echo "Creating color square reference links from '$IMAGE_INPUT_DIR' to '$IMAGE_OUTPUT_DIR'..."
    echo "---------------"

    mkdir -p $IMAGE_OUTPUT_DIR

    local LINK_CMD="cp -v"  # regular copy
    #local LINK_CMD="ln -sf"   # symlink

    local COLOR_OUT_MASK="$IMAGE_OUTPUT_DIR/$FRAME_DIR_MASK/%s"

    local COLOR_TOP_UP=$(printf $COLOR_SQUARE_MASK $FIELD_TOP $FIELD_TOP)
    local COLOR_TOP_LOW=$(printf $COLOR_SQUARE_MASK $FIELD_TOP $FIELD_BOTTOM)
    local COLOR_BOTTOM_UP=$(printf $COLOR_SQUARE_MASK $FIELD_BOTTOM $FIELD_TOP)
    local COLOR_BOTTOM_LOW=$(printf $COLOR_SQUARE_MASK $FIELD_BOTTOM $FIELD_BOTTOM)

    for i in {1..4}; do
        COLOR_REFERENCE_FILE[$i]=$IMAGE_INPUT_DIR/$(printf "%s.$IMAGE_TYPE" ${COLOR_REFERENCE[$i]})
    done

    # --------------------------
    FRAME_INDEX=1

    T_UP=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_TOP_UP)
    T_LOW=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_TOP_LOW)
    B_UP=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_BOTTOM_UP)
    B_LOW=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_BOTTOM_LOW)

    mkdir -p `dirname $T_UP`
    $LINK_CMD ${COLOR_REFERENCE_FILE[1]} $T_UP
    $LINK_CMD ${COLOR_REFERENCE_FILE[2]} $T_LOW
    $LINK_CMD ${COLOR_REFERENCE_FILE[1]} $B_UP
    $LINK_CMD ${COLOR_REFERENCE_FILE[3]} $B_LOW
    # --------------------------
    FRAME_INDEX=2

    T_UP=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_TOP_UP)
    T_LOW=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_TOP_LOW)
    B_UP=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_BOTTOM_UP)
    B_LOW=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_BOTTOM_LOW)

    mkdir -p `dirname $T_UP`
    $LINK_CMD ${COLOR_REFERENCE_FILE[2]} $T_UP
    $LINK_CMD ${COLOR_REFERENCE_FILE[1]} $T_LOW
    $LINK_CMD ${COLOR_REFERENCE_FILE[2]} $B_UP
    $LINK_CMD ${COLOR_REFERENCE_FILE[3]} $B_LOW
    # --------------------------
    FRAME_INDEX=3

    T_UP=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_TOP_UP)
    T_LOW=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_TOP_LOW)
    B_UP=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_BOTTOM_UP)
    B_LOW=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_BOTTOM_LOW)

    mkdir -p `dirname $T_UP`
    $LINK_CMD ${COLOR_REFERENCE_FILE[1]} $T_UP
    $LINK_CMD ${COLOR_REFERENCE_FILE[2]} $T_LOW
    $LINK_CMD ${COLOR_REFERENCE_FILE[1]} $B_UP
    $LINK_CMD ${COLOR_REFERENCE_FILE[4]} $B_LOW
    # --------------------------
    FRAME_INDEX=4

    T_UP=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_TOP_UP)
    T_LOW=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_TOP_LOW)
    B_UP=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_BOTTOM_UP)
    B_LOW=$(printf $COLOR_OUT_MASK $FRAME_INDEX $COLOR_BOTTOM_LOW)

    mkdir -p `dirname $T_UP`
    $LINK_CMD ${COLOR_REFERENCE_FILE[2]} $T_UP
    $LINK_CMD ${COLOR_REFERENCE_FILE[1]} $T_LOW
    $LINK_CMD ${COLOR_REFERENCE_FILE[2]} $B_UP
    $LINK_CMD ${COLOR_REFERENCE_FILE[4]} $B_LOW
    # --------------------------
}



function generate_interlaced_rectangles_
{
    local IMAGE_OUTPUT_DIR=$1

    echo ""
    echo "---------------"
    echo "Generating interlaced color rectangles into folder '$IMAGE_OUTPUT_DIR'..."
    echo "---------------"

    mkdir -p $IMAGE_OUTPUT_DIR

    for i in {1..4}; do
        echo "Not implemented, yet. :("
    done
}


function generate_color_bars
{
    local IMAGE_OUTPUT_DIR=$1
    local IMAGE_OUT=$IMAGE_OUTPUT_DIR/$COLORBAR_MASK

    echo ""
    echo "---------------"
    echo "Generating colorbars as '$IMAGE_OUT'..."
    echo "---------------"

    mkdir -p $IMAGE_OUTPUT_DIR
    
    for i in {1..7}; do
        COLOR=${COLOR_BAR[$i]}
        echo " - color: '$COLOR'"

        # TODO: Write color value into color bars:
        #COLORS="$COLORS xc:$COLOR -annotate +0+10 '$COLOR' +append"
        COLORS="$COLORS xc:$COLOR"
    done

    cmd="$IM_CONVERT -size $COLOR_BAR_SIZE -gravity South -fill white -undercolor '#0009' -pointsize 20 $COLORS +append $IMAGE_OUT"
    #echo $cmd #DEBUG
    eval $cmd
}


function generate_signal_placeholder_image
{
    local IMAGE_OUTPUT_DIR=$1
    local IMAGE_OUT=$IMAGE_OUTPUT_DIR/$SIGNAL_PLACEHOLDER
    local IMAGE_SOURCE_DIR=$BASE_DIR/$IMAGE_SOURCE_DIR
    local LOGO_IMAGE=$IMAGE_SOURCE_DIR/$LOGO_IMAGE

    local OFFSET_X="+50"
    local COLOR_BACKGROUND="#3c5f7f"
    local COLOR_DEPTH="PNG24:"

    cmd="$IM_CONVERT -size $VIDEO_SIZE xc:'$COLOR_BACKGROUND' -font 'Nimbus-Sans-Bold' -pointsize 62 -fill white -gravity Center -annotate +0+0 'No valid signal' -gravity SouthEast -fill '#143c5d' -pointsize 24 -annotate $OFFSET_X+74 'DVA Profession' $LOGO_IMAGE -geometry 276x200$OFFSET_X-120 -composite $COLOR_DEPTH$IMAGE_OUT"
    echo $cmd #DEBUG
    eval $cmd
}


function generate_static_frames
{
    local IMAGE_INPUT_DIR=$1
    local IMAGE_OUTPUT_DIR=$2
    local BACKGROUND_IMAGE=$3
    local IMAGE_SOURCE_DIR=$BASE_DIR/$IMAGE_SOURCE_DIR
    local LOGO_IMAGE=$IMAGE_SOURCE_DIR/$LOGO_IMAGE

    local COLOR_BAR_IMAGE=$IMAGE_INPUT_DIR/$COLORBAR_MASK
    local TEMP_IMAGE="$IMAGE_OUTPUT_DIR/temp.$IMAGE_TYPE"
    local TEMP_IMAGE2="$IMAGE_OUTPUT_DIR/temp2.$IMAGE_TYPE"

    echo ""
    echo "---------------"
    echo "Generating static background frames into folder '$IMAGE_OUTPUT_DIR'..."
    echo "---------------"

    mkdir -p $IMAGE_OUTPUT_DIR

    # embed color bars:
    cmd="$IM_COMPOSITE -gravity South $COLOR_BAR_IMAGE $BACKGROUND_IMAGE $TEMP_IMAGE"
    #echo $cmd
    eval $cmd

    # embed Mediathek OEM Logo:
    cmd="$IM_COMPOSITE -gravity South -geometry 276x200+0+70 $LOGO_IMAGE $TEMP_IMAGE $TEMP_IMAGE2"
    eval $cmd

    # embed DVA Profession logo:
    cmd="$IM_CONVERT $TEMP_IMAGE2 -font 'Nimbus-Sans-Bold' -fill '#0009' -pointsize 62 -gravity South -annotate -2+90 'DVA Profession' $TEMP_IMAGE"
    #echo $cmd
    eval $cmd

    for i in $(seq 1 $FRAME_COUNT); do
        RECTANGLE_IMAGE=$IMAGE_SOURCE_DIR/$(printf $RECTANGLE_MASK $i)
        FRAME_IMAGE=$IMAGE_OUTPUT_DIR/$(printf $FRAME_MASK $i)

        echo " - frame $i..."

        # embed rectangle:
        cmd="$IM_COMPOSITE -geometry $RECTANGLE_POSITION $RECTANGLE_IMAGE $TEMP_IMAGE $FRAME_IMAGE"
        #echo $cmd
        eval $cmd
    done

    rm $TEMP_IMAGE
    rm $TEMP_IMAGE2
}


function get_timecode_string
{
    local FRAME_POSITION=$1
    local FPS=$2

    # Convert frame position to hours, minutes, seconds, frames:
    local SECONDS=$(($FRAME_POSITION / $FPS))           # seconds
    local MINUTES=$(($SECONDS / 60))
    local HOURS=$(($MINUTES / 60))

    # Split each time unit, by using modulo (%):
    local HOUR=$(($HOURS % 60))
    local MINUTE=$(($MINUTES % 60))
    local SECOND=$(($SECONDS % 60))
    local FRAME=$(($FRAME_POSITION % $FPS))

    local TIMECODE_STRING=$(printf "$TIMECODE_MASK" $HOUR $MINUTE $SECOND $FRAME)
    echo $TIMECODE_STRING
}


function generate_testvideo_frames
{
    local FRAME_DURATION=$1
    local IMAGE_INPUT_DIR=$2
    local IMAGE_OUTPUT_DIR=$3
    local COLOR_DEPTH="PNG24:"

    DURATION="$(get_timecode_string $FRAME_DURATION $FPS)"

    echo ""
    echo "---------------"
    echo "Generating test frames as images - duration: $DURATION (=$FRAME_DURATION frames)"
    echo "  Output folder: $IMAGE_OUTPUT_DIR"
    echo "---------------"

    mkdir -p $IMAGE_OUTPUT_DIR
    
    for frame_position in $(seq 0 $(($FRAME_DURATION -1))); do
        INDEX=$(($(($frame_position % $FRAME_COUNT)) +1))
        
        TIMECODE_STRING="$(get_timecode_string $frame_position $FPS)"
        echo -n "$TIMECODE_STRING ($frame_position / $INDEX): "
        FRAME_IMAGE_IN=$IMAGE_INPUT_DIR/$(printf $FRAME_MASK $INDEX)
        FRAME_IMAGE_OUT=$IMAGE_OUTPUT_DIR/$(printf $FRAME_MASK $frame_position)

        # Skip existing frames to avoid unnecessary re-computation.
        # If frames should be re-generated, just delete them first. ;)
        if [ -s $FRAME_IMAGE_OUT ]; then
            echo "."
            continue
        fi

        cmd="$IM_CONVERT $FRAME_IMAGE_IN -font 'Nimbus-Mono-Bold' -fill white -undercolor '#000f' -pointsize 42 -gravity south -annotate $TIMECODE_POSITION '$TIMECODE_STRING' $COLOR_DEPTH$FRAME_IMAGE_OUT"
        #echo $cmd
        eval $cmd

        echo "ok"
    done
}


function convert_images_to_video
{
    local IMAGE_INPUT_DIR=$1
    local VIDEO_OUT=$2

    echo ""
    echo "---------------"
    echo "Converting frames in '$IMAGE_INPUT_DIR' to video '$VIDEO_OUT'..."
    echo "---------------"

    local TITLE=$(printf "DVA Profession Test-Video (v%s)" $TESTVIDEO_VERSION)
    local METADATA="-metadata title='$TITLE' -metadata ICRD='$TIMESTAMP_ISO' -metadata ITCH='Österreichische Mediathek'"

    cmd="$FFMPEG -r $FPS -i $IMAGE_INPUT_DIR/$FRAME_MASK -an -vcodec $TESTVIDEO_VCODEC -pix_fmt $TESTVIDEO_COLORSPACE $METADATA $VIDEO_OUT"
    echo $cmd
    eval $cmd
}


function generate_testvideo
{
    local WORKING_DIR=$1
    local DURATION=$2
    local OUTPUT_PATH=$3

    local VIDEO_OUT=$OUTPUT_PATH/$(printf $TESTVIDEO_MASK $TESTVIDEO_VCODEC $TESTVIDEO_COLORSPACE $DURATION $FPS)
    local IMAGE_OUTPUT_DIR="$OUTPUT_PATH/generated_frames"

    log_message "Started generating testvideo: $(date)"

    MESSAGE="
---------------
Generating testvideo:
  Filename:           $VIDEO_OUT
  Duration:           $(get_timecode_string $DURATION $FPS) ($DURATION frames)
  FPS:                $FPS

  working dir:        $WORKING_DIR
  color reference:    $COLOR_REFERENCE_DIR
---------------
"
    log_message "$MESSAGE"

    mkdir -p $OUTPUT_PATH
    #cd $WORKING_DIR

    generate_testvideo_frames $DURATION $BASE_DIR/$COLOR_REFERENCE_DIR $IMAGE_OUTPUT_DIR
    convert_images_to_video $IMAGE_OUTPUT_DIR $VIDEO_OUT

    log_message "Finished generating testvideo: $(date)"
}


# ----------------------------------------------[ EVALUATING VIDEO ]

function extract_frames
{
    local VIDEO_IN="$1"
    local IMAGE_OUTPUT_DIR="$2"

    if [ -d $IMAGE_OUTPUT_DIR ]; then
        echo ""
        echo "WARNING: Frame output folder '$IMAGE_OUTPUT_DIR' already exists."
        echo "         Delete it manually to re-extract frames."
        echo ""
        return 1
    fi

    echo ""
    echo "---------------"
    echo "Extracting full-frame images from $VIDEO_IN to $IMAGE_OUTPUT_DIR..."
    echo "---------------"

    mkdir -p $IMAGE_OUTPUT_DIR
    
    #NOCROP: cmd="$FFMPEG -i $VIDEO_IN -an -pix_fmt rgb24 -f image2 $IMAGE_OUTPUT_DIR/$FRAME_MASK"
    cmd="$FFMPEG -i '$VIDEO_IN' -vf crop=$CROP_RECTANGLE -an -pix_fmt rgb24 -f image2 $IMAGE_OUTPUT_DIR/$FRAME_MASK"
    echo $cmd
    eval $cmd
}


function split_frame_to_fields
{
    local FRAME_IMAGE=$1
    local IMAGE_OUTPUT_DIR=$2
    local COLOR_DEPTH="PNG8:"

    #echo "---------------"
    #echo "Splitting frame '$FRAME_IMAGE' into top/bottom fields..."
    #echo "---------------"
    mkdir -p $IMAGE_OUTPUT_DIR

    #BASENAME=$(basename $FRAME_IMAGE ".$IMAGE_TYPE")
    #FIELD_NAME_TOP=$IMAGE_OUTPUT_DIR/$(printf $FIELD_MASK $BASENAME $FIELD_TOP)
    #FIELD_NAME_BOTTOM=$IMAGE_OUTPUT_DIR/$(printf $FIELD_MASK $BASENAME $FIELD_BOTTOM)

    FIELD_NAME_TOP=$IMAGE_OUTPUT_DIR/$(printf $FIELD_MASK $FIELD_TOP)
    FIELD_NAME_BOTTOM=$IMAGE_OUTPUT_DIR/$(printf $FIELD_MASK $FIELD_BOTTOM)

    cmd="$IM_CONVERT $FRAME_IMAGE -roll +0+1 -sample 100%x50% $COLOR_DEPTH$FIELD_NAME_TOP"
    #echo $cmd
    eval $cmd

    cmd="$IM_CONVERT $FRAME_IMAGE -sample 100%x50% $COLOR_DEPTH$FIELD_NAME_BOTTOM"
    #echo $cmd
    eval $cmd
}


function extract_color_squares
{
    FIELD_IMAGE=$1
    IMAGE_OUTPUT_DIR=$2
    PREFIX=$3

    #COLOR_DEPTH="-colors 2 PNG8:"
    COLOR_DEPTH="PNG24:"
    
    #echo "---------------"
    #echo "Extracting color squares from '$FIELD_IMAGE'..."
    #echo "---------------"

    mkdir -p $IMAGE_OUTPUT_DIR

    BASENAME=$(basename $FIELD_IMAGE ".$IMAGE_TYPE")

    SQUARE_NAME_TOP=$IMAGE_OUTPUT_DIR/$(printf $COLOR_SQUARE_MASK $PREFIX $FIELD_TOP)
    SQUARE_NAME_BOTTOM=$IMAGE_OUTPUT_DIR/$(printf $COLOR_SQUARE_MASK $PREFIX $FIELD_BOTTOM)

    # ------ Upper color:
    cmd="$IM_CONVERT $FIELD_IMAGE -gravity North -crop $COLOR_SQUARE_SIZE+0+0 +repage $COLOR_DEPTH$SQUARE_NAME_TOP"
    #echo $cmd
    eval $cmd

    # ------ Lower color:
    cmd="$IM_CONVERT $FIELD_IMAGE -gravity South -crop $COLOR_SQUARE_SIZE+0+0 +repage $COLOR_DEPTH$SQUARE_NAME_BOTTOM"
    #echo $cmd
    eval $cmd
}


##
# IMPORTANT: This function *must not* produce any output other than the comparison result value.
##
function verify_color_squares
{
    # TODO:
    # - Compare with a given testframe (1..4)
    # - if it does NOT match:
    #   - log video error

    local IMAGE_INPUT_DIR="$1"
    local REFERENCE_DIR="$2"
    local REFERENCE_FRAME_INDEX="$3"

    local DIFF_IMAGE="/dev/null"
    local REFERENCE="$REFERENCE_DIR/$(printf $FRAME_DIR_MASK $REFERENCE_FRAME_INDEX)"

    for color_square_reference in $REFERENCE/*.$IMAGE_TYPE; do
        local BASENAME=$(basename $color_square_reference)
        local REFERENCE=$color_square_reference
        local FROM_VIDEO="$IMAGE_INPUT_DIR/$BASENAME"

        cmd="$IM_COMPARE -metric $COMPARE_METRIC -fuzz $COMPARE_FUZZ% $FROM_VIDEO $REFERENCE $DIFF_IMAGE"
        #echo $cmd

        # redirect stderr to stdout an stdout to /dev/null:
        RESULT=$(eval $cmd 2>&1 >/dev/null)

        if [ $RESULT -gt 0 ]; then
            #MASK="   ! ERROR (%d) at: %s\n\n"
            #printf "$MASK" $RESULT $(basename $FROM_VIDEO)
            #log_message_silent "Rectangle failed: $BASENAME"

            echo $RESULT  # This is the number of pixels that differ
            return $RETURN_ERROR
        fi
    done
    echo $RETURN_OK
    return $RETURN_OK
}


function calibrate_color_squares
{
    local IMAGE_INPUT_DIR=$1
    local REFERENCE_DIR=$2

    local DIFF_IMAGE="/dev/null"
    local PAUSE=1

    echo "Metric: $COMPARE_METRIC"

    while (true); do
        local ERROR=0 # start fresh

        for color_square in $IMAGE_INPUT_DIR/#*.$IMAGE_TYPE; do
            echo "Current fuzz factor: $COMPARE_FUZZ%"

            local BASENAME=$(basename $color_square)
            local REFERENCE=$REFERENCE_DIR/$BASENAME
            local FROM_VIDEO=$color_square


            cmd="$IM_COMPARE -metric $COMPARE_METRIC -fuzz $COMPARE_FUZZ% $FROM_VIDEO $REFERENCE $DIFF_IMAGE"
            #echo $cmd
            RESULT=$(eval $cmd 2>&1 >/dev/null)
            echo -n "   $RESULT Different pixels in '$BASENAME' ---    "

            if [ $RESULT -gt 0 ]; then
                # Slowly increase fuzz until no error appears
                (( COMPARE_FUZZ++ ))
                (( ERROR++ ))

                echo "Error #$ERROR. Increasing fuzz to $COMPARE_FUZZ..."

                echo "Pausing for $PAUSE seconds..."
                sleep $PAUSE
                continue
            else
                # We might have found a good fuzz factor?
                echo "ok"
            fi
        done
        
        echo "Errors: $ERROR"
        echo ""
        if [ $ERROR -eq 0 ]; then
            break;
        fi
    done

    echo ""
    echo "-------------"
    echo "Useful fuzz factor: $COMPARE_FUZZ"
    echo "-------------"
    echo ""
}


function check_frames
{
    local WORKING_DIR=$1
    local FRAME_POSITION=$2
    local REFERENCE_INDEX=1

    if [ -z $FRAME_POSITION ]; then
        FRAME_POSITION=1    # default is to start at frame 1
    fi

    cd $WORKING_DIR
    #local FRAMES_DIR=$FRAMES_DIR
    #local FIELDS_DIR=$FIELDS_DIR
    
    # Sync mode: find entry frame that correlates with reference frame 1
    local SYNC_MODE=true
    local ERROR=false
    
    log_message "=== Started: $(date) ==="
    log_message "Running field rectangle check at frame #$FRAME_POSITION"
    log_message "Fuzz factor: $COMPARE_FUZZ"
    log_message "Looking for sync frame #$REFERENCE_INDEX..."

    while (true); do
        FRAME_IMAGE=$FRAMES_DIR/$(printf $FRAME_MASK $FRAME_POSITION)

        # If the expected frame does *not* exist, quit:
        if [ ! -f $FRAME_IMAGE ]; then
            LOG_MSG="   Frame #$FRAME_POSITION: file '$FRAME_IMAGE' not found. Exiting."
            echo ""
            log_message "$LOG_MSG"
            echo ""
            break
        fi

        BASENAME=$(basename $FRAME_IMAGE ".$IMAGE_TYPE")
        REFERENCE_INDEX=$((($REFERENCE_INDEX -1) % $FRAME_COUNT +1))

        MESSAGE=$(printf "checking frame '%s' - %06d (%02d)" $(basename $FRAME_IMAGE) $FRAME_POSITION $REFERENCE_INDEX)
        echo -n "$MESSAGE...   "
        

        # Sync-start:
        #   1) extract fields
        #   2) extract the color squares from fields
        #   3) compare color squares to reference files
        #   4) *if* comparision matches testframe #1: start error comparison
        #   ----
        #   5) repeat 1-3 until error is found
        #   6) if error is found: re-sync to testframe #1

        split_frame_to_fields $FRAME_IMAGE $FIELDS_DIR

        extract_color_squares $FIELDS_DIR/$(printf $FIELD_MASK $FIELD_TOP) $COLOR_SQUARE_DIR $FIELD_TOP
        extract_color_squares $FIELDS_DIR/$(printf $FIELD_MASK $FIELD_BOTTOM) $COLOR_SQUARE_DIR $FIELD_BOTTOM

        #echo -n "Comparing frame #$FRAME_POSITION with reference #$REFERENCE_INDEX ...    "
        RESULT=$(verify_color_squares $COLOR_SQUARE_DIR $BASE_DIR/$COLOR_REFERENCE_DIR $REFERENCE_INDEX)

        if [ $RESULT -eq $RETURN_OK ]; then
            echo "ok"
            ERROR=false

            if [ $SYNC_MODE == true ]; then
                LOG_MSG="=== Synchronization successful! ($FRAME_POSITION = $REFERENCE_INDEX)"
                echo ""
                log_message "$LOG_MSG"
                echo ""

                SYNC_MODE=false
            fi
        else
            echo "failed"
            LOG_MSG="   Frame #$FRAME_POSITION: Error ($RESULT) found. Reference frame #$REFERENCE_INDEX."

            if [ $SYNC_MODE == true ]; then
                echo "Sync: no match at $FRAME_POSITION (diff: $RESULT)"
            else
                # If we've had an error in a previous frame, too - resync!
                if [ $ERROR == true ]; then
                    SYNC_MODE=true
                fi
                # Only log errors if we're synchronized...
                log_message "$LOG_MSG"
                ERROR=true
            fi

            #echo "waiting..." && sleep 2 #DELME DEBUG
        fi

        (( FRAME_POSITION++ ))
        (( REFERENCE_INDEX++ ))
        if [ $SYNC_MODE == true ]; then
            REFERENCE_INDEX=1   # Force check with reference #1.
            echo "...sync mode ON (looking for reference frame #$REFERENCE_INDEX"
            echo ""
            #echo "waiting..." && sleep 1 #DELME DEBUG
        fi

    done

    log_message "=== Finished: $(date) ==="
    log_message "Analyzed $(($FRAME_POSITION -1)) frames"
}




# ----------------------------------------------
case "$1" in
    generate_reference)
        IMAGE_OUTPUT_DIR=$BASE_DIR/$COLOR_REFERENCE_DIR
        LOG_FILE="$IMAGE_OUTPUT_DIR/$LOG_FILE"
        start_logfile 

        # Infrastructure:
        generate_color_reference_images $IMAGE_OUTPUT_DIR
        generate_color_reference_links $IMAGE_OUTPUT_DIR $IMAGE_OUTPUT_DIR
        generate_color_bars $IMAGE_OUTPUT_DIR
        #generate_static_frames $IMAGE_OUTPUT_DIR $IMAGE_OUTPUT_DIR "$BASE_DIR/$IMAGE_SOURCE_DIR/$BACKGROUND_IMAGE"
    ;;

    generate)
        #DURATION=$((60 * 60 * $FPS))    # 1 hour
        DURATION="$2"
        OUTPUT_PATH="$3"
        REFERENCE_DIR="$BASE_DIR/$COLOR_REFERENCE_DIR"
        LOG_FILE="$OUTPUT_PATH/$LOG_FILE"
        start_logfile 

        if [ -z $OUTPUT_PATH ]; then
            write_error "No output path for video given."
            exit $RETURN_ERROR
        fi

        # Test-Video:
        generate_static_frames $REFERENCE_DIR $REFERENCE_DIR "$BASE_DIR/$IMAGE_SOURCE_DIR/$BACKGROUND_IMAGE"
        generate_testvideo $BASE_DIR $DURATION $OUTPUT_PATH
    ;;

    calibrate_colors)
        IMAGE_INPUT_DIR="$2"
        REFERENCE_DIR="$BASE_DIR/$COLOR_REFERENCE_DIR"

        if [ -z $IMAGE_INPUT_DIR ]; then
            write_error "No image path with color square from video given."
            exit $RETURN_ERROR
        fi

        calibrate_color_squares $IMAGE_INPUT_DIR $REFERENCE_DIR
    ;;

    run_test)
        BASE_DIR=$(readlink -f "$2")
        VIDEO_IN="$3"
        FRAME_POSITION="$4"
        DURATION="$5"                                   # not used yet.
        RESUME="$6"                                     # use frames from previous extraction (saves time)
        OUTPUT_PATH="$BASE_DIR/$FROM_VIDEO_DIR"
        REFERENCE_DIR="$BASE_DIR/$COLOR_REFERENCE_DIR"
        #LOG_FILE="$OUTPUT_PATH/$(basename $VIDEO_IN).log"
        LOG_FILE="$BASE_DIR/$(basename $VIDEO_IN).log"
        OUTPUT_FRAMES_DIR="$OUTPUT_PATH/$FRAMES_DIR"

        start_logfile 

        if [ -z $VIDEO_IN ]; then
            write_error "No input video filename provided."
            exit $RETURN_ERROR
        fi

        if [ ! -d $REFERENCE_DIR ]; then
            write_error "Color reference folder missing: $REFERENCE_DIR"
            exit $RETURN_ERROR
        fi

        mkdir -p $OUTPUT_PATH
        #cd $WORKING_DIR

        log_message "Running DVA Profession Video Test on '$(basename $VIDEO_IN)'..."

        echo ""
        echo " Video IN:       $VIDEO_IN"
        echo " Base directory: $BASE_DIR"
        echo " Frame position: $FRAME_POSITION"
        echo " Output path:    $OUTPUT_PATH"
        echo " Logfile:        $LOG_FILE"
        echo ""
        echo " Resume:         '$RESUME'"
        echo ""
        pause 15

        if [[ -z "$RESUME" && -d "$OUTPUT_FRAMES_DIR" ]]; then
            echo "                 Deleting leftovers:"
            echo "                  - '$OUTPUT_FRAMES_DIR'"
            pause 2
            rm -rv "$OUTPUT_FRAMES_DIR"
        fi


        extract_frames $VIDEO_IN $OUTPUT_FRAMES_DIR
        check_frames $OUTPUT_PATH $FRAME_POSITION
    ;;

    signal_placeholder)
        DURATION="$2"
        OUTPUT_PATH="$3"

        generate_signal_placeholder_image $OUTPUT_PATH
    ;;

    *)
        echo ""
        echo "SYNTAX: `basename $0` (generate_reference | generate | run_test | calibrate_colors) ..."
        echo ""
        echo "  *) Generate reference files:"
        echo "     $0 generate_reference"
        echo ""
        echo "  *) Generate test-video:"
        echo "     $0 generate DURATION OUTPUT_PATH"
        echo ""
        echo "  *) Verify recorded test-video:"
        echo "     $0 run_test BASE_DIR VIDEO_IN [FRAME_POSITION] [DURATION] [RESUME]"
        echo "     FRAME_POSITION:  Start at frame-offset <FRAME_POSITION> (must be >= 1)"
        echo "     DURATION:        is not implemented yet!"
        echo "     RESUME:          if 'true', data from previous run will be used to save time" 
        echo ""
        echo "  *) Calibrate fuzz value, by using color squares from video source:"
        echo "     $0 calibrate_colors IMAGE_PATH"
        echo ""
        echo "  *) Generate placeholder video for invalid signals:"
        echo "     $0 signal_placeholder DURATION OUTPUT_PATH"
        echo ""
    ;;
esac

