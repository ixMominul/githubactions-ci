#!/bin/bash
# TWRP build script
# For github actions
#
# Copyright(c) 2021 Hendra Manudinata.

#set -eo pipefail

# Variables
device=$1 # Device codename
twrp_branch=$2 # TWRP branch version
dt_url="https://github.com/hendramn/twrp_${device}" # Device tree link
buildtype=$3 # Build variant
recoverytype=$4 # Build Type

if [ "${recoverytype}" == "boot" ]; then
	mkatype=bootimage
else
	mkatype=recoveryimage
fi

# Setup environment
setup_env() {
	sudo DEBIAN_FRONTEND=noninteractive apt-get install \
	openjdk-8-jdk android-tools-adb bc bison \
	build-essential curl flex g++-multilib gcc-multilib \
	gnupg gperf imagemagick lib32ncurses5-dev \
	lib32readline-dev lib32z1-dev liblz4-tool \
	libncurses5-dev libsdl1.2-dev libssl-dev \
	libwxgtk3.0-dev libxml2 libxml2-utils lzop \
	pngcrush rsync schedtool squashfs-tools xsltproc \
	yasm zip zlib1g-dev ccache -y

	export USE_CCACHE=1
	export CCACHE_EXEC=$(command -v ccache)
	export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx3g"

	sudo curl --create-dirs -L -o /usr/local/bin/repo -O -L https://storage.googleapis.com/git-repo-downloads/repo
	sudo chmod a+rx /usr/local/bin/repo

	sudo apt-get clean
	sudo rm -rf /var/cache/apt/*
	sudo rm -rf /var/lib/apt/lists/*
	sudo rm -rf /tmp/*
}

# Clone source
clone_source() {
	cd ~
	mkdir twrp && cd twrp

	repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_omni -b twrp-${twrp_branch}
	repo sync --force-sync --current-branch --no-tags --no-clone-bundle --optimized-fetch --prune -j$(nproc --all)
}

# Clone DT
clone_tree() {
	mkdir -p device/samsung && cd device/samsung
	git clone ${dt_url}
}

# Start build
start_build() {
	cd ~/twrp
	source build/envsetup.sh

	BUILD_START=$(date +"%s")

	lunch omni-${device}_${buildtype}
	mka ${mkatype} -j$(nproc --all)

	BUILD_END=$(date +"%s")
	DIFF=$(($BUILD_END - $BUILD_START))
}

# Fancy Telegram function

# Send text (helper)
function tg_sendText() {
	curl -s "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
		-d "parse_mode=html" \
		-d text="${1}" \
		-d chat_id=$CHAT_ID \
		-d "disable_web_page_preview=true"
}

# Send info
tg_sendInfo() {
	tg_sendText "<b>TWRP Build Started!</b>
	<b>💻 Started on:</b> Github Actions
	<b>📱 Device:</b> ${device}
	<b>📃 Commit list:</b> <a href='${dt_url}/commits/master'>Click Here</a>
	<b>📆  Date:</b> $(date +%A,\ %d\ %B\ %Y\ %H:%M:%S)"
}

# Telegram status: Prepare
tg_sendPrepareStatus() {
	tg_sendText "<b>$(date +%H:%M:%S):</b> Preparing Environment"
}

# Telegram status: Download source
tg_sendSyncSourceStatus() {
	tg_sendText "<b>$(date +%H:%M:%S):</b> Syncing source (${twrp_branch})"
}

# Telegram status: Clone tree
tg_sendCloneTreeStatus() {
	tg_sendText "<b>$(date +%H:%M:%S):</b> Cloning Tree"
}

# Telegram status: Build
tg_sendBuildStatus() {
	tg_sendText "<b>$(date +%H:%M:%S):</b> Building"
}

# Telegram status: Done
tg_sendDoneStatus() {
	tg_sendText "<b>Build done successfully! 🎉</b>
	<b>Time build:</b> $(($DIFF / 60))m $(($DIFF % 60))s"
}

# Error function
abort() {
	errorvalue=$?
	tg_sendText "Build error! Check github actions log bruh"
	exit $errorvalue
}
trap 'abort' ERR;

# Finally, call the function
tg_sendPrepareStatus;
setup_env;
tg_sendSyncSourceStatus;
clone_source;
tg_sendCloneTreeStatus;
clone_tree;
tg_sendBuildStatus;
build;
tg_sendDoneStatus;
