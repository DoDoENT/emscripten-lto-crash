#!/bin/sh

# shamelessly stolen from https://stackoverflow.com/questions/1215538/extract-parameters-before-last-parameter-in

param_length=$(($#-1))
all_but_last=${@:1:$param_length}
last_arg=${@:$#}

echo "Invoking cmake -GNinja -DCMAKE_TOOLCHAIN_FILE=\"$ANDROID_NDK/build/cmake/android.toolchain.cmake\" -DCMAKE_ANDROID_NDK:STRING=$ANDROID_NDK -DCMAKE_SYSROOT:STRING=$ANDROID_NDK/sysroot -DCMAKE_SYSTEM_NAME:STRING=Android $all_but_last -C \"`dirname $0`/common_options.cmake\" $last_arg"

cmake -GNinja -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" -DCMAKE_ANDROID_NDK:STRING=$ANDROID_NDK -DCMAKE_SYSROOT:STRING=$ANDROID_NDK/sysroot -DCMAKE_SYSTEM_NAME:STRING=Android $all_but_last -C "`dirname $0`/common_options.cmake" $last_arg