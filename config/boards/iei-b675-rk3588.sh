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
    local overlay="$2"
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

	# Install watchdog
	chroot "${rootfs}" apt-get -y install watchdog

	# Use tweaked asound config
	cp "${overlay}/var/lib/alsa/asound.state" "${rootfs}/var/lib/alsa/asound.state"

	# Install legacy networking utilities (ifconfig, route, netstat)
	chroot "${rootfs}" apt-get -y install net-tools

	# copy rknn demo relate files
	cp "${overlay}/usr/bin/rknn_yolov5_demo" "${rootfs}/usr/bin/rknn_yolov5_demo"
	cp "${overlay}/usr/lib/aarch64-linux-gnu/librknnrt.so" "${rootfs}/usr/lib/aarch64-linux-gnu/librknnrt.so"
	cp "${overlay}/usr/lib/aarch64-linux-gnu/librga.so" "${rootfs}/usr/lib/aarch64-linux-gnu/librga.so"

	# copy rkllm demo relate files
	cp "${overlay}/usr/bin/llm_demo" "${rootfs}/usr/bin/llm_demo"
	cp "${overlay}/usr/lib/aarch64-linux-gnu/librkllmrt.so" "${rootfs}/usr/lib/aarch64-linux-gnu/librkllmrt.so"

	# Install Bluetooth userspace tools (BlueZ, Blueman)
	chroot "${rootfs}" apt-get -y install blueman bluez bluez-tools

	# Force iptables legacy backend for compatibility with existing scripts
	chroot "${rootfs}" update-alternatives --set iptables  /usr/sbin/iptables-legacy || true
	chroot "${rootfs}" update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy || true

	# Install dialog dependency for Wi-Fi hotspot configuration script
	chroot "${rootfs}" apt-get -y install dialog

	# Install Wi-Fi hotspot userspace helper script
	cp "${overlay}/usr/bin/hotspot_script.sh" "${rootfs}/usr/bin/hotspot_script.sh"

	# Install resize-filesystem helper script and systemd service
	mkdir -p "${rootfs}/usr/lib/scripts"
	cp "${overlay}/usr/lib/scripts/resize-filesystem.sh" "${rootfs}/usr/lib/scripts/resize-filesystem.sh"
	cp "${overlay}/usr/lib/systemd/system/resize-filesystem.service" "${rootfs}/usr/lib/systemd/system/resize-filesystem.service"
	chroot "${rootfs}" /bin/bash -c "systemctl enable resize-filesystem"
    fi

    return 0
}
