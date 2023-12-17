# Which ffmpeg release/version to use:
FFMPEG_VERSION := 4.0.6
FFMPEG_RELEASE := https://ffmpeg.org/releases/ffmpeg-$(FFMPEG_VERSION).tar.bz2
FFMPEG_ZIP := ffmpeg-$(FFMPEG_VERSION).tar.bz2

# Folder where to build ffmpeg:
BUILD_DIR := ffmpeg-build

FFMPEG_BIN := /usr/local/bin

# FFmpeg configure parameters:
FF_PREFIX := /opt/ffmpeg/ffmpeg-fidelity
FF_LICENSES := --enable-gpl --enable-version3
FFPLAY_SPECIFIC := --enable-postproc --enable-ffplay
PARALLEL_MAKE := -k -j16

## Default compile flags:
FF_COMPILE_FLAGS1 := --disable-shared $(FF_LICENSES) $(FFPLAY_SPECIFIC)
FF_COMPILE_FLAGS2 := \
	--enable-libfreetype \
	--enable-libmp3lame \
	--enable-libopenjpeg \
	--enable-libopus \
	--enable-libsnappy \
	--enable-libtheora \
	--enable-libvorbis \
	--enable-libvpx \
	--enable-libx264 \
	--enable-libxvid \
	--enable-libfontconfig \
	--disable-libjack \
	--disable-indev=jack
FF_COMPILE_FLAGS3 := \
	--enable-swscale \
	--enable-avfilter \
	--enable-pthreads \
	--enable-bzlib \
	--enable-zlib
FF_COMPILE_FLAGS_FIDELITY := \
	--enable-muxer=dvafidelity

# Not used here at the moment, to not require Blackmagic SDKs right now.
FF_DECKLINK := \
	--pkg-config-flags=--static \
	--extra-libs='-lpthread -lm' \
	--enable-nonfree \
	--extra-cflags='-I$(DECKLINK_SDK)' \
	--extra-ldflags='-I$(DECKLINK_SDK)' \
	--enable-decklink

FF_COMPILE_FLAGS := \
	$(FF_COMPILE_FLAGS1) \
	$(FF_COMPILE_FLAGS2) \
	$(FF_COMPILE_FLAGS3) \
	$(FF_COMPILE_FLAGS_FIDELITY)

PKG_DEFAULT = \
	build-essential \
	yasm \
	libbz2-dev \
	libfreetype6-dev \
	libopenjp2-7-dev \
	libvpx-dev \
	libvorbis-dev \
	libxvidcore-dev \
	libmp3lame-dev \
	libx264-dev \
	libfaac-dev \
	libfaad-dev \
	libx265-dev \
	libsdl2-dev \
	libva-dev \
	libvdpau-dev \
	libxcb1-dev \
	libxcb-shm0-dev \
	libxcb-xfixes0-dev \
	libopus-dev \
	libsnappy-dev \
	libtheora-dev \
	libfontconfig1-dev

PACKAGES := $(PKG_DEFAULT)


# ---------------------------

APT_UPDATED := apt-updated
apt-updated:
	$(info "Updating package source lists...")
	sudo apt update && touch $(APT_UPDATED)


.PHONY: prep
prep: apt-updated
	$(info "Installing required packages...")
	sudo apt install $(PACKAGES)


# ---------------------------

.PHONY: ffmpeg-download
ffmpeg-download: $(BUILD_DIR)
	$(info "Downloading FFmpeg source from upstream...")
	wget -cO $(FFMPEG_ZIP) $(FFMPEG_RELEASE)


$(BUILD_DIR):
	mkdir $(BUILD_DIR)


# The tarball is either already included in the git repository, or can be
# downloaded from upstream:
$(FFMPEG_ZIP): ffmpeg-download


.PHONY: ffmpeg-unpack
ffmpeg-unpack: $(FFMPEG_ZIP) $(BUILD_DIR)
	tar --strip-components=1 --skip-old-files -xjf $(FFMPEG_ZIP) -C $(BUILD_DIR)

.PHONY: ffmpeg
ffmpeg: ffmpeg-unpack
	$(info "Building FFmpeg...")
	cd $(BUILD_DIR) && ./configure --prefix=$(FF_PREFIX) $(FF_COMPILE_FLAGS) && make $(PARALLEL_MAKE)


.PHONY: patch
patch:
	cd $(BUILD_DIR) && patch -i ../version_2/patches/dva_fidelity-ffmpeg_v4-20231216.patch -p 1


# ---------------------------

# Folder where vrecord is looking for ffmpeg-decklink binaries:
$(FFMPEG_BIN):
	mkdir -vp $(FFMPEG_BIN)

# There probably is a more elegant way to copy these 2 files in one make-rule, but it works.
$(FFMPEG_BIN)/ffmpeg: $(FFMPEG_BIN)
	cp -avi $(BUILD_DIR)/ffmpeg $(FFMPEG_BIN)/ffmpeg-fidelity

# ---------------------------

# Call this one (as sudo) to put the binaries in place:
.PHONY: install
install: $(FFMPEG_BIN)/ffmpeg


.PHONY: all
all: prep ffmpeg


.PHONY: clean
clean:
	$(info "Cleaning up temp files...")
	rm -rf $(BUILD_DIR)
	rm -f $(APT_UPDATED)

