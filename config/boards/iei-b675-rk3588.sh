# shellcheck shell=bash

export BOARD_NAME="B675"
export BOARD_MAKER="IEI"
export BOARD_SOC="Rockchip RK3588"
export BOARD_CPU="ARM Cortex A76 / A55"
export UBOOT_PACKAGE="u-boot-iei-b675-rk3588"
export UBOOT_RULES_TARGET="iei-b675-rk3588"
export COMPATIBLE_SUITES=("jammy" "noble")
export COMPATIBLE_FLAVORS=("server" "desktop")

function config_image_hook__iei-b675-rk3588() {
    local rootfs="$1"
    local suite="$3"
    if [ "${suite}" == "jammy" ] || [ "${suite}" == "noble" ] || [ "${suite}" == "iei-b675-noble" ]; then
        # Install panfork
        chroot "${rootfs}" add-apt-repository -y ppa:jjriek/panfork-mesa
        chroot "${rootfs}" apt-get update
        chroot "${rootfs}" apt-get -y install mali-g610-firmware
        chroot "${rootfs}" apt-get -y dist-upgrade

        # Install libmali blobs alongside panfork
        chroot "${rootfs}" apt-get -y install libmali-g610-x11

        # Install the rockchip camera engine
        chroot "${rootfs}" apt-get -y install camera-engine-rkaiq-rk3588

        # Disable the system turning off the screen when it is inactive
        chroot "${rootfs}" sed -i 's/<default>300<\/default>/<default>0<\/default>/g' /usr/share/glib-2.0/schemas/org.gnome.desktop.session.gschema.xml
        # Disable the system screen dimming after idle timeout
        chroot "${rootfs}" sed -i 's/<default>true<\/default>/<default>false<\/default>/g' /usr/share/glib-2.0/schemas/org.gnome.settings-daemon.plugins.power.gschema.xml
        chroot "${rootfs}" glib-compile-schemas /usr/share/glib-2.0/schemas/
		chroot "${rootfs}" dconf update

        # Install gstreamer plugins for H.265 video
        chroot "${rootfs}" apt-get -y install gstreamer1.0-plugins-bad gstreamer1.0-libav
    fi

    return 0
}
