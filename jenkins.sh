#!/bin/bash

make_releasenote()
{
        release_name=$(git tag | grep UBUNTU | tail -1)
        author="Ming Tsai"
        os="UBUNTU_2204"
        cp ${release_path}/ReleaseNotes.txt ${release_path}/release_template/ReleaseNotes_${os}.txt
        sed -i "s/^[ \t]*Version:.*$/Version: ${release_name}/" ${release_path}/release_template/ReleaseNotes_${os}.txt
        sed -i -r "s/^[ \t]*Date: [0-9]*\.[0-9]*\.[0-9]*(.*)/Date: $(date '+%Y.%m.%d') \1/" ${release_path}/release_template/ReleaseNotes_${os}.txt
        sed -i "s/Howard Chou/${author}/g" ${release_path}/release_template/ReleaseNotes_${os}.txt
}

B675_path="/home/iei-sw/new_ssd1_4TB/rk3588/ubuntu_b675_rk3588"
release_path="/home/iei-sw/new_ssd1_4TB/rk3588/release/b675/ubuntu2204"
release_name="B675-UBUNTU-2204-R001.zip"
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

make_releasenote

cd ${B675_path}/images
for i in image-release-rockchip-format*.img.xz; do [ -f "$i" ] && built_file="$i"; done
if [ -z $built_file ]; then
    echo "No rockchip format update file found!"
    exit 100
fi

release_folder=$(basename ${release_name} .zip)
cp -a ${release_path}/release_template ${release_path}/${release_folder}
rm ${release_path}/release_template/ReleaseNotes_${os}.txt

built_file_zip=$(basename ${built_file} .xz).zip
release_img=$(basename ${built_file} .xz)
md5_img=$(basename ${release_img} .img)
xz -d ${built_file}
md5sum ${release_img} > ${release_path}/${release_folder}/${md5_img}_md5sum.txt
mv ${release_img} ${release_path}/${release_folder}/
cd ${release_path}
zip -r ${release_name} ${release_folder}
rm -rf ${release_folder}
