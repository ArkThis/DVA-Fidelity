#!/bin/bash
# @author: Peter Bubestinger
# @date: June 17th 2011
# @description: 
#   - Exports frames from a video, extracts their fields and stores 
#     it as a 3-parted image (frame/top/bottom)

# @history:
#   pb  20.JUN.2011     - Added creation of fTB images
#                       - Added annotation of T/B field images
#   pb  17.JUN.2011     - Started.



# ------ Applications:
FFMPEG="/home/pb/install/ffmpeg/ffmpeg-git/ffmpeg"
IM_COMPOSITE="/usr/bin/composite"
IM_CONVERT="/usr/bin/convert"
IM_COMPARE="/usr/bin/compare"

# ------ Graphic / image information:
IMAGE_TYPE="png"
IMAGE_TYPE_FTB="jpg"
IMAGE_TYPE_THUMBNAIL="jpg"
FIELD_TOP='t'
FIELD_BOTTOM='b'

FRAME_WIDTH=720
FRAME_HEIGHT=576
FIELD_WIDTH=$(($FRAME_WIDTH / 2))
FIELD_HEIGHT=$(($FRAME_HEIGHT / 2))
THUMBNAIL_WIDTH=220
FONT_SIZE=150

# ------ Video information:
FIELD_TOP='t'
FIELD_BOTTOM='b'
FTB_BACKGROUND='white'

# ------ Filenames:
FRAME_INDEX_LENGTH=6
FRAME_DIR="frames"
FIELD_DIR="fields"
FTB_IMAGE_DIR="ftb"
THUMBNAIL_DIR="small"
FRAME_MASK="%06d.$IMAGE_TYPE"
FIELD_MASK="%s-%s.$IMAGE_TYPE"



function extract_frames
{
    VIDEO_IN="$1"
    OUTPUT_PATH="$2"

    IMAGE_OUT="$OUTPUT_PATH/$FRAME_MASK"
    mkdir -p $OUTPUT_PATH

    cmd="$FFMPEG -i '$VIDEO_IN' -f image2 '$IMAGE_OUT'"
    #echo "$cmd"
    eval $cmd
}


