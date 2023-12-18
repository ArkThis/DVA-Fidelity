# DVA-Fidelity patchset for FFmpeg

The FFmpeg-patches were written by Georg Lippitsch, whom the Mediathek hired to
implement the functionality already existing in my shell-scripts directly in
FFmpeg.

The original patchset is from December 2013.

On 2019-04-02 I wrote Georg that I've managed to apply his patches to ffmpeg
v4.1 source.

Therefore, I'm using v4.0.6 here.
(because I could only find 4.0.x on FFmpeg release website, and the next higher
version is already v5)


# Applying the Patch

  1. Download ffmpeg v4.0.6

  2. `make patch`
     Or manually:

     `$ cd ffmpeg-build`

     `$ patch -i ../version_2/patches/dva_fidelity-ffmpeg_v4-20231216.patch -p 1`


# Show Options

This recipe outputs the options for the DVA-Fidelity muxer:

`$ ffmpeg-fidelity -h muxer=dvafidelity`


And should return this:

```
Muxer dvafidelity [DVA-Profession Fidelity Analyzer]:
    Default video codec: rawvideo.
DVA Fidelity Analyzer class AVOptions:
  -crop_upper_pos    <image_size> E........ Position of upper crop rectangle (default "593x95")
  -crop_upper_size   <image_size> E........ Size of upper crop rectangle (default "16x32")
  -crop_lower_pos    <image_size> E........ Position of lower crop rectangle (default "593x280")
  -crop_lower_size   <image_size> E........ Size of lower crop rectangle (default "16x32")
  -color_f1_up_top   <color>      E........ Color of frame 1, upper rectangle, top field (default "0xFF0000")
  -color_f1_up_bot   <color>      E........ Color of frame 1, upper rectangle, bottom field (default "0xFF0000")
  -color_f1_low_top  <color>      E........ Color of frame 1, lower rectangle, top field (default "0x00FF00")
  -color_f1_low_bot  <color>      E........ Color of frame 1, lower rectangle, bottom field (default "0x0000FF")
  -color_f2_up_top   <color>      E........ Color of frame 2, upper rectangle, top field (default "0x00FF00")
  -color_f2_up_bot   <color>      E........ Color of frame 2, upper rectangle, bottom field (default "0x00FF00")
  -color_f2_low_top  <color>      E........ Color of frame 2, lower rectangle, top field (default "0xFF0000")
  -color_f2_low_bot  <color>      E........ Color of frame 2, lower rectangle, bottom field (default "0x0000FF")
  -color_f3_up_top   <color>      E........ Color of frame 3, upper rectangle, top field (default "0xFF0000")
  -color_f3_up_bot   <color>      E........ Color of frame 3, upper rectangle, bottom field (default "0xFF0000")
  -color_f3_low_top  <color>      E........ Color of frame 3, lower rectangle, top field (default "0x00FF00")
  -color_f3_low_bot  <color>      E........ Color of frame 3, lower rectangle, bottom field (default "0xFFFFFF")
  -color_f4_up_top   <color>      E........ Color of frame 4, upper rectangle, top field (default "0x00FF00")
  -color_f4_up_bot   <color>      E........ Color of frame 4, upper rectangle, bottom field (default "0x00FF00")
  -color_f4_low_top  <color>      E........ Color of frame 4, lower rectangle, top field (default "0xFF0000")
  -color_f4_low_bot  <color>      E........ Color of frame 4, lower rectangle, bottom field (default "0xFFFFFF")
  -fuzz_luma         <int>        E........ Fuzz for luminance (from 0 to 100) (default 50)
  -fuzz_chroma       <int>        E........ Fuzz for chrominance (from 0 to 100) (default 50)
```

The default values in the code, match the generated DVA-Fidelity video out of the box.
They even contain headroom for image instability (eg "telecine-film") and chroma/luma fuzziness when comparing color matches.


# Example Recipes

`$ ffmpeg -i FIDELITY_RECORDING -fuzz_luma 70 -fuzz_chroma 70`

This sets both luminance and chrominance "fuzziness" when comparing the color values between recording and reference (red/green/blue/white).
The average of 50 for both is a sane default.
Use higher fuzziness values for "dirtier" recordings / signal chains.

Due to the demuxer being implemented in FFmpeg, it should be perfectly possible to do a live evaluation, connecting to a live (SDI) input from a DVA-Fidelity playback.

