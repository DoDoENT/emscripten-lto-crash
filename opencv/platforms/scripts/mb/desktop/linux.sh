#!/bin/sh

if [ -z "$use_cxx11_abi" ]; then
    use_cxx11_abi=OFF
fi

if [ -z "$arch" ]; then
    arch=x64
fi

if [ -z "$optim" ]; then
    optim=generic
fi

if [ ! -z "$build_dir" ]; then
    additional_cmake_params="-DMB_CONAN_BUILD_LOCATION=$build_dir -DCONAN_EXPORTED=1"
fi

mkdir install

for config in release development
do
    mkdir $config
    pushd $config
    set -x
    cmake -GNinja $additional_cmake_params -DMB_DESKTOP_BUILD=1 -DBUILD_ZLIB=1 -DMB_INTEL_OPTIMIZATION=$optim -DOPENCV_GCC_USE_CXX11_ABI=$use_cxx11_abi -C "`dirname $0`/../common_options.cmake" -DTNUN_ABI=$arch -DENABLE_PRECOMPILED_HEADERS=OFF -DCMAKE_BUILD_TYPE=$config -DCMAKE_INSTALL_PREFIX=$build_dir/install/$config "`dirname $0`/../../../.." || exit 1
    set +x
    cmake --build . --target install || exit 1
    popd
done