function split_frames_to_fields
{
    FRAME_DIR="$1"
    OUTPUT_PATH="$2"

    COLOR_DEPTH="PNG24"

    echo ""
    echo "Storing fields in folder '$OUTPUT_PATH'..."
    mkdir -p $OUTPUT_PATH

    for FRAME_IN in "$FRAME_DIR"/*.$IMAGE_TYPE; do
        NAME=$(basename $FRAME_IN)
        # The leftmost characters of the frame filename are the frame index number:
        INDEX=${NAME:0:$FRAME_INDEX_LENGTH}
        echo "  Frame-to-fields: $INDEX"

        FIELD_NAME_TOP="$OUTPUT_PATH/$(printf $FIELD_MASK $INDEX $FIELD_TOP)"
        FIELD_NAME_BOTTOM="$OUTPUT_PATH/$(printf $FIELD_MASK $INDEX $FIELD_BOTTOM)"

        cmd="$IM_CONVERT '$FRAME_IN' -roll +0+1 -sample 100%x50% '$COLOR_DEPTH:$FIELD_NAME_TOP'"
        #echo $cmd
        eval $cmd

        cmd="$IM_CONVERT '$FRAME_IN' -sample 100%x50% '$COLOR_DEPTH:$FIELD_NAME_BOTTOM'"
        #echo $cmd
        eval $cmd
    done
}


function frame_field_image
{
    FRAME_IN="$1"
    FIELDS_DIR="$2"
    OUTPUT_PATH="$3"
    IMAGE_TYPE_OUT="$4"

    echo ""
    echo "Creating fTB images in folder '$OUTPUT_PATH'..."
    mkdir -p $OUTPUT_PATH

    # The leftmost characters of the frame filename are the frame index number:
    NAME=$(basename $FRAME_IN)
    INDEX=${NAME:0:$FRAME_INDEX_LENGTH}

    echo "  fTB-Image: $INDEX"

    FIELD_NAME_TOP="$FIELDS_DIR/$(printf $FIELD_MASK $INDEX $FIELD_TOP)"
    FIELD_NAME_BOTTOM="$FIELDS_DIR/$(printf $FIELD_MASK $INDEX $FIELD_BOTTOM)"

    IMAGE_OUT="$OUTPUT_PATH/$INDEX-ftb.$IMAGE_TYPE_OUT"

    FIELD_POS_Y=$(($FRAME_HEIGHT +4))
    FIELD_POS_TOP="+0+$FIELD_POS_Y"
    FIELD_POS_BOTTOM="+$(($FRAME_WIDTH +8))+$FIELD_POS_Y"
    
    LABEL_POS_Y=$((($FIELD_HEIGHT / 2) - ($FONT_SIZE / 2)))
    LABEL_POS_TOP="-$(($FIELD_WIDTH / 2))+$LABEL_POS_Y"
    LABEL_POS_BOTTOM="+$(($FIELD_WIDTH / 2))+$LABEL_POS_Y"


    # Resize the field images to half-frame width, scale their height to normal aspect ratio
    # and append them at the bottom of the frame image:
    #cmd="convert $FRAME_IN -bordercolor '#FF0000' -border 2x2 \( $FIELD_NAME_TOP $FIELD_NAME_BOTTOM -resize $FIELD_WIDTH\!x$FIELD_HEIGHT\! +append \) -background $FTB_BACKGROUND -append $IMAGE_OUT"

    cmd="convert -page +2+0 $FRAME_IN \( -page $FIELD_POS_TOP $FIELD_NAME_TOP -page $FIELD_POS_BOTTOM $FIELD_NAME_BOTTOM -resize $FIELD_WIDTH\!x$FIELD_HEIGHT\! \) -background $FTB_BACKGROUND -mosaic $IMAGE_OUT"
    #echo "$cmd"
    eval $cmd

    # Label the top- and bottom-field images:
    cmd="convert $IMAGE_OUT -fill '#ffffff77' -pointsize $FONT_SIZE -gravity South -annotate $LABEL_POS_TOP 'T' -annotate $LABEL_POS_BOTTOM 'B' $IMAGE_OUT"
    eval $cmd
}


function create_thumbnails
{
    IMAGE_MASK="$1"
    OUTPUT_PATH="$2"
    IMAGE_TYPE_IN="$3"

    # Clean old leftovers:
    rm $OUTPUT_PATH/*.$IMAGE_TYPE_THUMBNAIL
    mkdir -p $OUTPUT_PATH

    echo "Downsizing all images matching '$IMAGE_MASK' ($IMAGE_TYPE_IN) to $THUMBNAIL_WIDTH..."
    
    for IMAGE_IN in $IMAGE_MASK; do
        IMAGE_OUT="$OUTPUT_PATH/$(basename $IMAGE_IN '.'$IMAGE_TYPE_IN).$IMAGE_TYPE_THUMBNAIL"
        
        echo "  thumbnail: $(basename $IMAGE_OUT)"

        cmd="convert $IMAGE_IN -resize $THUMBNAIL_WIDTH $IMAGE_OUT"
        #echo "$cmd"
        eval $cmd
    done
}


function create_ftb_images
{
    VIDEO_IN="$1"
    OUTPUT_DIR="$2"

    extract_frames "$VIDEO_IN" "$FRAMES_DIR"
    split_frames_to_fields "$FRAMES_DIR" "$FIELDS_DIR"

    for FRAME_IN in "$FRAMES_DIR"/*.$IMAGE_TYPE; do
        frame_field_image "$FRAME_IN" "$FIELDS_DIR" "$FTB_IMAGES_DIR" "$IMAGE_TYPE_FTB"
        #exit
    done

    #create_thumbnails "$FTB_IMAGES_DIR/*.$IMAGE_TYPE_FTB" "$THUMBNAILS_DIR" "$IMAGE_TYPE_THUMBNAIL"
}


function find_output_dir
{
    VIDEO_IN="$1"
    INDEX=1

    while [ true ]; do
        VIDEO_DIR=$(dirname $VIDEO_IN)
        OUTPUT_DIR="$VIDEO_DIR/images_$INDEX"
        if [ -d $OUTPUT_DIR ]; then
            echo "Output dir already exists: $OUTPUT_DIR"
            INDEX=$(($INDEX +1))
        else
            break;
        fi
    done

    echo "Using folder $OUTPUT_DIR"
    mkdir -p $OUTPUT_DIR
}



VIDEO_IN="$1"

find_output_dir "$VIDEO_IN"

FTB_IMAGES_DIR="$OUTPUT_DIR"
FRAMES_DIR="$OUTPUT_DIR/$FRAME_DIR"
FIELDS_DIR="$OUTPUT_DIR/$FIELD_DIR"
THUMBNAILS_DIR="$OUTPUT_DIR/$THUMBNAIL_DIR"

create_ftb_images "$VIDEO_IN" "$OUTPUT_DIR"
create_thumbnails "$OUTPUT_DIR/*.$IMAGE_TYPE_FTB" "$THUMBNAILS_DIR" "$IMAGE_TYPE_FTB"
