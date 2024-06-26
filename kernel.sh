#!/bin/bash

TG_TOKEN=${BOT_TOKEN_ID}
TG_CHAT=${TG_CHAT_ID}
TAG="$(curl -s https://api.github.com/repos/tiann/KernelSU/releases/latest | jq -r '.tag_name')"

if [ -z "$TG_TOKEN" ] || [ -z "$TG_CHAT" ] || [ -z "$TAG" ]; then
    echo "Vars are not setup properly!"
    exit 1
fi

KZIP="$(pwd)/Kernel"
cd ~
mkdir kernel; cd kernel
git config --global color.ui true
git config --global user.name lucazzzkk
git config --global user.email heyylucazzz@google.com

function tg_sendFile() {
		curl -s "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
		-F parse_mode=markdown \
		-F chat_id=$TG_CHAT \
		-F document=@${1} \
		-F "caption=${2}"
}

function tg_sendText() {
	curl -s "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
		-d "parse_mode=html" \
		-d text="${1}" \
		-d chat_id=$TG_CHAT \
		-d "disable_web_page_preview=true"
}

n='
'

tg_sendText "Starting KernelSU CI Builds ($TAG)"
today=$(date +%y%m%d)

branches=$(curl -s "https://api.github.com/repos/Gabriel2392/android_kernel_samsung_s5e8535/branches" | jq -r '.[].name')

HOME="$(pwd)"
git clone https://gitlab.com/OhMyVenyx/clang-r450784e "$HOME/clang-r450784e" --depth=1
git clone https://android.googlesource.com/platform/prebuilts/build-tools "$HOME/build-tools" --depth=1

export CROSS_COMPILE="$HOME/clang-r450784e/bin/aarch64-linux-gnu-"
export CC="$HOME/clang-r450784e/bin/clang"
export PLATFORM_VERSION=13
export ANDROID_MAJOR_VERSION=t
export PATH="$HOME/clang-r450784e/bin:$PATH"
export PATH="$HOME/build-tools/path/linux-x86:$PATH"
export STACK_CHECK_MAX_FRAME_SIZE=16096
export CONFIG_FRAME_WARN=16096
export TARGET_SOC=s5e8535
export LLVM=1 LLVM_IAS=1
export ARCH=arm64
EXTRA_FLAGS="LOCALVERSION= KBUILD_BUILD_HOST=compiuterkk"


for branch in $branches; do
    rm -rf src
    git clone https://github.com/Gabriel2392/android_kernel_samsung_s5e8535 -b $branch --depth=1 src || continue
    sudo apt-get install bc flex libelf-dev dwarves -y
    cd src
    nano Makefile
    curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash - || continue
    kversion=$(awk -F= '/^VERSION =/ {v=$2} /^PATCHLEVEL =/ {p=$2} /^SUBLEVEL =/ {s=$2} END {gsub(/ /,"",v); gsub(/ /,"",p); gsub(/ /,"",s); print v"."p"."s}' Makefile | sort)
    echo "Building $kversion"
    make -j$(nproc --all) -C $(pwd) $EXTRA_FLAGS CROSS_COMPILE="$HOME/clang-r450784e/bin/aarch64-linux-gnu-" CC="$HOME/clang-r450784e/bin/clang" TARGET_SOC=s5e8535 LLVM=1 LLVM_IAS=1 ARCH=arm64 PLATFORM_VERSION=13 ANDROID_MAJOR_VERSION=t KBUILD_BUILD_USER=lucazzzkk KBUILD_BUILD_HOST=compiuterkk a14x_defconfig || continue
    make -j$(nproc --all) -C $(pwd) $EXTRA_FLAGS CROSS_COMPILE="$HOME/clang-r450784e/bin/aarch64-linux-gnu-" CC="$HOME/clang-r450784e/bin/clang" TARGET_SOC=s5e8535 LLVM=1 LLVM_IAS=1 ARCH=arm64 PLATFORM_VERSION=13 ANDROID_MAJOR_VERSION=t KBUILD_BUILD_USER=lucazzzkk KBUILD_BUILD_HOST=compiuterkk || continue
    cp "arch/arm64/boot/Image" "${KZIP}/Image"
    cd "$KZIP"
    zip -r "KernelSU_${TAG}-${kversion}.zip" ./
    tg_sendFile "KernelSU_${TAG}-${kversion}.zip" "KernelSU version: ${TAG}${n}Kernel version: ${kversion}" || tg_sendFile "KernelSU_${TAG}-${kversion}.zip" "KernelSU version: ${TAG}${n}Kernel version: ${kversion}" || exit 1
    rm -f Image "KernelSU_${TAG}-${kversion}.zip"
    cd $HOME
done
