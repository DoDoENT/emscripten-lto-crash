include_guard()

add_library( CONAN_PKG::GTest INTERFACE IMPORTED )
target_link_libraries( CONAN_PKG::GTest INTERFACE gtest gtest_main )

set( SOURCES
    ${CMAKE_CURRENT_LIST_DIR}/Source/GTestTest.cpp
)

build_mobile_exe( GTestTest ${CMAKE_CURRENT_LIST_DIR} ${SOURCES} )

target_link_libraries( GTestTest PRIVATE gtest gtest_main opencv_imgcodecs )

target_include_directories( GTestTest PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/../opencv/include
    ${CMAKE_CURRENT_LIST_DIR}/../opencv/modules/core/include
    ${CMAKE_CURRENT_LIST_DIR}/../opencv/modules/imgcodecs/include
    ${CMAKE_BINARY_DIR}
)
