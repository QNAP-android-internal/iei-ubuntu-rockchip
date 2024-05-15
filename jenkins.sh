#!/bin/bash

B675_path="/home/iei-sw/new_ssd1_4TB/rk3588/ubuntu_b675_rk3588"
release_path="/home/iei-sw/new_ssd1_4TB/rk3588/release/b675/ubuntu2204"
release_name="B675-Ubuntu-2204-R001.zip"

cd ${B675_path}
rm -rf images
rm -f build/linux-*.deb
rm -f build/u-boot-*.deb

if [ "$VARIANT" = "SERVER" ]; then
    ./build.sh -b "$BOARD" -so
else
    ./build.sh -b "$BOARD" -do
fi

if [ -f $release_path/$release_name ]; then
    rm -f $release_path/$release_name
fi

cd ${B675_path}/images
for i in image-release-rockchip-format*.img.xz; do [ -f "$i" ] && built_file="$i"; done
if [ -z $built_file ]; then
    echo "No rockchip format update file found!"
    exit 100
fi

release_folder=$(basename ${release_name} .zip)
cp -a ${release_path}/release_template ${release_path}/${release_folder}
built_file_zip=$(basename ${built_file} .xz).zip
xz -c -d ${built_file} | zip ${release_path}/${release_folder}/${built_file_zip} -
zip -r ${release_path}/${release_name} ${release_path}/${release_folder}
rm -rf ${release_path}/${release_folder}
