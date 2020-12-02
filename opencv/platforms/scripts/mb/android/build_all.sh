#!/bin/sh

if [ -z $ANDROID_NDK ]; then
    if [ -z $ANDROID_SDK ]; then
        export ANDROID_SDK=~/android-sdks
    fi
    export ANDROID_NDK=$ANDROID_SDK/ndk-bundle
fi

if [ -z $ocv_dir ]; then
    export ocv_dir=`dirname $0`/../../../..
fi

mkdir -p install

`dirname $0`/run_build.sh android armv7_neon
`dirname $0`/run_build.sh android armv8
`dirname $0`/run_build.sh android x86
`dirname $0`/run_build.sh android x86_64