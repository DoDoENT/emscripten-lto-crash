@echo off
set generator=Visual Studio %1
set generator=%generator:"=%
mkdir install
mkdir %2
cd %2
cmake -G "%generator%" -DMB_DESKTOP_BUILD=1 -DBUILD_ZLIB=1 -DMB_CONAN_BUILD_LOCATION="%3" -DCONAN_EXPORTED=1 -DCMAKE_INSTALL_PREFIX="%3\install" -C "%~dp0..\common_options.cmake" "%~dp0..\..\..\.."
cd ..
cmake --build %2 --config development --target install
cmake --build %2 --config release     --target install
::cmake --build %2 --config debug       --target install
