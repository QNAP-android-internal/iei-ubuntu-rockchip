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

if [[ "${MAINLINE}" != "Y" ]]; then
    if [ ! -d kernel-${BOARD} ]; then
        # shellcheck source=/dev/null
        source ${TOPDIR}/packages/kernel-"${BOARD}"-rk3588/debian/upstream
        git clone --single-branch --progress -b "${BRANCH}" "${GIT}" kernel-"${BOARD}"
        git -C kernel-"${BOARD}" checkout "${COMMIT}"
    fi

    export CROSS_COMPILE=${TOPDIR}/tools/prebuilts/gcc/linux-x86/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
    export ARCH=$(cat ${TOPDIR}/packages/kernel-"${BOARD}"-rk3588/debian/arch)

    cd kernel-${BOARD}

    sed -i -r 's/^KBUILD_IMAGE(.*)Image\.gz$/KBUILD_IMAGE\1Image/g' arch/${ARCH}/Makefile

    # Compile kernel into a deb package
    #dpkg-buildpackage -a "$(cat debian/arch)" -d -b -nc -uc

    ### For iEi linux defconfig
    #make rockchip_linux_defconfig rk3588_linux.config
    make iei_ubuntu_defconfig

    make rk3588-b675.img -j"$(nproc)"

    make KERNELRELEASE="$(make kernelversion)" KDEB_PKGVERSION="$(make kernelversion)" -j"$(nproc)" bindeb-pkg

    #make CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 ARCH=arm64 iei_android_defconfig
    #make CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 ARCH=arm64 rk3588-b675.img -j"$(nproc)"
    #make KERNELRELEASE="$(make kernelversion)-rockchip" KDEB_PKGVERSION="$(make kernelversion)-rockchip" CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 ARCH=arm64 -j"$(nproc)" bindeb-pkg
    #make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- iei_android_defconfig
    #make KERNELRELEASE="$(make kernelversion)-rockchip" KDEB_PKGVERSION="$(make kernelversion)-rockchip" CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 -j "$(nproc)" bindeb-pkg

    rm -f ../linux-image-*dbg*.deb ../linux-libc-dev_*.deb ../*.buildinfo ../*.changes ../*.dsc ../*.tar.gz
else
    test -d linux ||  git clone --single-branch --progress -b v6.6-rk3588 https://github.com/Joshua-Riek/linux.git --depth=100
    cd linux

    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- rockchip_linux_defconfig
    make KERNELRELEASE="$(make kernelversion)-rockchip" KDEB_PKGVERSION="$(make kernelversion)-rockchip" CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 -j "$(nproc)" bindeb-pkg

    rm -f ../linux-image-*dbg*.deb ../linux-libc-dev_*.deb ../*.buildinfo ../*.changes ../*.dsc ../*.tar.gz
fi
