set(the_description "Camera Calibration and 3D Reconstruction")
ocv_define_module(calib3d opencv_imgproc opencv_features2d WRAP java python)

# MB patch begin
if ( EMSCRIPTEN AND MB_EMSCRIPTEN_BACKEND STREQUAL "upstream" AND EMSCRIPTEN_VERSION VERSION_EQUAL "1.39.0" )
    # workaround for crashing compiler
    set_source_files_properties( ${CMAKE_CURRENT_LIST_DIR}/src/polynom_solver.cpp PROPERTIES COMPILE_FLAGS "-flto" )
endif()
# MB patch end
