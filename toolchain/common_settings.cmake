include_guard( GLOBAL )

cmake_minimum_required( VERSION 3.19 )  # Requires support for modern build system in Xcode

set( CMAKE_CONFIGURATION_TYPES "Debug" "Release" )

# Obtain default parameters, but do not set default flags (we need to override them)
set( TNUN_DO_NOT_ADD_DEFAULT_BUILD_FLAGS true )
include( ${CMAKE_CURRENT_LIST_DIR}/build/build_options.cmake )

# Override some default settings from build repo

if ( WIN32 ) # TODO: add detection of Windows Phone / Windows Universal platform
    include( "${CMAKE_CURRENT_LIST_DIR}/toolchain-overrides/msvc.toolchain-override.cmake" )
elseif( APPLE AND NOT iOS )
    include( "${CMAKE_CURRENT_LIST_DIR}/toolchain-overrides/osx.toolchain-override.cmake" )
elseif( ${CMAKE_SYSTEM_NAME} MATCHES "Linux" )
    include( "${CMAKE_CURRENT_LIST_DIR}/toolchain-overrides/linux.toolchain-override.cmake" )
elseif( ANDROID_TOOLCHAIN ) # TNUN android.toolchain.cmake does not define this variable, while native Android Studio toolchain does
    include( "${CMAKE_CURRENT_LIST_DIR}/toolchain-overrides/android-studio.toolchain-override.cmake" )
elseif( iOS )
    include( "${CMAKE_CURRENT_LIST_DIR}/toolchain-overrides/ios.toolchain-override.cmake" )
elseif( EMSCRIPTEN )
    include( "${CMAKE_CURRENT_LIST_DIR}/toolchain-overrides/emscripten.toolchain-override.cmake" )
else()
    # Android and iOS (crosscompiling platforms) have to specify the toolchain
    # file explicitly.
endif()

option( MB_ALLOW_EXCEPTIONS         "Allow exception support in C++ code"                           false )
option( MB_ALLOW_RTTI               "Allow Runtime Type Information in C++ code"                    false )
option( MB_DEBUG_SYMBOLS_IN_RELEASE "Generate debug symbols for easier debugging of release builds" true  )
mark_as_advanced( MB_ALLOW_EXCEPTIONS         )
mark_as_advanced( MB_ALLOW_RTTI               )
mark_as_advanced( MB_DEBUG_SYMBOLS_IN_RELEASE )

option( MB_DEV_RELEASE "Build development versions of release configurations (w/ debug symbols, asserts and runtime sanity checks, w/o LTCG)" false )

if( MB_DEV_RELEASE )
    TNUN_add_compile_options( Release ${TNUN_compiler_dev_release_flags} ${TNUN_compiler_assertions} )
    TNUN_add_compile_options( Release ${TNUN_compiler_debug_symbols}                                 )
    TNUN_add_link_options(    Release ${TNUN_linker_debug_symbols}       ${TNUN_linker_assertions}   )
    string( REPLACE "/DNDEBUG" "" CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}" )
    string( REPLACE "/DNDEBUG" "" CMAKE_C_FLAGS_RELEASE   "${CMAKE_C_FLAGS_RELEASE}"   )
    add_compile_options( $<$<CONFIG:RELEASE>:-DALLOW_ASSERT_IN_RELEASE> $<$<CONFIG:RELEASE>:-DBOOST_ENABLE_ASSERT_HANDLER> $<$<CONFIG:RELEASE>:-UNDEBUG> )

    # Note: In all assert-enabled (non-production) builds enable RTTI to be
    # able to verify casts in object hierarchies.
    #                                     Domagoj Saric (27.05.2017.)
    set( MB_ALLOW_RTTI true CACHE BOOL "" FORCE )

    set( DEFAULT_LTO OFF )
else()
    TNUN_add_compile_options( Release ${TNUN_compiler_release_flags} )
    set( DEFAULT_LTO ON )
endif()

# Note: CMake 3.9 triggers warnings when setting this variable and enables LTO on Clang/GCC even when we don't want
#       that. We prefer manual control over such optimisation.
unset( CMAKE_INTERPROCEDURAL_OPTIMIZATION )

option( MB_ENABLE_LTO "Enable Link-time optimization" ${DEFAULT_LTO} )
if( MB_ENABLE_LTO )
    TNUN_add_compile_options( Release ${TNUN_compiler_LTO} )
    TNUN_add_link_options   ( Release ${TNUN_linker_LTO} )
endif()

function( add_cxx_compile_options )
    if( ${CMAKE_GENERATOR} MATCHES "Visual Studio" )
        add_compile_options( ${ARGV} )
    else()
        foreach( arg ${ARGV} )
            add_compile_options( $<$<COMPILE_LANGUAGE:CXX>:${arg}> )
        endforeach()
    endif()
endfunction()

if( ${MB_ALLOW_EXCEPTIONS} )
    add_cxx_compile_options( ${TNUN_compiler_exceptions_on} )
    if ( EMSCRIPTEN )
        add_link_options( ${TNUN_linker_exceptions_on} )
    endif()
else()
    add_cxx_compile_options( ${TNUN_compiler_exceptions_off} )
    if ( EMSCRIPTEN )
        add_link_options( ${TNUN_linker_exceptions_off} )
    endif()
endif()

if( ${MB_ALLOW_RTTI} )
    add_cxx_compile_options( ${TNUN_compiler_rtti_on} )
else()
    add_cxx_compile_options( ${TNUN_compiler_rtti_off} )
endif()
# Note: In all assert-enabled (non-production) builds enable RTTI to be able
# to verify casts in object hierarchies.
#                                         Domagoj Saric (27.05.2017.)
add_cxx_compile_options( $<$<CONFIG:Debug>:${TNUN_compiler_rtti_on}> )

add_cxx_compile_options( ${TNUN_compiler_disable_thread_safe_init} )

# this is to prevent usage of TNUN_ prefixed macros inside our codebase
add_definitions( -DMB_NOEXCEPT_EXCEPT_BADALLOC=TNUN_NOEXCEPT_EXCEPT_BADALLOC )

if ( ${MB_DEBUG_SYMBOLS_IN_RELEASE} )
    TNUN_add_compile_options( Release ${TNUN_compiler_debug_symbols} )
    TNUN_add_link_options   ( Release ${TNUN_linker_debug_symbols}   )
endif()

TNUN_add_compile_options( Debug ${TNUN_compiler_debug_flags} ${TNUN_compiler_debug_symbols} ${TNUN_compiler_assertions} )
TNUN_add_link_options   ( Debug ${TNUN_linker_debug_flags} ${TNUN_linker_debug_symbols} ${TNUN_linker_assertions} )

TNUN_add_compile_options( Release ${TNUN_compiler_optimize_for_size} )

if( NOT ( CMAKE_SYSTEM_NAME MATCHES "Linux" AND CLANG ) )
    TNUN_add_compile_options( Release ${TNUN_compiler_fastmath} )
endif()

TNUN_add_link_options( Release ${TNUN_linker_release_flags} )

if( "${CMAKE_CFG_INTDIR}" STREQUAL "." )
    if( NOT CMAKE_BUILD_TYPE )
        message( STATUS "No build type specified, default to Release" )
        set( CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type" FORCE )
        set_property( CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" )
    endif()
endif()

include( ${CMAKE_CURRENT_LIST_DIR}/common_utils.cmake )
