cmake_minimum_required(VERSION 3.10)

include( ${CMAKE_CURRENT_LIST_DIR}/toolchain/common_settings.cmake )

project(Test)

add_subdirectory( ${CMAKE_CURRENT_LIST_DIR}/opencv opencv )

set( gtest_disable_pthreads      ON CACHE BOOL INTERNAL FORCE )
set( gtest_hide_internal_symbols ON CACHE BOOL INTERNAL FORCE )

if ( IOS )
    add_compile_options( -Wno-ignored-optimization-argument )
endif()

if ( EMSCRIPTEN )
    add_compile_options( -Wno-unused-command-line-argument )
endif()

add_subdirectory( ${CMAKE_CURRENT_LIST_DIR}/googletest googletest )

include( ${CMAKE_CURRENT_LIST_DIR}/GTestTest/GTestTest.cmake )
