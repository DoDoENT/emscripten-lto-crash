# Note: CMake support is community-based. The maintainers do not use CMake
# internally.

cmake_minimum_required(VERSION 2.8.8)

if (POLICY CMP0048)
  cmake_policy(SET CMP0048 NEW)
endif (POLICY CMP0048)

project(googletest-distribution)
set(GOOGLETEST_VERSION 1.10.0)

enable_testing()

include(CMakeDependentOption)
include(GNUInstallDirs)

#Note that googlemock target already builds googletest
option(BUILD_GMOCK "Builds the googlemock subproject" ON)
option(INSTALL_GTEST "Enable installation of googletest. (Projects embedding googletest may want to turn this OFF.)" ON)

if ( ANDROID )
    option(GTEST_REDIRECT_OUTPUT_TO_ANDROID_LOG "Redirect GTest output to Android Log" OFF)

    if( GTEST_REDIRECT_OUTPUT_TO_ANDROID_LOG )
        add_definitions( -DGTEST_REDIRECT_TO_ANDROID_LOG )
    endif()
endif()

# if ( EMSCRIPTEN_VERSION STREQUAL "2.0.9" AND MB_EMSCRIPTEN_BACKEND STREQUAL "upstream" )
#     # workaround for LTO crash when linking with OpenCV imgcodecs
    add_compile_options( -fexceptions )
# endif()

if(BUILD_GMOCK)
  add_subdirectory( googlemock )
else()
  add_subdirectory( googletest )
endif()
