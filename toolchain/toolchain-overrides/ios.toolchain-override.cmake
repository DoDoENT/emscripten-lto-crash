
include( ${CMAKE_CURRENT_LIST_DIR}/gcc_clang_overrides.cmake )

# Adds support for mixing Objective C and C++ code

if( ${CMAKE_CXX_COMPILER_ID} MATCHES "Clang" )
    add_compile_options( -fconstant-cfstrings -fobjc-call-cxx-cdtors )
    add_compile_options( -Qunused-arguments )
else()
    add_compile_options( -mconstant-cfstrings )
endif()

add_definitions( -DPLATFORM_IOS )

link_libraries( -ObjC++ )

set( MB_IOS_SDK "device" CACHE STRING "iOS SDK to be used" )
set_property( CACHE MB_IOS_SDK PROPERTY STRINGS "device" "simulator" "maccatalyst" )

set( CMAKE_XCODE_ATTRIBUTE_ARCHS "$(ARCHS_STANDARD)" )

if ( XCODE_VERSION VERSION_LESS "12.0.0" )
    set( CMAKE_XCODE_ATTRIBUTE_VALID_ARCHS                  "$(ARCHS_STANDARD)" )
    set( CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET   "8.0"               )
else()
    set( CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET   "9.0"               )
    set( CMAKE_XCODE_ATTRIBUTE_MACOSX_DEPLOYMENT_TARGET     "10.15"             ) # catalina (Catalyst)
endif()

set( CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES" )

# With runtime checks on iOS build succeeds, but app fails with  Library not loaded: @rpath/libclang_rt.asan_ios_dynamic.dylib
# If clang sanitizers are to be used on iOS, an Xcode session option for this should be enabled.
unset( TNUN_compiler_runtime_sanity_checks )
unset( TNUN_linker_runtime_sanity_checks )
unset( TNUN_compiler_runtime_integer_checks )
unset( TNUN_linker_runtime_integer_checks )

# Adding PP_USE_NEON preprocessor definition is implemented in common_utils in fix_xcode9_armv7_warning,
# appending to arch-specific xcode variable and combining that with global properties is not simple
# as Xcode seems to ignore flags in that way.
# i.e. setting CMAKE_XCODE_ATTRIBUTE_OTHER_CFLAGS[arch=armv7] will overwrite settings from ios.toolchain.cmake
# and appending to this variable seems to be ignored by the Xcode, especially if target has customly set
# property XCODE_ATTRIBUTE_OTHER_CFLAGS[arch=armv7]

if( NOT MB_DEV_RELEASE )
    TNUN_enable_bitcode()
endif()
