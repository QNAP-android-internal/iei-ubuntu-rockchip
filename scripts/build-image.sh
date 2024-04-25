#!/bin/bash

set -eE 
trap 'echo Error: in $0 on line $LINENO' ERR

cleanup_loopdev() {
    local loop="$1"

    sync --file-system
    sync

    sleep 1

    if [ -b "${loop}" ]; then
        for part in "${loop}"p*; do
            if mnt=$(findmnt -n -o target -S "$part"); then
                umount "${mnt}"
            fi
        done
        losetup -d "${loop}"
    fi
}

wait_loopdev() {
    local loop="$1"
    local seconds="$2"

    until test $((seconds--)) -eq 0 -o -b "${loop}"; do sleep 1; done

    ((++seconds))

    ls -l "${loop}" &> /dev/null
}

if [ "$(id -u)" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: $0 filename.rootfs.tar"
    exit 1
fi

rootfs="$(readlink -f "$1")"
if [[ "$(basename "${rootfs}")" != *".rootfs.tar" || ! -e "${rootfs}" ]]; then
    echo "Error: $(basename "${rootfs}") must be a rootfs tarfile"
    exit 1
fi

cd "$(dirname -- "$(readlink -f -- "$0")")" && cd ..
mkdir -p images build && cd build

if [[ -z ${BOARD} ]]; then
    echo "Error: BOARD is not set"
    exit 1
fi

if [[ -z ${VENDOR} ]]; then
    echo "Error: VENDOR is not set"
    exit 1
fi

if [[ "${BOARD}" == iei-b675 ]]; then
    DEVICE_TREE=rk3588-b675.dtb
    OVERLAY_PREFIX=iei-b675
fi

KVER=""
if [[ "${MAINLINE}" == "Y" ]]; then
    KVER="-mainline-6.6.0"
fi

# Create an empty disk image
img="../images/$(basename "${rootfs}" .rootfs.tar)${KVER}.img"
size="$(( $(wc -c < "${rootfs}" ) / 1024 / 1024 ))"
truncate -s "$(( size + 2048 + 512 ))M" "${img}"

# Create loop device for disk image
loop="$(losetup -f)"
losetup "${loop}" "${img}"
disk="${loop}"

# Cleanup loopdev on early exit
trap 'cleanup_loopdev ${loop}' EXIT

# Ensure disk is not mounted
mount_point=/tmp/mnt
umount "${disk}"* 2> /dev/null || true
umount ${mount_point}/* 2> /dev/null || true
mkdir -p ${mount_point}

# Setup partition table
dd if=/dev/zero of="${disk}" count=4096 bs=512
parted --script "${disk}" \
mklabel gpt \
mkpart primary fat16 16MiB 528MiB \
mkpart primary ext4 528MiB 100%

# Create partitions
{
    echo "t"
    echo "1"
    echo "BC13C2FF-59E6-4262-A352-B275FD6F7172"
    echo "t"
    echo "2"
    echo "0FC63DAF-8483-4772-8E79-3D69D8477DE4"
    echo "w"
} | fdisk "${disk}" &> /dev/null || true

partprobe "${disk}"

partition_char="$(if [[ ${disk: -1} == [0-9] ]]; then echo p; fi)"

#sleep 1

#wait_loopdev "${disk}${partition_char}2" 60 || {
#    echo "Failure to create ${disk}${partition_char}1 in time"
#    exit 1
#}

#sleep 1

#wait_loopdev "${disk}${partition_char}1" 60 || {
#    echo "Failure to create ${disk}${partition_char}1 in time"
#    exit 1
#}

sleep 1

# Generate random uuid for bootfs
boot_uuid=$(uuidgen | head -c8)

# Generate random uuid for rootfs
root_uuid=$(uuidgen)

# Create filesystems on partitions
mkfs.vfat -i "${boot_uuid}" -F16 -n system-boot "${disk}${partition_char}1"
dd if=/dev/zero of="${disk}${partition_char}2" bs=1KB count=10 > /dev/null
mkfs.ext4 -U "${root_uuid}" -L writable "${disk}${partition_char}2"

# Mount partitions
mkdir -p ${mount_point}/{system-boot,writable} 
mount "${disk}${partition_char}1" ${mount_point}/system-boot
mount "${disk}${partition_char}2" ${mount_point}/writable

# Copy the rootfs to root partition
tar -xpf "${rootfs}" -C ${mount_point}/writable

# Set boot args for the splash screen
[ -z "${img##*desktop*}" ] && bootargs="quiet splash plymouth.ignore-serial-consoles" || bootargs=""

# Create fstab entries
boot_uuid="${boot_uuid:0:4}-${boot_uuid:4:4}"
mkdir -p ${mount_point}/writable/boot/firmware
cat > ${mount_point}/writable/etc/fstab << EOF
# <file system>     <mount point>  <type>  <options>   <dump>  <fsck>
UUID=${boot_uuid^^} /boot/firmware vfat    defaults    0       2
UUID=${root_uuid,,} /              ext4    defaults    0       1
/swapfile           none           swap    sw          0       0
EOF

# Uboot script
cat > ${mount_point}/system-boot/boot.cmd << 'EOF'
# This is a boot script for U-Boot
#
# Recompile with:
# mkimage -A arm64 -O linux -T script -C none -n "Boot Script" -d boot.cmd boot.scr

setenv load_addr ${scriptaddr}
setenv overlay_error "false"

echo "Boot script loaded from ${devtype} ${devnum}"

if test -e ${devtype} ${devnum}:${distro_bootpart} /ubuntuEnv.txt; then
	load ${devtype} ${devnum}:${distro_bootpart} ${load_addr} /ubuntuEnv.txt
	env import -t ${load_addr} ${filesize}
fi

load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} /dtbs/${fdtfile}
fdt addr ${fdt_addr_r} && fdt resize 0x10000

for overlay_file in ${overlays}; do
    if load ${devtype} ${devnum}:${distro_bootpart} ${fdtoverlay_addr_r} /dtbs/overlays/${overlay_prefix}-${overlay_file}.dtbo; then
        echo "Applying device tree overlay: /dtbs/overlays/${overlay_prefix}-${overlay_file}.dtbo"
        fdt apply ${fdtoverlay_addr_r} || setenv overlay_error "true"
    elif load ${devtype} ${devnum}:${distro_bootpart} ${fdtoverlay_addr_r} /dtbs/overlays/${overlay_file}.dtbo; then
        echo "Applying device tree overlay: /dtbs/overlays/${overlay_file}.dtbo"
        fdt apply ${fdtoverlay_addr_r} || setenv overlay_error "true"
    elif load ${devtype} ${devnum}:${distro_bootpart} ${fdtoverlay_addr_r} /dtbs/overlays/rk3588-${overlay_file}.dtbo; then
        echo "Applying device tree overlay: /dtbs/overlays/rk3588-${overlay_file}.dtbo"
        fdt apply ${fdtoverlay_addr_r} || setenv overlay_error "true"
    fi
done
if test "${overlay_error}" = "true"; then
    echo "Error applying device tree overlays, restoring original device tree"
    load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} /dtbs/${fdtfile}
fi

load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} /vmlinuz
load ${devtype} ${devnum}:${distro_bootpart} ${ramdisk_addr_r} /initrd.img

booti ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}
EOF
${TOPDIR}/tools/rkbin/tools/mkimage -A arm64 -O linux -T script -C none -n "Boot Script" -d ${mount_point}/system-boot/boot.cmd ${mount_point}/system-boot/boot.scr

# Uboot env
cat > ${mount_point}/system-boot/ubuntuEnv.txt << EOF
bootargs=root=UUID=${root_uuid} rootfstype=ext4 rootwait rw console=ttyS2,1500000 console=tty1 cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory swapaccount=1 systemd.unified_cgroup_hierarchy=0 ${bootargs}
fdtfile=${DEVICE_TREE}
overlay_prefix=${OVERLAY_PREFIX}
overlays=
EOF

# Copy the device trees, kernel, and initrd to the boot partition
mv ${mount_point}/writable/boot/firmware/* ${mount_point}/system-boot/

# Write bootloader to disk image
if [ -f "${mount_point}/writable/usr/lib/u-boot/u-boot-rockchip.bin" ]; then
    dd if="${mount_point}/writable/usr/lib/u-boot/u-boot-rockchip.bin" of="${loop}" seek=1 bs=32k conv=fsync
else
    dd if="${mount_point}/writable/usr/lib/u-boot/idbloader.img" of="${loop}" seek=64 conv=notrunc
    #dd if="${mount_point}/writable/usr/lib/u-boot/u-boot.itb" of="${loop}" seek=16384 conv=notrunc
    dd if="${mount_point}/writable/usr/lib/u-boot/uboot.img" of="${loop}" seek=16384 conv=notrunc
fi

# Cloud init config for server image
if [ -z "${img##*server*}" ]; then
    cp ../overlay/boot/firmware/{meta-data,user-data,network-config} ${mount_point}/system-boot
    if [ "${BOARD}" == iei-b675 ]; then
	sed -i 's/expire: true/expire: false/g' ${mount_point}/system-boot/user-data
    fi
fi

sync --file-system
sync

mkdir -p rkimage/Image

pushd rkimage
cp -rf ../../tools/* .
cp -rf ${mount_point}/writable/usr/lib/u-boot/idbloader.img Image/
cp -rf ${mount_point}/writable/usr/lib/u-boot/uboot.img Image/
cp -rf ${mount_point}/writable/usr/lib/u-boot/u-boot.itb Image/
cp -a MiniLoaderAll.bin Image/
cp -a misc.img Image/
cp -a parameter.txt Image/
cp -a package-file Image/
cp -a RKTools/linux/Linux_Pack_Firmware/rockdev/afptool .
cp -a RKTools/linux/Linux_Pack_Firmware/rockdev/rkImageMaker .
popd

# Umount partitions
umount "${disk}${partition_char}1"
umount "${disk}${partition_char}2"

# Remove loop device
losetup -d "${loop}"

# Exit trap is no longer needed
trap '' EXIT

tag=""
if [ -z "${img##*desktop*}" ]; then
    tag="desktop"
elif [ -z "${img##*server*}" ]; then
    tag="server"
fi

# build RK format Image
rkimg="../images/image-release-rockchip-format-${BOARD}-ubuntu-${tag}-$(date "+%y%m%d").img"

pushd rkimage
dd if=../${img} of=Image/boot.img skip=32768 bs=512 count=1048576 conv=notrunc
dd if=../${img} of=Image/rootfs.img skip=1081344 conv=notrunc
RKTools/linux/Linux_Pack_Firmware/rockdev/afptool -pack . update.img ./package-file
RKTools/linux/Linux_Pack_Firmware/rockdev/rkImageMaker -RK3588 Image/MiniLoaderAll.bin ./update.img ../${rkimg} -os_type:androidos
rm -rf Image/update.img
xz -3 --force --keep --quiet --threads=0 "../${rkimg}"
rm -f "../${rkimg}"
popd
rm -rf rkimage

# Compressing RAW format Image
rawimg="../images/image-release-raw-format-${BOARD}-ubuntu-${tag}-$(date "+%y%m%d").img"
mv "${img}" "${rawimg}"
echo -e "\nCompressing $(basename "${rawimg}.xz")\n"
xz -3 --force --keep --quiet --threads=0 "${rawimg}"
rm -f "${rawimg}"
cd ../images && sha256sum "$(basename "${rawimg}.xz")" > "$(basename "${rawimg}.xz.sha256")"
