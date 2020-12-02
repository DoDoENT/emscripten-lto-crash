#!/bin/sh

# set this to your local path when building
QT_PATH=/Users/dodo/Qt/5.8/clang_64

cmake -GXcode -C "`dirname $0`/../common_options.cmake" -DMB_DESKTOP_BUILD=1 -DMB_QTGUI=1 -DWITH_QT=1 -DCMAKE_MODULE_PATH=$QT_PATH/lib/cmake -DCMAKE_PREFIX_PATH="$QT_PATH/lib/cmake/Qt5Core;$QT_PATH/lib/cmake/Qt5Gui;$QT_PATH/lib/cmake/Qt5Widgets;$QT_PATH/lib/cmake/Qt5Test;$QT_PATH/lib/cmake/Qt5Concurrent;$QT_PATH/lib/cmake/Qt5OpenGL" -DBUILD_opencv_highgui=ON "`dirname $0`/../../../.."
cmake --build . --config Development
cmake --build . --config Release
