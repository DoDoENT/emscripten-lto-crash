#!/bin/sh

if [ -z "$ocv_dir" ]; then
    ocv_dir="`dirname $0`/../../../../.."
fi

if [ ! -z "$build_dir" ]; then
    additional_cmake_params="-DMB_CONAN_BUILD_LOCATION=$build_dir -DCONAN_EXPORTED=1"
fi

mkdir install
mkdir build
cd build

cmake -GXcode -DCMAKE_TOOLCHAIN_FILE="$CONAN_CMAKE_TOOLCHAIN_FILE" -DiOS_ALLOW_UNIVERSAL_BUILD=ON $additional_cmake_params -DCMAKE_INSTALL_PREFIX=../install -C "`dirname $0`/../common_options.cmake" "$ocv_dir"
cmake --build . --config Development --target install
cmake --build . --config Release     --target install
