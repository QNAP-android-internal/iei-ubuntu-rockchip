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

if [[ -z ${SUITE} ]]; then
    echo "Error: SUITE is not set"
    exit 1
fi

# shellcheck source=/dev/null
source "../config/suites/${SUITE}.sh"

# Clone the kernel repo
if ! git -C linux-rockchip pull; then
    git clone --progress -b "${KERNEL_BRANCH}" "${KERNEL_REPO}" linux-rockchip --depth=2
fi

cd linux-rockchip
git checkout "${KERNEL_BRANCH}"

# shellcheck disable=SC2046
export $(dpkg-architecture -aarm64)
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=aarch64-linux-gnu-gcc
export LANG=C

if [[ "${SUITE}" == iei-b675-noble  ]]; then
export $(dpkg-architecture -aarm64)
export CROSS_COMPILE=${TOPDIR}/tools/prebuilts/gcc/linux-x86/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
export CC=${TOPDIR}/tools/prebuilts/gcc/linux-x86/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-gcc
export LANG=C

make ARCH=arm64 \
	CROSS_COMPILE=${TOPDIR}/tools/prebuilts/gcc/linux-x86/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu- \
	iei_ubuntu_defconfig

mv .config ../.config

make ARCH=arm64 \
    CROSS_COMPILE=${TOPDIR}/tools/prebuilts/gcc/linux-x86/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu- \
    mrproper

    SERIES_FILE="../../packages/kernel-${SUITE}/debian/patches/series"

    case "${PANEL}" in
        lvds)
            echo "PANEL=lvds -> disable HDMI + MIPI"
            sed -i \
                's|^0003-.*|0003-arm64-dts-rk3588-b675-disable-hdmi-and-mipi-displays.patch|' \
                "${SERIES_FILE}"
           ;;
        mipi)
            echo "PANEL=mipi -> disable HDMI + LVDS"
            sed -i \
                's|^0003-.*|0003-arm64-dts-rk3588-b675-disable-hdmi-and-lvds-displays.patch|' \
                "${SERIES_FILE}"
            ;;
        hdmi|"")
            echo "PANEL=hdmi (default) -> keep original series"
            ;;
        *)
            echo "WARNING: Unknown PANEL=${PANEL}, keep original series"
            ;;
    esac

    cp -r ../../packages/kernel-${SUITE}/debian .
    cp -r ../../packages/kernel-${SUITE}/debian.rockchip .
fi

# Compile the kernel into a deb package
dpkg-source --before-build .
fakeroot debian/rules clean binary-headers binary-rockchip do_mainline_build=true
dpkg-source --after-build .
