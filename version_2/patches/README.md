# DVA-Fidelity patchset for FFmpeg

The FFmpeg-patches were written by Georg Lippitsch, whom the Mediathek hired to implement the functionality already existing in my shell-scripts directly in FFmpeg.

The patchset is from December 2013.

On 2019-04-02 I wrote Georg that I've managed to apply his patches to ffmpeg v4.1 source.
So I'm using v4.0.6 here.


# Applying the Patch

  1. Download ffmpeg v4.0.6
     I really don't know why v4.1 is not listed on previous releases, and the next version is already v5.

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


# FFmpeg v4.1 - 20190402

## eMail an Georg: "Deinen DVA-Fidelity MUXER Patch mit ffmpeg 4.1"

Griaß Di Georg!

Wollt Dich eh vor ein paar Tagen schon so mal wieder fragen wie's Dir geht?
Weil ich grad wieder was bei ToolsOnAir bestellt hab und neugierig war
obst noch dort arbeitest 😄

Und weil's der Zufall so will hätt ich aber auch eine kleine Frage an Dich:
Kannst Du Dich noch an den superleiwanden DVA-Fidelity Check erinnern,
den Du mir damals 2013 implementiert hast?

Ich würde das Setup gerne wieder aktualisieren, aber krieg's mit FFmpeg
v4.1 ned zum Laufen...
Wärst Du so lieb und würdest mir beim Verstehen helfen?

Patch lässt sich eigentlich "ohne Fehler" anwenden, aber FFmpeg kennt
dann das format "dvafidelity" immer noch nicht...

Patch tut folgendes:

  * Erzeugt ein File: libavformat/dvafidelityenc.c

  * Fügt in libavformat/Makefile folgende Zeile ein:
`OBJS-$(CONFIG_DVAFIDELITY_MUXER)         += dvafidelityenc.o`

Das "REGISTER_MUXER" in "av_register_all(void)" kann ned eingetragen
werden, weil "av_register_all(void)" angeblich seit ca. Anfang 2018
deprecated ist. Angeblich ersatzlos gestrichen, weil nicht mehr notwendig.


Ich kenn mich mit C und Makefiles aber viel zu wenig aus, sodass ich
nedamal weiß ob's reinkompiliert wurde - oder wie ich einfach nur
überprüfen kann ob libavcodec/dvafidelityenc.c überhaupt kompiliert.


Hättest Du vielleicht kurz Zeit mir da auf die Sprünge zu helfen?


Vielen Dank und liebe Grüße!
Peter


------------------

## eMail 2 an Georg: "Re: Deinen DVA-Fidelity MUXER Patch mit ffmpeg 4.1"

Hallo Georg 😄


Hab's hingekriegt! :D

In "libavformats/allformats.c" muss das AVOutputFormat für den Muxer
doch eingetragen werden.
Diese Zeile ist dort bei den anderen Muxern einzutragen:

`extern AVOutputFormat ff_dvafidelity_muxer;`

Dann scheint bei "./configure --list-muxers" auch "dvafidelity" auf:
Jetzt noch "--enable-muxer=dvafidelity" beim Aufruf von "./configure"
anhängen und dann tut's.


Würd' mich dennoch freuen mal wieder von Dir zu hören 😄
Wie läuft's?


Liebe Grüße,
Peter



