#!/bin/sh

if [ ! -z "$build_dir" ]; then
    additional_cmake_params="-DMB_CONAN_BUILD_LOCATION=$build_dir -DCONAN_EXPORTED=1"
fi

mkdir install

for config in release development
do
    mkdir $config
    pushd $config
    cmake -GNinja -DCMAKE_BUILD_TYPE=$config -DMB_DESKTOP_BUILD=1 -DHAVE_COCOA=1 -DCMAKE_INSTALL_PREFIX=$build_dir/install/$config $additional_cmake_params -C "`dirname $0`/../common_options.cmake" "`dirname $0`/../../../.."
    cmake --build . --target install
    popd
done
