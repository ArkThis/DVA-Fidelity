================================
  DVA Fidelity Analyzer 
================================

  Version: v0.1
  Date:    August 13th, 2012

================================

1) The "Fidelity_Analyzer" folder on "storage" must be symlinked here in order for the DVA-Fidelity analyzer to work.

  "storage -> /mnt/video_archive/part2/DVA-Profession/Fidelity_Analyzer"


2) A patched version of ffmpeg is required for this analyzer to function correctly.
The reason for this is a YUV-to-RGB conversion issue with subsampled material.
See FFmpeg ticket #143 for details:

    http://ffmpeg.org/trac/ffmpeg/ticket/143

The patch file is called "yuv422p_to_rgb.patch".
A copy is located in this folder, as well as attached to the above bug ticket:

     http://ffmpeg.org/trac/ffmpeg/attachment/ticket/143/yuv422p_to_rgb.patch

The patch was written for FFmpeg version from SVN, revision 32669


