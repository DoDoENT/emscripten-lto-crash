#!/bin/sh

cmake -G "Visual Studio 14 2015" -DCMAKE_SYSTEM_NAME=WindowsStore -DCMAKE_SYSTEM_VERSION=10.0 -DBUILD_JASPER=OFF -DBUILD_PERF_TESTS=OFF -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF -DBUILD_WITH_STATIC_CRT=OFF -DBUILD_DOCS=OFF -DBUILD_OPENEXR=OFF -DBUILD_PACKAGE=OFF -DBUILD_WITH_DEBUG_INFO=OFF -DBUILD_JPEG=ON -DBUILD_PNG=ON -DBUILD_TIFF=ON -DBUILD_WITH_DYNAMIC_IPP=OFF -DBUILD_ZLIB=ON -DBUILD_opencv_apps=OFF -DBUILD_opencv_highgui=OFF -DBUILD_opencv_world=OFF -DENABLE_PRECOMPILED_HEADERS=OFF -DWITH_1394=OFF -DWITH_CUDA=OFF -DWITH_CUFFT=OFF -DWITH_DIRECTX=OFF -DWITH_DSHOW=OFF -DWITH_EIGEN=OFF -DWITH_FFMPEG=OFF -DWITH_GDAL=OFF -DWITH_GIGEAPI=OFF -DWITH_IPP=OFF -DWITH_JASPER=OFF -DWITH_OPENCL=OFF -DWITH_OPENEXR=OFF -DWITH_PVAPI=OFF -DWITH_VFW=OFF -DWITH_TIFF=ON -DWITH_VTK=OFF -DWITH_WEBP=OFF -DBUILD_opencv_ts=OFF -DWITH_VFW=OFF -DBUILD_opencv_videoio=OFF $1
