#!/bin/bash
DIR=$(readlink -f .)
PARENT_DIR=$(readlink -f ${DIR}/..)

export CROSS_COMPILE=$PARENT_DIR/clang-r416183b/bin/aarch64-linux-gnu-
export CC=$PARENT_DIR/clang-r416183b/bin/clang

export PLATFORM_VERSION=13
export ANDROID_MAJOR_VERSION=t
export PATH=$PARENT_DIR/clang-r416183b/bin:$PATH
export PATH=$PARENT_DIR/build-tools/path/linux-x86:$PATH
export TARGET_SOC=s5e8535
export LLVM=1 LLVM_IAS=1
export ARCH=arm64
export STACK_CHECK_MAX_FRAME_SIZE=16096
export CONFIG_FRAME_WARN=16096

git clone https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r416183b $PARENT_DIR/clang-r416183b --depth=1

git clone https://android.googlesource.com/platform/prebuilts/build-tools $PARENT_DIR/build-tools --depth=1

make -j$(nproc --all) -C $(pwd) O=out a14x_defconfig

make -j$(nproc --all) -C $(pwd) O=out