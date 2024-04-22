#!/bin/bash

set -eE 
trap 'echo Error: in $0 on line $LINENO' ERR

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

TOPDIR=$(pwd)

cd "$(dirname -- "$(readlink -f -- "$0")")" && cd ..
mkdir -p build && cd build

if [[ -z ${VENDOR} ]]; then
    echo "Error: VENDOR is not set"
    exit 1
fi

if [ ! -d u-boot-${BOARD} ]; then
    # shellcheck source=/dev/null
    source ${TOPDIR}/packages/u-boot-"${BOARD}"-rk3588/debian/upstream
    git clone --single-branch --progress -b "${BRANCH}" "${GIT}" u-boot-"${BOARD}"
    git -C u-boot-"${BOARD}" checkout "${COMMIT}"
    cp -r ${TOPDIR}/packages/u-boot-"${BOARD}"-rk3588/debian u-boot-"${BOARD}"
fi

export CROSS_COMPILE=${TOPDIR}/tools/prebuilts/gcc/linux-x86/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
ln -sf ${TOPDIR}/tools/rkbin ${TOPDIR}/build/rkbin
ln -sf ${TOPDIR}/tools/prebuilts ${TOPDIR}/build/prebuilts

cd u-boot-${BOARD}

# Compile u-boot into a deb package
#dpkg-buildpackage -a "$(cat debian/arch)" -d -b -nc -uc

#make clean &&  make mrproper &&  make distclean
#./make.sh rk3588_b675
#./make.sh itb
#tools/mkimage -n rk3588 -T rksd -d tpl/u-boot-tpl.bin idbloader.img
#cat spl/u-boot-spl.bin >> idbloader.img
#./make.sh loader
dpkg-buildpackage -a "$(cat debian/arch)" -T build -d -uc -nc
dpkg-buildpackage -a "$(cat debian/arch)" -T binary -d -uc -nc


rm -f ../*.buildinfo ../*.changes
