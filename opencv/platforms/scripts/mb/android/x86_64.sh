#!/bin/sh
`dirname $0`/do_build.sh -DANDROID_ABI=x86_64 -DCMAKE_ANDROID_ARCH_ABI:STRING=x86_64 -DANDROID_PLATFORM=android-21 -DCMAKE_SYSTEM_VERSION:STRING=21 $@