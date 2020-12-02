#!/bin/sh

if [ -z "$COMPILE_TO_WEBASSEMBLY" ]; then
    COMPILE_TO_WEBASSEMBLY=ON
fi

if [ -z "$ENABLE_PTHREADS" ]; then
    ENABLE_PTHREADS=OFF
fi

if [ -z "$USE_WEBGL2" ]; then
    USE_WEBGL2=ON
fi

if [ -z "$TARGET_ENVIRONMENT" ]; then
    TARGET_ENVIRONMENT=web
fi

if [ -z "$USE_SIMD" ]; then
    USE_SIMD=OFF
fi

if [ ! -z "$build_dir" ]; then
    additional_cmake_params="-DMB_CONAN_BUILD_LOCATION=$build_dir -DCONAN_EXPORTED=1"
fi

cmake_params="-DBUILD_ZLIB=1 -DMB_EMSCRIPTEN_COMPILE_TO_WEBASSEMBLY=$COMPILE_TO_WEBASSEMBLY -DMB_EMSCRIPTEN_ENABLE_PTHREADS=$ENABLE_PTHREADS -DMB_EMSCRIPTEN_USE_WEBGL2=$USE_WEBGL2 -DMB_EMSCRIPTEN_TARGET_ENVIRONMENT=$TARGET_ENVIRONMENT -DMB_EMSCRIPTEN_SIMD=$USE_SIMD -DENABLE_PRECOMPILED_HEADERS=OFF $additional_cmake_params"

echo "CMake parameters are: $cmake_params"

mkdir install

for config in development release
do
    mkdir $config
    pushd $config
    emcmake cmake -GNinja $cmake_params -C "`dirname $0`/common_options.cmake" -DCMAKE_BUILD_TYPE=$config -DCMAKE_INSTALL_PREFIX=$build_dir/install/$config "`dirname $0`/../../../.." || exit -1
    cmake --build . --target install  || exit -1
    popd
done
