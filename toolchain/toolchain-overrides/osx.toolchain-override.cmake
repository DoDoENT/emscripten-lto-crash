
include( ${CMAKE_CURRENT_LIST_DIR}/gcc_clang_overrides.cmake )

# Adds support for mixing Objective C and C++ code

if( ${CMAKE_CXX_COMPILER_ID} MATCHES "Clang" )
    add_compile_options( -fconstant-cfstrings -fobjc-call-cxx-cdtors )
else()
    add_compile_options( -mconstant-cfstrings )
endif()

set( minimum_macos_version 10.14 )

if( ${CMAKE_GENERATOR} MATCHES "Xcode" )
    set( CMAKE_OSX_DEPLOYMENT_TARGET "${minimum_macos_version}" )

    if ( XCODE_VERSION VERSION_LESS "12.2" )
        message( FATAL_ERROR "OSX toolchain requires XCode 12.2 or newer in order to correctly build arm64 slices for ARM-based macs" )
    endif()
else()
    unset( CMAKE_OSX_DEPLOYMENT_TARGET ) # PCH problems if this is set
    add_compile_options( -mmacosx-version-min=${minimum_macos_version} )
    add_link_options( -mmacosx-version-min=${minimum_macos_version} )
endif()
