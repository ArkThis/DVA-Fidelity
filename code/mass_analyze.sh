#!/bin/bash
# @date: 21.Feb.2012
# @author: Peter Bubestinger
# @description:
#   This script runs the DVA-Fidelity analysis on all videos matching
#   a given filemask.
#   NOTE:   The "frames" folder will be deleted (!) after each video 
#           has been analyzed in order to avoid leftovers.
#           So, this "mass_analyze" script cannot be used for quick
#           re-runs of tests. Just that you know...


ACTION="$1"
BASE_DIR="$2"           # Generated analysis reports will be put in this folder, too.
VIDEOS_IN="$3"        # The mask for files to-analyze. May include the foldername.

FIDELITY_ANALYZER="./dva_fidelity.sh"

function pause
{
    PAUSE="$1"
    echo "Waiting $PAUSE seconds..."
    echo ""
    sleep $PAUSE
}

case "$ACTION" in
    run_test)
        echo "Videos to analyze: '$VIDEOS_IN'."
        pause 1

        for VIDEO_IN in $VIDEOS_IN; do
            LOG_FILE="$BASE_DIR/$(basename $VIDEO_IN).log"
            if [ -e $LOG_FILE ]; then
                echo "Logfile exists: '$LOG_FILE'."
                echo "Video already analyzed? Skipping: '$VIDEO_IN'"
                pause 3
                continue
            fi

            echo "Processing '$VIDEO_IN'..."
            $FIDELITY_ANALYZER run_test "$2" "$VIDEO_IN"
            pause 10
        done
    ;;

    *)
        echo ""
        echo "SYNTAX: `basename $0` (run_test) ..."
        echo ""
        echo "  *) Verify recorded test-videos:"
        echo "     $0 run_test BASE_DIR VIDEOS_IN"
        echo ""
        echo "     = EXAMPLE:"
        echo "     $0 run_test 'storage/DVA-Profession/analysis' '/media/usb-disk/*.avi'"
        echo ""
    ;;
esac
