#!/bin/bash
# @author: Peter Bubestinger
# @date:   08.Sep.2013
# @description:
#   Generates the audio, used for the DVA-Fidelity analyzer.
#   The duration of the generated audio track is given as 
#   parameter in minutes.
#
# @history:
#   peter_b     02.DEZ.2013     - Added additional audio track for longitudinal-track tests.
#   peter_b     17.OCT.2013     - Added duration as commandline argument.
#   peter_b     09.SEP.2013     - Changed continuous frequencies to less "annoying".
#                               - Added blip gain values.
#                               - Added generating the complete, final duration.
#                               - Changed final output format to FLAC (to avoid 2GB WAV limit)
#   peter_b     08.SEP.2013     - Started.
#                               - Added generating continuous tones.
#                               - Added generating 2 different sync "blips".

function show_syntax
{
    echo ""
    echo "SYNTAX:"
    echo " $0 <output_dir> <duration_mins>"
    echo ""
}

DIR_OUTPUT="$1"
if [ ! -d "$DIR_OUTPUT" ]; then
    echo "ERROR: Please specify output directory"
    show_syntax
    exit 1
fi

DURATION_MINS="$2"
if [ ! $DURATION_MINS -gt 0 ]; then
    echo "ERROR: Please provide duration parameter (in full minutes)"
    show_syntax
    exit 1
fi


SAMPLERATE=48000

GAIN_DB_CONT="-6"
GAIN_DB_BLIP_1="-1"
GAIN_DB_BLIP_2="-2"

# LO/HI for main stereo track:
FREQ_LO=200
FREQ_HI=1000
# LO/HI for alternative, longitudinal track:
FREQ_LO2=400
FREQ_HI2=2000
# Audio blips for A/V synchronicity check:
FREQ_BLIP_1=880
FREQ_BLIP_2=440

FILE_TEMP="$DIR_OUTPUT/temp.wav"
FILE_CONTINUOUS="$DIR_OUTPUT/continuous.wav"
FILE_BLIP_1="$DIR_OUTPUT/sync_blip_1.wav"
FILE_BLIP_2="$DIR_OUTPUT/sync_blip_2.wav"

FILE_FINAL_1="$DIR_OUTPUT/final_1.wav"
FILE_FINAL_2="$DIR_OUTPUT/final_2.wav"

# Final output files:
FILE_FINAL="$DIR_OUTPUT/dva-fidelity-${DURATION_MINS}m.flac"
FILE_FINAL_B="$DIR_OUTPUT/dva-fidelity-${DURATION_MINS}m-longitudinal.flac"

DURATION_BLIP="0.04"        # Duration of sync blip. 1 frame PAL = 1/25 = 0.04s
BLIP_FADE="0.001"           # Duration of fade in/out of sync blip tone (=to avoid clicks)
TONE_FADE="0.001"           # Duration of fade in/out of sync blip tone (=to avoid clicks)
#BLIP_PAD=$(echo "1.0 - $DURATION_BLIP" | bc)


echo ""
echo "Generate continous tones:"
echo " low:  $FREQ_LO Hz"
echo " high: $FREQ_LO Hz"
# Generate a continuous tone with FREQ_LO in left, and FREQ_HI in right channel:
sox -r $SAMPLERATE -n $FILE_CONTINUOUS synth 1 sine $FREQ_LO sine $FREQ_HI gain $GAIN_DB_CONT fade $TONE_FADE 1 $TONE_FADE
echo "Done."


echo ""
echo -n "Generate sync blip 1 ($FREQ_BLIP_1 Hz):"
# Generate sync blip 1:
sox -r $SAMPLERATE -n $FILE_TEMP synth $DURATION_BLIP sine $FREQ_BLIP_1 gain $GAIN_DB_BLIP_1 fade q $BLIP_FADE $DURATION_BLIP $BLIP_FADE
# Merge sync-blip into stereo file - but with inverted phase per channel:
sox -M $FILE_TEMP -v -1 $FILE_TEMP $FILE_BLIP_1
echo "Done."

echo ""
echo -n "Generate sync blip 1 ($FREQ_BLIP_2 Hz):"
# Generate sync blip 2:
sox -r $SAMPLERATE -n $FILE_TEMP synth $DURATION_BLIP sine $FREQ_BLIP_2 gain $GAIN_DB_BLIP_2 fade q $BLIP_FADE $DURATION_BLIP $BLIP_FADE
# Merge sync-blip into stereo file - but with inverted phase per channel:
sox -M $FILE_TEMP -v -1 $FILE_TEMP $FILE_BLIP_2
echo "Done."

echo -n "Append continuous tone to sync blips:"
# Append continuous tone to sync blips - and trim them to 1 second in total:
sox $FILE_BLIP_1 $FILE_CONTINUOUS $FILE_FINAL_1 trim 0 1
sox $FILE_BLIP_2 $FILE_CONTINUOUS $FILE_FINAL_2 trim 0 1 repeat 8
echo "Done."


echo "Append everything to final audio output: '$FILE_FINAL'"
echo "Duration: $DURATION_MINS minutes"
echo "This may take a while..."
# NOTE: The final file is compressed, to avoid problems with the 2GB WAV size boundary:
#       compression rate is "0 = worst = fastest"

# remove leftovers from previous runs
rm "$FILE_FINAL"    
rm "$FILE_FINAL_B"  

# Duration: 10s * 6 (=1min) * 240 (=4 hours) => repeat 10s * 1440:
echo "Generating main track..."
sox --show-progress $FILE_FINAL_1 $FILE_FINAL_2 -C 0 $FILE_FINAL repeat $((6 * $DURATION_MINS)) 
echo "Main track: Done."

echo "Generating alternative track..."
sox --show-progress -r $SAMPLERATE -n $FILE_FINAL_B synth $((60 * $DURATION_MINS)) sine $FREQ_LO2 sine $FREQ_HI2 gain $GAIN_DB_CONT
echo "Alternative track: Done."


# Remove temp files:
rm "$FILE_TEMP" "$FILE_CONTINUOUS" "$FILE_BLIP_1" "$FILE_BLIP_2" "$FILE_FINAL_1" "$FILE_FINAL_2"
