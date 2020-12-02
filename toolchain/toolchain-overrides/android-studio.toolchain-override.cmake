
include( ${CMAKE_CURRENT_LIST_DIR}/gcc_clang_overrides.cmake )

if( CLANG )
    add_compile_options( -Qunused-arguments )
endif()

unset( CMAKE_CXX_STANDARD )
unset( CMAKE_C_STANDARD )

list( APPEND TNUN_compiler_LTO -fPIC )
# -Os causes error: "Optimization level must be between 0 and 3"
# https://github.com/android-ndk/ndk/issues/313
# https://github.com/android-ndk/ndk/issues/318
# https://github.com/android-ndk/ndk/issues/251
list( APPEND TNUN_linker_LTO -O3 -mllvm -inline-threshold=100 )

# __ARCH_ABI_ID__ contains identifier for current architecture
# 0 is armeabi
# 1 is armeabi-v7a
# 2 is x86
# 3 is mips
# 4 is arm64-v8a
# 5 is x86_64
# 6 is mips64
# 7 is armeabi-v7a-hardfloat

if( ANDROID_ABI STREQUAL "armeabi" )
    add_definitions( -D__ARCH_ABI_ID__=0 )
elseif( ANDROID_ABI STREQUAL "armeabi-v7a" )
    if( ${TNUN_ANDROID_ARM7_HARDFLOAT_ABI} )
        add_definitions( -D__ARCH_ABI_ID__=7 )
    else()
        add_definitions( -D__ARCH_ABI_ID__=1 )
    endif()
    if( ANDROID_ARM_NEON )
        add_definitions( -DPP_USE_NEON )
    endif()
elseif( ANDROID_ABI STREQUAL "x86" )
    add_definitions( -D__ARCH_ABI_ID__=2 )
    set( TNUN_compiler_optimize_for_size -Os )
elseif( ANDROID_ABI STREQUAL "mips" )
    add_definitions( -D__ARCH_ABI_ID__=3 )
elseif( ANDROID_ABI STREQUAL "arm64-v8a" )
    add_definitions( -D__ARCH_ABI_ID__=4 -DPP_USE_NEON_64 )
elseif( ANDROID_ABI STREQUAL "x86_64" )
    add_definitions( -D__ARCH_ABI_ID__=5 )
elseif( ANDROID_ABI STREQUAL "mips64" )
    add_definitions( -D__ARCH_ABI_ID__=6 )
endif()
