#!/bin/sh

export CC=/usr/local/bin/gcc-7
export CXX=/usr/local/bin/g++-7

mkdir development
cd development
cmake -GNinja -DMB_DESKTOP_BUILD=1 -DBUILD_opencv_highgui=OFF -DWITH_AVFOUNDATION=OFF -C "`dirname $0`/../common_options.cmake" -DENABLE_PRECOMPILED_HEADERS=OFF -DCMAKE_BUILD_TYPE=Development -DCMAKE_C_FLAGS="-Wno-implicit-fallthrough -Wno-error=return-type" "`dirname $0`/../../../.."
cmake --build .
cd ..

# mkdir release
# cd release
# cmake -GNinja -DMB_DESKTOP_BUILD=1 -DHAVE_COCOA=1 -C "`dirname $0`/../common_options.cmake" -DENABLE_PRECOMPILED_HEADERS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-Wno-implicit-fallthrough -Wno-error=return-type" "`dirname $0`/../../../.."
# cmake --build .
# cd ..
