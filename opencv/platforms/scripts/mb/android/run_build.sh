#!/bin/sh

if [ ! -z "$build_dir" ]; then
    additional_cmake_params="-DMB_CONAN_BUILD_LOCATION=$build_dir -DCONAN_EXPORTED=1"
fi

for config in release development
do
    mkdir -p $2/$config
    cd $2/$config
    ocv_dir_path=../../$ocv_dir
    $ocv_dir/platforms/scripts/mb/$1/$2.sh -DCMAKE_BUILD_TYPE=$config $additional_cmake_params -DOpenCV_INSTALL_BINARIES_PREFIX=$2/$config/ -DCMAKE_INSTALL_PREFIX=$build_dir/install $ocv_dir || exit 1
    cmake --build . --target install
    cd ../..
done
