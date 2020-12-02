if( NOT COMMON_UTILS_INCLUDED )

    set( COMMON_UTILS_INCLUDED true )

    set( COMMON_UTILS_DIR ${CMAKE_CURRENT_LIST_DIR} )

    include(${CMAKE_CURRENT_LIST_DIR}/build/pch.cmake)
    include( ${CMAKE_CURRENT_LIST_DIR}/getsubdirs.cmake )

    macro( is_android_compat_required required )
        if( ANDROID_PLATFORM )
            if( NOT DEFINED ANDROID_COMPAT_REQUIRED )
                # if targeting android-21 or newer, we need to add androidCompat.c
                string( REPLACE "android-" "" API_LEVEL ${ANDROID_PLATFORM} )
                if( ${API_LEVEL} GREATER 21 OR ${API_LEVEL} EQUAL 21 )
                    if( DEFINED ANDROID_NDK_RELEASE AND ( ${ANDROID_NDK_REVISION} VERSION_GREATER "140" OR ${ANDROID_NDK_REVISION} VERSION_EQUAL "140" ) AND ANDROID_UNIFIED_HEADERS )
                        message( STATUS "Using unified headers from NDK r14 or newer - androidCompat.c is not required" )
                        set( ANDROID_COMPAT_REQUIRED FALSE )
                    else()
                        # however, if targeting 64-bit ABI, then ANDROID_PLATFORM cannot be less than 21 and androidCompat.c is not required as 64-bit
                        # devices are supported only by Android 5.0 and newer
                        if( ANDROID_ABI STREQUAL "armeabi" OR
                            ANDROID_ABI STREQUAL "armeabi-v7a" OR
                            ANDROID_ABI STREQUAL "x86" OR
                            ANDROID_ABI STREQUAL "mips"
                          )
                            message( STATUS "Using android platform ${ANDROID_PLATFORM} with 32-bit ABI. Need to add androidCompat.c for compatibility with older Androids." )
                            set( ANDROID_COMPAT_REQUIRED TRUE )
                        else()
                            message( STATUS "Using android platform ${ANDROID_PLATFORM} with 64-bit ABI. No need for androidCompat.c" )
                            set( ANDROID_COMPAT_REQUIRED FALSE )
                        endif()
                    endif()
                else()
                    message( STATUS "Using android platform ${ANDROID_PLATFORM}. No need for androidCompat.c" )
                    set( ANDROID_COMPAT_REQUIRED FALSE )
                endif()
            endif()
            set( ${required} ${ANDROID_COMPAT_REQUIRED} )
        else()
            set( ${required} FALSE )
        endif()
    endmacro()

    if( ANDROID AND NOT TARGET android_compat )
        is_android_compat_required( need_android_compat )
        if( need_android_compat )
            add_library( android_compat STATIC ${COMMON_UTILS_DIR}/androidCompat.c )
        endif()
    endif()

    macro( __get_sources_from_dir result current_source_dir dir source_script )
        # message(STATUS "Scanning dir ${dir}")
        file(GLOB _sources "${dir}/*.cpp" "${dir}/*.c" "${dir}/*.glsl" "${dir}/*.m" "${dir}/*.mm")
        file(GLOB _headers "${dir}/*.hpp" "${dir}/*.h")
        set(_allFiles ${_sources} ${_headers})
        # exclude patterns from ARGV3
        foreach(exclude ${ARGV4})
            foreach(file ${_allFiles})
                string(REGEX REPLACE "${current_source_dir}/" "" file_relative_path ${file})
                if(${file_relative_path} MATCHES ${exclude})
                    # message(STATUS "Excluding ${file}")
                    list(REMOVE_ITEM _allFiles ${file})
                endif()
            endforeach()
        endforeach()

    #    message(STATUS "Found sources: ${_sources}")
        list(APPEND ${result} ${_allFiles})

        # generate source group name
        string(REPLACE "${current_source_dir}/" "" group_name_one ${dir})
        string(REPLACE "/" "\\" group_name ${group_name_one})
        # message(STATUS "Generating group with name ${group_name}")
        source_group("${group_name}" FILES ${_allFiles})

        #message(STATUS "Appending ${_sources}")

        # Now, update source_script
        set( _allFiles "" )
        # do another globbing so that excluded files are not missed now
        file( GLOB _allFiles "${dir}/*.cpp" "${dir}/*.hpp" "${dir}/*.c" "${dir}/*.h" "${dir}/*.glsl" "${dir}/*.hlsl" "${dir}/*.m" "${dir}/*.mm" )
        list( SORT _allFiles )
        string( REPLACE "\\" "_" group_var_name ${group_name} )
        string( REPLACE "\\" "\\\\" group_name_in_code ${group_name} )
        set( ${source_script} "${${source_script}}\nset( ${group_var_name}\n" )
        foreach( file ${_allFiles} )
            string(REGEX REPLACE "${current_source_dir}/" "" file_relative_path ${file})
            set( ${source_script} "${${source_script}}    \${CMAKE_CURRENT_LIST_DIR}/${file_relative_path}\n")
        endforeach()
        set( ${source_script} "${${source_script}})\nsource_group( \"${group_name_in_code}\" FILES \${${group_var_name}} )\nlist( APPEND SOURCES \${${group_var_name}} )\n" )

        subdirlist(subdirs ${dir})
        foreach(subdir ${subdirs})
            __get_sources_from_dir( ${result} ${current_source_dir} ${subdir} ${source_script} "${ARGV4}" )
        endforeach()
    endmacro()

    macro(get_sources_from_dir result current_source_dir dir)
        message( AUTHOR_WARNING "Function get_sources_from_dir is deprecated. Please include source list directly!" )
        set( source_script "set( SOURCES \"\" )\n" )
        __get_sources_from_dir( ${result} ${current_source_dir} ${dir} source_script "${ARGV3}" )

        # extract project name from current_source_dir
        get_filename_component( project_name ${current_source_dir} NAME )
        file( WRITE ${CMAKE_CURRENT_BINARY_DIR}/${project_name}.srcs.cmake ${source_script} )
        message( AUTHOR_WARNING "Automatically generated source list has been written to ${CMAKE_CURRENT_BINARY_DIR}/${project_name}.srcs.cmake" )
    endmacro()

    macro( setup_log_level output name allow_default )
        if( ${allow_default} )
            set( ${name}_LOG_LEVEL "LOG_DEFAULT" CACHE STRING "Log level for ${name}" )
            set_property( CACHE ${name}_LOG_LEVEL PROPERTY STRINGS "LOG_DEFAULT" "LOG_STFU" "LOG_WARNINGS_AND_ERRORS" "LOG_INFO" "LOG_DEBUG" "LOG_VERBOSE" )
        else()
            set( ${name}_LOG_LEVEL "LOG_WARNINGS_AND_ERRORS" CACHE STRING "Log level" )
            set_property( CACHE ${name}_LOG_LEVEL PROPERTY STRINGS "LOG_STFU" "LOG_WARNINGS_AND_ERRORS" "LOG_INFO" "LOG_DEBUG" "LOG_VERBOSE" )
        endif()

        set( LOG_LEVEL_INT 0 )
        if( ${${name}_LOG_LEVEL} STREQUAL "LOG_STFU" )
            set( LOG_LEVEL_INT -1 )
        elseif( ${${name}_LOG_LEVEL} STREQUAL "LOG_WARNINGS_AND_ERRORS" )
            set( LOG_LEVEL_INT 0 )
        elseif( ${${name}_LOG_LEVEL} STREQUAL "LOG_INFO" )
            set( LOG_LEVEL_INT 1 )
        elseif( ${${name}_LOG_LEVEL} STREQUAL "LOG_DEBUG" )
            set( LOG_LEVEL_INT 2 )
        elseif( ${${name}_LOG_LEVEL} STREQUAL "LOG_VERBOSE" )
            set( LOG_LEVEL_INT 3 )
        elseif( ${${name}_LOG_LEVEL} STREQUAL "LOG_DEFAULT" )
            set( LOG_LEVEL_INT -100 ) # Not used anyway
        else()
            message( FATAL_ERROR "Unknown log level ${${name}_LOG_LEVEL}" )
        endif()

        set( ${output} ${LOG_LEVEL_INT} )
    endmacro()

    macro( set_timer_enabled name allow_default )
        if( ${allow_default} )
            option( ${name}_ENABLE_TIMER "Enable timer for performance analysis in ${name}" off )
        else()
            option( ${name}_ENABLE_TIMER "Enable timer for performance analysis" off )
        endif()
    endmacro()

    set( FILENAME_LOG_DEFAULT OFF )
    if( CMAKE_BUILD_TYPE STREQUAL "Debug" OR MB_DEV_RELEASE )
        set( FILENAME_LOG_DEFAULT ON )
    endif()
    option( MB_FILENAME_IN_LOG "Show filename when outputting log" ${FILENAME_LOG_DEFAULT} )

    option( MB_TREAT_WARNINGS_AS_ERRORS "Treat all warnings as errors" OFF )

    macro( enable_warnings target )
        target_compile_options( ${target} PRIVATE ${TNUN_default_warnings} )
        if( ${MB_TREAT_WARNINGS_AS_ERRORS} )
            target_compile_options( ${target} PRIVATE ${TNUN_warnings_as_errors} )
        endif()
        target_compile_options( ${target} PRIVATE ${TNUN_disabled_warnings} )
    endmacro()

    macro( fix_xcode9_armv7_warning target )
        # -fomit-frame-pointer apparently was never supported for armv7 and armv7s, however it was silently ignored
        # from XCode9 on, attempt to enable it causes compile warning: https://lists.llvm.org/pipermail/cfe-commits/Week-of-Mon-20160822/168796.html
        if( iOS )
            set_target_properties(
                ${target}
                PROPERTIES
                    XCODE_ATTRIBUTE_OTHER_CFLAGS[arch=armv7]  "$(OTHER_CFLAGS) $<$<CONFIG:RELEASE>:-fno-omit-frame-pointer> -DPP_USE_NEON"
                    XCODE_ATTRIBUTE_OTHER_CFLAGS[arch=armv7s] "$(OTHER_CFLAGS) $<$<CONFIG:RELEASE>:-fno-omit-frame-pointer> -DPP_USE_NEON"
                    XCODE_ATTRIBUTE_OTHER_FLAGS[arch=arm64] "$(OTHER_CFLAGS) -DPP_USE_NEON_64"
                    XCODE_ATTRIBUTE_OTHER_CPLUSPLUSFLAGS[arch=armv7]  "$(OTHER_CPLUSPLUSFLAGS) $<$<CONFIG:RELEASE>:-fno-omit-frame-pointer> -DPP_USE_NEON"
                    XCODE_ATTRIBUTE_OTHER_CPLUSPLUSFLAGS[arch=armv7s] "$(OTHER_CPLUSPLUSFLAGS) $<$<CONFIG:RELEASE>:-fno-omit-frame-pointer> -DPP_USE_NEON"
                    XCODE_ATTRIBUTE_OTHER_CPLUSPLUSFLAGS[arch=arm64] "$(OTHER_CPLUSPLUSFLAGS) -DPP_USE_NEON_64"
            )
        endif()
    endmacro()

    set( default_runtime_checks OFF )
    if( CMAKE_BUILD_TYPE STREQUAL "Debug" OR MB_DEV_RELEASE )
        # Note: In all assert-enabled builds we will obtain conan packages built with
        # enabled runtime checks. So make sure runtime checks are enabled here as well,
        # in order to prevent crashes or false positives in ASan.
        set( default_runtime_checks ON )
    endif()

    option( MB_ENABLE_RUNTIME_CHECKS "Enable runtime sanity checks" ${default_runtime_checks} )

    macro( enable_runtime_checks target )
        if( MSVC )
            foreach( compiler_flag ${TNUN_compiler_runtime_sanity_checks} )
                target_compile_options( ${target} PRIVATE $<$<CONFIG:DEBUG>:${compiler_flag}> )
            endforeach()
            foreach( linker_flag ${TNUN_linker_runtime_sanity_checks} )
                target_link_libraries( ${target} PUBLIC $<$<CONFIG:DEBUG>:${linker_flag}> )
            endforeach()
            # Implementation note: MSVC's 'smaller type' check causes FP errors
            # in Eigen code.
            #                                 (22.03.2017. Domagoj Saric)
            foreach( compiler_flag ${TNUN_compiler_dbg_only_runtime_sanity_checks} )
                target_compile_options( ${target} PRIVATE $<$<CONFIG:DEBUG>:${compiler_flag}> )
            endforeach()
        else()
            if( MB_ENABLE_RUNTIME_CHECKS )
                target_compile_options( ${target} PRIVATE ${TNUN_compiler_runtime_sanity_checks} ${TNUN_compiler_dbg_only_runtime_sanity_checks} ${TNUN_compiler_runtime_integer_checks} )
                target_link_libraries( ${target} PUBLIC ${TNUN_linker_runtime_sanity_checks} ${TNUN_linker_runtime_integer_checks} )
            endif()
        endif()
    endmacro()

    option( MB_CODE_COVERAGE "Enable code coverage reporting" OFF )

    macro( setup_code_coverage target )
        if( MB_CODE_COVERAGE )
            target_compile_options( ${target} PRIVATE ${TNUN_code_coverage_compiler_flags} )
            target_link_libraries( ${target} PRIVATE ${TNUN_code_coverage_compiler_flags} )
        endif()
    endmacro()

    macro( enable_include_checks target )
        if( MB_INCLUDE_WHAT_YOU_USE )
            message( "Enabling IWYU with command line: ${MB_INCLUDE_WHAT_YOU_USE}" )
            set_target_properties( ${target} PROPERTIES CXX_INCLUDE_WHAT_YOU_USE "${MB_INCLUDE_WHAT_YOU_USE}" )
        endif()
    endmacro()

    macro( make_universal target )
        message( AUTHOR_WARNING "make_universal no longer works. Please migrate build scripts to separate ios/simulator/catalyst builds" )
    endmacro()

    if ( CMAKE_STRIP )
        option( MB_STRIP_FINAL_BINARY "Should original binary be stripped (this should be enabled for distribution builds)." OFF )
        if ( NOT MB_STRIP_FINAL_BINARY )
            option( MB_CREATE_STRIPPED_BINARY "Should create stripped binary, side-by-side to the original, unstripped one" OFF )
            mark_as_advanced( MB_CREATE_STRIPPED_BINARY )
        endif()
    endif()

    macro( strip target )
        if ( CMAKE_STRIP )
            # special case for android distribution builds and for the needs of Crashlytics
            if( ANDROID AND ANDROID_NDK_BUILD_OUTPUT )
                # Copy non-stripped library to ${ANDROID_NDK_BUILD_OUTPUT}/obj/local/${ANDROID_ABI}/
                set( NDK_NON_STRIPPED_PATH "${ANDROID_NDK_BUILD_OUTPUT}/obj/local/${ANDROID_ABI}/" )
                add_custom_command( TARGET ${target} POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E make_directory ${NDK_NON_STRIPPED_PATH}
                    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${target}> ${NDK_NON_STRIPPED_PATH}
                    COMMENT "Copying non-stripped binary to ${NDK_NON_STRIPPED_PATH}"
                    VERBATIM )

                set( NDK_STRIPPED_PATH "${ANDROID_NDK_BUILD_OUTPUT}/lib/${ANDROID_ABI}/" )
                add_custom_command( TARGET ${target} POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E make_directory ${NDK_STRIPPED_PATH}
                    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${target}> ${NDK_STRIPPED_PATH}
                    COMMAND ${CMAKE_STRIP} -x ${NDK_STRIPPED_PATH}/$<TARGET_FILE_NAME:${target}>
                    COMMENT "Creating stripped binary in ${NDK_STRIPPED_PATH}"
                    VERBATIM )
            else()
                if ( MB_STRIP_FINAL_BINARY)
                    add_custom_command( TARGET ${target} POST_BUILD
                        COMMAND ${CMAKE_STRIP} -x $<TARGET_FILE:${target}>
                        COMMENT "Stripping binary ${targetName}"
                        VERBATIM )
                else() # do not strip the original binary (required to support debugging)
                    if ( MB_CREATE_STRIPPED_BINARY )
                        # create stripped binary next to the original one
                        set( STRIPPED_BINARY_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/strippedBinaries )
                        add_custom_command( TARGET ${target} POST_BUILD
                            COMMAND ${CMAKE_COMMAND} -E make_directory ${STRIPPED_BINARY_LOCATION}
                            COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${target}> ${STRIPPED_BINARY_LOCATION}
                            COMMAND ${CMAKE_STRIP} -x ${STRIPPED_BINARY_LOCATION}/$<TARGET_FILE_NAME:${target}>
                            COMMENT "Creating stripped binary for ${targetName}"
                            VERBATIM )
                    endif()
                endif()
            endif()
        endif()
    endmacro()

    macro( target_add_tool_specific_flags target )
        # Note: At the moment, enabling asserts for tools requires fixes at least in Err, MMap and ConcurrentQueue.
        # Othervise it causes ODR violations or compile errors.
        #
        #           (Nenad Miksa) (03.02.2020.)
        target_compile_options( ${target} PRIVATE
            ${TNUN_compiler_precisemath}
            ${TNUN_compiler_disable_LTO}

            # This will allow asserts, but requires at least LogAndTimer/1.3.2@microblink/stable, otherwise you will get linker error
            # $<$<CONFIG:RELEASE>:-DALLOW_ASSERT_IN_RELEASE>
            # $<$<CONFIG:RELEASE>:-DBOOST_ENABLE_ASSERT_HANDLER>
            # Note: -UNDEBUG is not given due to possible ODR violations
        )
    endmacro()

    option( MB_ALLOW_STATIC_EXECUTABLES "Allow creation of static executables, if they are supported" OFF )
    mark_as_advanced( MB_ALLOW_STATIC_EXECUTABLES )

    macro( make_static_executable exename )
        if ( CMAKE_SYSTEM_NAME MATCHES "Linux" AND NOT MB_ENABLE_RUNTIME_CHECKS AND MB_ALLOW_STATIC_EXECUTABLES )
            target_link_libraries( ${exename} PRIVATE -static )
            if( ${TNUN_CPP_LIBRARY} STREQUAL "stdc++" )
                target_link_libraries( ${exename} PRIVATE -static-libstdc++ -static-libgcc )
            elseif( ${TNUN_CPP_LIBRARY} STREQUAL "libc++" )
                target_link_libraries( ${exename} PRIVATE -s c++ pthread dl c++abi unwind c dl m )
            endif()
        endif()
    endmacro()

    macro( define_src_path target current_source_dir )
        target_compile_definitions( ${target} PRIVATE "__CURRENT_SRC_PATH__=\"${current_source_dir}/..\"" )
    endmacro()

    macro( mb_target_precompiled_header target header )
        if( MB_USE_PCH )
            if ( ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.16.0" )
                message( AUTHOR_WARNING "mb_target_precompiled_header is deprecated and should be replaced with more versatile target_precompile_headers, available from CMake v3.16" )
                target_compile_definitions( ${target} PRIVATE "USING_PCH" ) # NOTE: Added for backward compatibility with project that expect that.
                target_precompile_headers( ${target} PRIVATE ${header} )
            else()
                message( WARNING "Using CMake v${CMAKE_VERSION} with enabled precompiled headers. For best support, consider upgrading CMake to at least v3.16!" )
                target_compile_definitions( ${target} PRIVATE "USING_PCH" )
                if( ${CMAKE_GENERATOR} MATCHES "Visual Studio" )
                    # create ${header}.cpp to make VS happy
                    get_filename_component( header_file ${header} NAME )
                    get_filename_component( header_file_we ${header} NAME_WE )
                    get_filename_component( pch_dir ${header} DIRECTORY )
                    file( MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${target}-pch )
                    file( WRITE ${CMAKE_CURRENT_BINARY_DIR}/${target}-pch/${header_file_we}.cpp "#include <${header_file}>\n" )
                    target_sources( ${target} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/${target}-pch/${header_file_we}.cpp )
                    target_include_directories( ${target} PRIVATE ${pch_dir} )
                endif()
                add_precompiled_header( ${target} ${header} FORCEINCLUDE ${ARGN} )
            endif()
        endif()
    endmacro()

    macro( target_precompiled_header target header )
        message( AUTHOR_WARNING "target_precompiled_header is deprecated. Please use mb_target_precompiled_header" )
        mb_target_precompiled_header( ${target} ${header} ${ARGN} )
    endmacro()

    macro( force_include_header target header )
        if( MSVC )
            target_compile_options( ${target} PRIVATE "-FI${header}" )
        else()
            target_compile_options( ${target} PRIVATE "-include${header}" )
        endif()
    endmacro()

    macro( ban_unsafe_functions target )
        if( MB_BANNED_HEADER )
            # On Xcode PCH gets force-included after the banned header, which causes error: "PCH was ignored because it's not the first -include"
            # On MSVC we get error while parsing the banned header (actually a deprecation warning, treated as error.) On MSVC it is not possible
            # to treat warnings as errors while keep treating a single warning (deprecated function) as warning.
            if ( NOT ${CMAKE_GENERATOR} STREQUAL "Xcode" AND NOT MSVC )
                force_include_header( ${target} ${MB_BANNED_HEADER} )
            endif()
        endif()
    endmacro()

    macro( add_android_compat target )
        is_android_compat_required( need_android_compat )
        if( need_android_compat )
            target_link_libraries( ${target} PUBLIC -Wl,--whole-archive android_compat -Wl,--no-whole-archive )
        endif()
    endmacro()

    if( NOT CMAKE_CROSSCOMPILING )
        option( MB_GENERATE_ANDROID_STUDIO_EXE_WRAPPER "For each mobile executable, generate Android Studio runner project to ease debugging and profiling" OFF )
        if ( MB_GENERATE_ANDROID_STUDIO_EXE_WRAPPER )
            option( MB_ANDROID_STUDIO_ADD_AUTORUN_SUPPORT "When generating Android Studio runner project, add support for auto-run it. The parameters for running will be loaded from parameters.txt file from internal storage of the app." OFF)
            set( MB_ANDROID_STUDIO_ABI_FILTER "armeabi-v7a arm64-v8a" CACHE STRING "ABI filters for Android Studio runner projects" )
            set_property( CACHE MB_ANDROID_STUDIO_ABI_FILTER PROPERTY STRINGS "armeabi-v7a arm64-v8a" "armeabi-v7a" "arm64-v8a" "armeabi-v7a arm64-v8a x86 x86_64" )

            # detect latest available NDK version and set that to default
            # if variable already exists, do not detect anything, to save some time
            if ( NOT MB_ANDROID_STUDIO_SELECTED_NDK_VERSION )
                # install latest AndroidNdk from conan
                execute_process(
                    COMMAND
                        conan search -r all AndroidNdk
                    OUTPUT_VARIABLE
                        search_result
                )
                message( "AndroidNdk conan search result:\n${search_result}" )
                string( REGEX MATCHALL "AndroidNdk\/r[0-9]+[a-z]?@microblink/stable" ndk_versions "${search_result}" )
                message( "NDK matches: ${ndk_versions}" )
                # obtain the last version printed (should be the latest)
                list( GET ndk_versions -1 desired_ndk_version )

                set( MB_ANDROID_STUDIO_SELECTED_NDK_VERSION ${desired_ndk_version} CACHE STRING "Selected NDK version to be used with generated Android studio wrapper projects" )
                set_property( CACHE MB_ANDROID_STUDIO_SELECTED_NDK_VERSION PROPERTY STRINGS ${ndk_versions} )
            endif()

            set( MB_ANDROID_STUDIO_TEST_BUILD_TYPE "release" CACHE STRING "Build type for which JUnit tests will be executed" )
            set_property( CACHE MB_ANDROID_STUDIO_TEST_BUILD_TYPE PROPERTY STRINGS "debug" "release" "distribute" )

            option( MB_ANDROID_STUDIO_BUILD_ALL_TARGETS "Build all cmake targets in generated Android Studio project (this is required if multiple DLLs need to be deployed to the app)" OFF )

        endif()
    endif()

    set( DEPLOYED_TEST_DATA_DIR        "res-data"        )
    set( DEPLOYED_SRC_DATA_DIR         "res-src"         )
    set( DEPLOYED_BUILD_DATA_DIR       "res-build"       )
    set( DEPLOYED_SECURE_TEST_DATA_DIR "res-secure-data" )

    function( get_data_file_destination result copy_lazy real_data_path_out data_file )
        get_filename_component( real_data_path ${data_file} ABSOLUTE )
        set( ${real_data_path_out} ${real_data_path} PARENT_SCOPE )

        string( FIND "${data_file}" "${MB_TEST_DATA_PATH}" test_data_path_pos )
        if( ${test_data_path_pos} GREATER -1 )
            # ${data_file} is inside test-data
            file( RELATIVE_PATH rel_data_file ${MB_TEST_DATA_PATH} ${data_file} )
            get_filename_component( rel_data_dir ${rel_data_file} DIRECTORY )
            set( ${result} "${DEPLOYED_TEST_DATA_DIR}/${rel_data_dir}" PARENT_SCOPE ) # PARENT_SCOPE required because of function
            set( ${copy_lazy} FALSE PARENT_SCOPE ) # test-data files must exist at configure time
            return() # return does not work with macro
        endif()

        if ( MB_SECURE_TEST_DATA_PATH )
            string( FIND "${data_file}" "${MB_SECURE_TEST_DATA_PATH}" secure_test_data_path_pos )
            if( ${secure_test_data_path_pos} GREATER -1 )
                # ${data_file} is inside secure test-data
                file( RELATIVE_PATH rel_data_file ${MB_SECURE_TEST_DATA_PATH} ${data_file} )
                get_filename_component( rel_data_dir ${rel_data_file} DIRECTORY )
                set( ${result} "${DEPLOYED_SECURE_TEST_DATA_DIR}/${rel_data_dir}" PARENT_SCOPE ) # PARENT_SCOPE required because of function
                set( ${copy_lazy} FALSE PARENT_SCOPE ) # secure test-data files must exist at configure time
                return() # return does not work with macro
            endif()
        endif()

        string( FIND "${data_file}" "${CMAKE_CURRENT_BINARY_DIR}" build_path_pos )
        if( ${build_path_pos} GREATER -1 )
            file( RELATIVE_PATH rel_data_file ${CMAKE_CURRENT_BINARY_DIR} ${data_file} )
            get_filename_component( rel_data_dir ${rel_data_file}/ DIRECTORY )
            set( ${result} "${DEPLOYED_BUILD_DATA_DIR}/${rel_data_dir}" PARENT_SCOPE )
            set( ${copy_lazy} TRUE PARENT_SCOPE ) # binary files do not exist at configure time
            return()
        endif()

        if( CMAKE_HOST_BINARY_DIR )
            string( FIND "${data_file}" "${CMAKE_HOST_BINARY_DIR}" host_bin_path_pos )
            if( ${host_bin_path_pos} GREATER -1 )
                file( RELATIVE_PATH rel_data_file ${CMAKE_HOST_BINARY_DIR} ${data_file} )
                get_filename_component( rel_data_dir ${rel_data_file} DIRECTORY )
                set( ${result} "${DEPLOYED_BUILD_DATA_DIR}/${rel_data_dir}" PARENT_SCOPE )
                set( ${copy_lazy} FALSE PARENT_SCOPE ) # host binary files must exist at configure time
                return()
            endif()
        endif()

        string( FIND "${data_file}" "${CMAKE_SOURCE_DIR}" src_path_pos )
        if( ${src_path_pos} GREATER -1 )
            file( RELATIVE_PATH rel_data_file ${CMAKE_SOURCE_DIR} ${data_file} )
            get_filename_component( rel_data_dir ${rel_data_file} DIRECTORY )
            set( ${result} "${DEPLOYED_SRC_DATA_DIR}/${rel_data_dir}" PARENT_SCOPE )
            set( ${copy_lazy} FALSE PARENT_SCOPE ) # source files must exist at configure time
            return()
        endif()

        if( ANDROID_STUDIO_WRAPPED_EXE AND ANDROID_HOST_SOURCE_DIR )
            string( FIND "${data_file}" "${ANDROID_HOST_SOURCE_DIR}" src_path_pos )
            if( ${src_path_pos} GREATER -1 )
                file( RELATIVE_PATH rel_data_file ${ANDROID_HOST_SOURCE_DIR} ${data_file} )
                get_filename_component( rel_data_dir ${rel_data_file} DIRECTORY )
                set( ${result} "${DEPLOYED_SRC_DATA_DIR}/${rel_data_dir}" PARENT_SCOPE )
                set( ${copy_lazy} FALSE PARENT_SCOPE ) # source files must exist at configure time
                return()
            endif()
        endif()

        message( FATAL_ERROR "Cannot obtain data file destination for ${real_data_path}" )

    endfunction()

    macro( prepare_data_files_for_device data_dirs target data_files )
        set( RESOURCE_ROOT ${CMAKE_CURRENT_BINARY_DIR} )
        if( ANDROID_STUDIO_WRAPPED_EXE )
            set( RESOURCE_ROOT ${CMAKE_HOST_BINARY_DIR} )
        endif()
        # prepare folders where ${data_files} will be copied prior deployment to device
        set( ${data_dirs}    "${RESOURCE_ROOT}/${target}-res/${DEPLOYED_SRC_DATA_DIR}"
                             "${RESOURCE_ROOT}/${target}-res/${DEPLOYED_BUILD_DATA_DIR}"
                             "${RESOURCE_ROOT}/${target}-res/${DEPLOYED_TEST_DATA_DIR}"
                             "${RESOURCE_ROOT}/${target}-res/${DEPLOYED_SECURE_TEST_DATA_DIR}"
        )
        file( MAKE_DIRECTORY ${${data_dirs}} )
        # Will be either empty or it will contain libraries on which test depends
        file( MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${target}-libs" )

        foreach( data_file ${data_files} )
            get_data_file_destination( destination copy_lazy real_data_path ${data_file} )
            set( final_dest "${RESOURCE_ROOT}/${target}-res/${destination}" )
            file( MAKE_DIRECTORY ${final_dest} )
            list( FIND ${target}_copied_files ${real_data_path} pos )
            if( ${pos} EQUAL -1 )
                list( APPEND ${target}_copied_files ${real_data_path} )
                if( CMAKE_HOST_UNIX )
                    # follow symlinks if on Unix
                    set( copy_command cp -RL "${data_file}" "${final_dest}" )
                else()
                    get_filename_component( data_file_name ${data_file} NAME )
                    string( FIND "${data_file_name}" "." extension_delimiter )
                    if ( extension_delimiter EQUAL -1 )
                        set( copy_command "${CMAKE_COMMAND}" -E copy_directory "${data_file}" "${final_dest}/${data_file_name}" )
                    else()
                        set( copy_command "${CMAKE_COMMAND}" -E copy "${data_file}" "${final_dest}" )
                    endif()
                endif()
                if( copy_lazy ) # copy during build of ${target}
                    add_custom_command( TARGET ${target} PRE_BUILD COMMAND ${copy_command} )
                else() # copy immediately
                    execute_process( COMMAND ${copy_command} OUTPUT_VARIABLE ouvar ERROR_VARIABLE errout )
                endif()
            endif()
        endforeach()
        if( EMSCRIPTEN )
            # preloading empty directory tree fails with emscripten
            file( GLOB_RECURSE files LIST_DIRECTORIES false ${RESOURCE_ROOT}/${target}-res/* )
            list( LENGTH files num_files )
            if ( num_files GREATER 0 )
                target_link_options( ${target} PRIVATE "SHELL:--preload-file ${RESOURCE_ROOT}/${target}-res@/" )
            endif()
        endif()
    endmacro()


    macro( set_target_resources target )
        prepare_data_files_for_device( data_dirs ${target} "${ARGN}" )
        if ( iOS )
          target_sources( ${target} PRIVATE ${data_dirs} )
          # ${data_dirs} must be added to target ${exename}Host so that XCode can pack it into an app bundle
          set_source_files_properties( ${data_dirs} PROPERTIES MACOSX_PACKAGE_LOCATION Resources GENERATED YES )
        endif()
    endmacro()

    macro( conan_android_ndk ANDROID_NDK )

        message( "Will install NDK ${MB_ANDROID_STUDIO_SELECTED_NDK_VERSION}" )
        execute_process(
            COMMAND
                conan install ${MB_ANDROID_STUDIO_SELECTED_NDK_VERSION}
        )
        # now obtain location of installed NDK version
        execute_process(
            COMMAND
                conan info --paths ${MB_ANDROID_STUDIO_SELECTED_NDK_VERSION}
            OUTPUT_VARIABLE
                ndk_conan_info
        )
        message( "Android NDK Conan info:\n${ndk_conan_info}" )
        string( REGEX MATCH "package_folder: *([A-Za-z]:)?[a-zA-Z0-9\\./_ -]+" ndk_location "${ndk_conan_info}" )
        string( REGEX REPLACE "package_folder: *" "" ${ANDROID_NDK} "${ndk_location}" )

        # fix windows paths
        string( REPLACE "\\" "/" ${ANDROID_NDK} "${${ANDROID_NDK}}" )
        message( "Will use Android NDK: '${${ANDROID_NDK}}'" )
    endmacro()

    if( ( NOT CMAKE_CROSSCOMPILING ) AND MB_GENERATE_ANDROID_STUDIO_EXE_WRAPPER )
        # determine latest SDK version
        if ( NOT ANDROID_SDK )
            if ( EXISTS "$ENV{ANDROID_SDK}" )
                set( ANDROID_SDK "$ENV{ANDROID_SDK}" CACHE PATH "Path to Android SDK" )
            else()
                set( ANDROID_SDK "$ENV{ANDROID_SDK_HOME}" CACHE PATH "Path to Android SDK" )
            endif()
        endif()

        if ( NOT EXISTS "${ANDROID_SDK}" )
            message( FATAL_ERROR "Unable to detect path to Android SDK. Please either set ANDROID_SDK environment variable or set ANDROID_SDK CMake variable to correct path of your Android SDK installation!" )
        endif()

        set( ANDROID_BUILD_TOOLS_VERSION "30.0.0" )
        set( ANDROID_LATEST_SDK 29 )

        if ( EXISTS "${ANDROID_SDK}" )
            set( FILE_SEPARATOR "/" )

            subdirlist( build_tool_versions "${ANDROID_SDK}/build-tools" )
            list( SORT build_tool_versions )
            list( GET build_tool_versions -1 latest_build_version ) # take last element - greatest version number
            string( REPLACE "${ANDROID_SDK}${FILE_SEPARATOR}build-tools${FILE_SEPARATOR}" "" ANDROID_BUILD_TOOLS_VERSION ${latest_build_version} )

            subdirlist( android_platforms "${ANDROID_SDK}/platforms" )
            list( SORT android_platforms )
            list( GET  android_platforms -1 latest_platform )
            string( REPLACE "${ANDROID_SDK}${FILE_SEPARATOR}platforms${FILE_SEPARATOR}android-" "" ANDROID_LATEST_SDK ${latest_platform} ) # take last element - greatest version number

            message( STATUS "Detected android build tools ${ANDROID_BUILD_TOOLS_VERSION} and SDK version ${ANDROID_LATEST_SDK}" )
        else()
            # set default SDK and build tools versions (in case of non-existing ANDROID_SDK)
            message( WARNING "
                Unable to detect Android SDK location from ANDROID_SDK_HOME environment variable.
                Please set the ANDROID_SDK CMake variable to correct location of your Android SDK. Until that,
                AS runner project will use build tools \"${ANDROID_BUILD_TOOLS_VERSION}\" and SDK version ${ANDROID_LATEST_SDK}." )
        endif()

        if ( NOT ANDROID_NDK )
            if ( $ENV{ANDROID_NDK} )
                set( ANDROID_NDK "$ENV{ANDROID_SDK}" )
            else()
                conan_android_ndk( ANDROID_NDK )
            endif()

            # parse NDK version for purpose of injecting it into build.gradle

            # taken from official android.toolchain.cmake file:

            # Android NDK revision
            # Possible formats:
            # * r16, build 1234: 16.0.1234
            # * r16b, build 1234: 16.1.1234
            # * r16 beta 1, build 1234: 16.0.1234-beta1
            file( READ "${ANDROID_NDK}/source.properties" ANDROID_NDK_SOURCE_PROPERTIES )

            set( ANDROID_NDK_REVISION_REGEX
                "^Pkg\\.Desc = Android NDK\nPkg\\.Revision = ([0-9]+)\\.([0-9]+)\\.([0-9]+)(-beta([0-9]+))?"
            )
            if ( NOT ANDROID_NDK_SOURCE_PROPERTIES MATCHES "${ANDROID_NDK_REVISION_REGEX}" )
                message( SEND_ERROR "Failed to parse Android NDK revision: ${ANDROID_NDK}/source.properties.\n${ANDROID_NDK_SOURCE_PROPERTIES}" )
            endif()

            set( ANDROID_NDK_MAJOR "${CMAKE_MATCH_1}" )
            set( ANDROID_NDK_MINOR "${CMAKE_MATCH_2}" )
            set( ANDROID_NDK_BUILD "${CMAKE_MATCH_3}" )
            set( ANDROID_NDK_BETA  "${CMAKE_MATCH_5}" )
            if ( ANDROID_NDK_BETA STREQUAL "" )
                set( ANDROID_NDK_BETA "0" )
            endif()
            set( ANDROID_NDK_REVISION "${ANDROID_NDK_MAJOR}.${ANDROID_NDK_MINOR}.${ANDROID_NDK_BUILD}${CMAKE_MATCH_4}" )
        endif()

        # List of variables that should be passed to Android Studio runner
        set( MB_ANDROID_STUDIO_VARIABLES )
    endif()

    macro( mark_variable_for_android_studio_runner variable )
        if ( MB_GENERATE_ANDROID_STUDIO_EXE_WRAPPER )
            get_property( desc CACHE ${variable} PROPERTY HELPSTRING )
            get_property( type CACHE ${variable} PROPERTY TYPE       )

            # Implementation note:
            #
            # Introduce new cache variable with MB_AS_ prefix - it will be a string variable,
            # where <UNSET> means that it should not be defined in android studio runner.
            # Other possible values will be inferred from the possible values of the original
            # variable
            #
            #                               (Nenad Miksa) (28.01.2019.)
            set( MB_AS_${variable} "<UNSET>" CACHE STRING "Android Studio project: ${desc}" )

            # Add variable to list of variables that need to be passed to Android studio project.
            list( APPEND MB_ANDROID_STUDIO_VARIABLES ${variable} )

            if( type )
                if ( ${type} STREQUAL BOOL )
                    set_property( CACHE MB_AS_${variable} PROPERTY STRINGS "<UNSET>" "ON" "OFF" )
                else()
                    # if variable is already a multiple choice, then simply append <UNSET> to available choces
                    get_property( possible_values CACHE ${variable} PROPERTY STRINGS )
                    if( possible_values )
                        set_property( CACHE MB_AS_${variable} PROPERTY STRINGS "<UNSET>" ${possible_values} )
                    else()
                        # don't set STRINGS property - the input is free form
                        # However, treat <UNSET> in the same way also in that case.
                    endif()
                endif()
            endif()
            # Implementation note:
            #
            # if type is not available, this means that variable is not a cache variable.
            # Neverthless, we need to introduce the cache variable MB_AS_variable, but we cannot
            # fill in possible values, so keep it free form, but treat <UNSET> in the same way
            # as always.
            #
            #                               (Nenad Miksa) (28.01.2019.)
        endif()
    endmacro()

    macro( resolve_android_studio_variables destination )
        set( ${destination} "" )
        foreach( variable in ${MB_ANDROID_STUDIO_VARIABLES} )
            if( NOT ${MB_AS_${variable}} STREQUAL "<UNSET>" )
                set( ${destination} "${${destination}}, '-D${variable}=${MB_AS_${variable}}'" )
            endif()
        endforeach()
    endmacro()

    macro( resolve_abi_filters destination )
        string( REPLACE " " ";" ABI_LIST ${MB_ANDROID_STUDIO_ABI_FILTER} )
        set( GRADLE_ABI_FILTER )
        foreach( abi ${ABI_LIST} )
            list( APPEND GRADLE_ABI_FILTER "'${abi}'")
        endforeach()
        string( REPLACE ";" ", " ${destination} "${GRADLE_ABI_FILTER}" )
    endmacro()

    macro( create_android_studio_runner exename has_gtest )
        set( DESTINATION_DIR ${CMAKE_CURRENT_BINARY_DIR}/${exename}-android-studio )
        file( MAKE_DIRECTORY ${DESTINATION_DIR}/app )
        # Copy template project
        set( ANDROID_STUDIO_TEMPLATE_SRC ${COMMON_UTILS_DIR}/android-studio/ExeRunner )
        file( COPY ${ANDROID_STUDIO_TEMPLATE_SRC}/build.gradle
                   ${ANDROID_STUDIO_TEMPLATE_SRC}/gradle
                   ${ANDROID_STUDIO_TEMPLATE_SRC}/gradle.properties
                   ${ANDROID_STUDIO_TEMPLATE_SRC}/gradlew
                   ${ANDROID_STUDIO_TEMPLATE_SRC}/gradlew.bat
                   ${ANDROID_STUDIO_TEMPLATE_SRC}/settings.gradle
                   DESTINATION ${DESTINATION_DIR}
            )

        if ( MB_ANDROID_STUDIO_BUILD_ALL_TARGETS )
            set( AS_TARGETS_TO_BUILD "" )
        else()
            set( AS_TARGETS_TO_BUILD "targets '${exename}'" )
        endif()
        set( TARGET_NAME ${exename} )
        set( ANDROID_HOST_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR} )
        set( ANDROID_HOST_SOURCE_DIR ${CMAKE_SOURCE_DIR} )
        set( ANDROID_ASSETS_DIR "${CMAKE_BINARY_DIR}/${exename}-res/" )
        set( ADDITIONAL_CPP_FLAGS "" )
        set( JAVA_AUTORUN_VALUE "false" )
        if ( MB_ANDROID_STUDIO_ADD_AUTORUN_SUPPORT )
            set( JAVA_AUTORUN_VALUE "true" )
        endif()
        resolve_abi_filters( ANDROID_ABI_FILTERS )
        resolve_android_studio_variables( ANDROID_CUSTOM_VARIABLES )

        if ( ${has_gtest} )
            set( ANDROID_CUSTOM_VARIABLES "${ANDROID_CUSTOM_VARIABLES}, '-DMB_AS_HAS_GTEST=ON'")
        endif()

        # sanitize path for windows
        string( REPLACE ":" "\\:" ANDROID_NDK_SANITIZED "${ANDROID_NDK}" )
        string( REPLACE ":" "\\:" ANDROID_SDK_SANITIZED "${ANDROID_SDK}" )

        # find path to conanfile.py or conanfile.txt
        if( EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/conanfile.py )
            set( CONANFILE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/conanfile.py )
        endif()
        if( EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/conanfile.txt )
            set( CONANFILE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/conanfile.txt )
        endif()

        # CONANFILE_PATH must be relative path from app's CMakeLists.txt to original CMAKE_CURRENT_SOURCE_DIR
        file( RELATIVE_PATH CONANFILE_PATH ${DESTINATION_DIR}/app "${CONANFILE_PATH}" )

        set( MAIN_CMAKELISTS_PATH ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt )

        configure_file( ${ANDROID_STUDIO_TEMPLATE_SRC}/app/build.gradle   ${DESTINATION_DIR}/app/build.gradle   @ONLY )
        configure_file( ${ANDROID_STUDIO_TEMPLATE_SRC}/app/CMakeLists.txt ${DESTINATION_DIR}/app/CMakeLists.txt @ONLY )
        configure_file( ${ANDROID_STUDIO_TEMPLATE_SRC}/local.properties ${DESTINATION_DIR}/local.properties     @ONLY )
        configure_file( ${ANDROID_STUDIO_TEMPLATE_SRC}/local.properties ${DESTINATION_DIR}/app/local.properties @ONLY )

        file( COPY ${ANDROID_STUDIO_TEMPLATE_SRC}/app/exports.map DESTINATION ${DESTINATION_DIR}/app/ )
        file( COPY ${ANDROID_STUDIO_TEMPLATE_SRC}/app/src DESTINATION ${DESTINATION_DIR}/app/ )
        configure_file( ${ANDROID_STUDIO_TEMPLATE_SRC}/app/src/main/res/values/strings.xml ${DESTINATION_DIR}/app/src/main/res/values/strings.xml @ONLY )
        configure_file( ${ANDROID_STUDIO_TEMPLATE_SRC}/app/src/main/java/com/microblink/exerunner/RunActivity.java ${DESTINATION_DIR}/app/src/main/java/com/microblink/exerunner/RunActivity.java @ONLY )
    endmacro()

    macro( setup_ccache target )
        if( MB_CCACHE )
            set_target_properties( ${target} PROPERTIES CXX_COMPILER_LAUNCHER "${MB_CCACHE}" C_COMPILER_LAUNCHER "${MB_CCACHE}" )
        endif()
    endmacro()

    option( MB_DISABLE_PUBLIC_HEADER_CHECK "Disable check for correct packaging of public headers" OFF )
    mark_as_advanced( MB_DISABLE_PUBLIC_HEADER_CHECK )

    function( mb_check_public_headers target public_include_path )
        # if ${public_include_path} does not exist, don't perform any checks. This means that project
        # has not yet been ported to new public headers convention.
        if ( NOT MB_DISABLE_PUBLIC_HEADER_CHECK AND NOT MB_${target}_DISABLE_PUBLIC_HEADER_CHECK AND EXISTS "${public_include_path}" )
            if ( NOT MB_CONAN_PACKAGE_NAME ) # not defined because project() command was issued after include of common_utils
                set( MB_CONAN_PACKAGE_NAME ${PROJECT_NAME} CACHE STRING "Name of the conan package" FORCE )
            endif()

            file( GLOB public_headers_subdirs ${public_include_path}/* )
            # ensure that there is only one subdir and that it's named ${MB_CONAN_PACKAGE_NAME}
            list( LENGTH public_headers_subdirs num_public_header_contents )
            if ( NOT ${num_public_header_contents} EQUAL 1 )
                message( FATAL_ERROR "Expecting exactly one folder named ${MB_CONAN_PACKAGE_NAME} and no files in ${public_include_path}. Found ${num_public_header_contents} items." )
            endif()
            list( GET public_headers_subdirs 0 subfolder_name )
            if ( NOT IS_DIRECTORY "${subfolder_name}" )
                message( FATAL_ERROR "Expecting ${subfolder_name} to be a directory. However, it's a file." )
            endif()

            get_filename_component( subfolder_name "${subfolder_name}" NAME )
            if ( NOT ${subfolder_name} STREQUAL ${MB_CONAN_PACKAGE_NAME} )
                message( FATAL_ERROR "The ${public_include_path} must contain exactly one folder named '${MB_CONAN_PACKAGE_NAME}'. It currently contains exactly one folder named '${subfolder_name}'." )
            endif()
        endif()
    endfunction()

    macro( setup_target target current_source_dir allow_ban_unsafe_functions include_type runnable )
        enable_include_checks   ( ${target} )
        fix_xcode9_armv7_warning( ${target} )
        setup_code_coverage     ( ${target} )
        enable_runtime_checks   ( ${target} )
        enable_warnings         ( ${target} )
        setup_ccache            ( ${target} )
        if( ${allow_ban_unsafe_functions} )
            ban_unsafe_functions   ( ${target} )
        endif()
        if ( EXISTS ${current_source_dir}/Source )
            target_include_directories( ${target} ${include_type} ${current_source_dir}/Source )
        endif()
        if ( EXISTS ${current_source_dir}/Include )
            target_include_directories( ${target} ${include_type} ${current_source_dir}/Include )
        endif()
        if( ${runnable} )
            define_src_path   ( ${target} ${current_source_dir} )
            strip             ( ${target}                       )
            add_android_compat( ${target}                       )
        endif()
    endmacro()

    # Makes given target aware that it is being built within Android Studio runner
    # This gives this target possibility to access AS runner's specific data, such
    # as asset manager, global JavaVM pointer or path to app's internal storage folder.
    # This macro has no use for executable targets, as they are always aware of Android
    # Studio. However, it can be used to make some static/dynamic library targets aware
    # of the same.
    macro( mb_target_make_android_studio_aware target )
        if( ANDROID AND ANDROID_STUDIO_WRAPPED_EXE )
            target_compile_definitions( ${target} PRIVATE "ANDROID_STUDIO_WRAPPED_EXE" )
            target_include_directories( ${target} PRIVATE ${COMMON_UTILS_DIR}/android-studio/ExeRunner/app/src/main/cpp )
        endif()
    endmacro()

    # TODO: remove in CMakeBuild v9.0.0
    macro( mb_mark_headers_as_public current_source_dir )
        set( header_destination ${CMAKE_CURRENT_BINARY_DIR}/include/${PROJECT_NAME} )
        file( MAKE_DIRECTORY ${header_destination} )
        foreach( header ${ARGN} )
            file( RELATIVE_PATH rel_header_path ${current_source_dir}/Source ${header} )
            get_filename_component( rel_destination_dir ${rel_header_path} DIRECTORY )
            file( INSTALL ${header} DESTINATION ${header_destination}/${rel_destination_dir} )
        endforeach()
    endmacro()

    # TODO: remove in CMakeBuild v9.0.0
    function( mb_target_mark_all_headers_public target current_source_dir )
        get_target_property( target_source_files ${target} SOURCES )
        set( public_headers )
        foreach ( file ${target_source_files} )
            if( "${file}" MATCHES ".*\\.h" )
                list( APPEND public_headers ${file} )
            endif()
        endforeach()
        mb_mark_headers_as_public( ${current_source_dir} ${public_headers} )
    endfunction()

    function( _create_compat_header compatiblity_headers_path compat_header_path new_header_path )
        message( STATUS "Generating compatibility header ${compat_header_path} -> ${new_header_path}" )
        get_filename_component( relative_directory "${compat_header_path}" DIRECTORY )
        if ( relative_directory )
            file( MAKE_DIRECTORY "${compatiblity_headers_path}/${relative_directory}" )
        endif()
        file( WRITE "${compatiblity_headers_path}/${compat_header_path}"
"
#pragma once

#ifdef _MSC_VER
#   pragma message( \"This header has been deprecated. Please #include <${new_header_path}>\" )
#else
#   warning \"This header has been deprecated. Please #include <${new_header_path}>\"
#endif

#include <${new_header_path}>
"
            )
    endfunction()

    function( mb_create_compatibility_headers current_source_dir )
        set( new_public_headers_path "${current_source_dir}/Include/${MB_CONAN_PACKAGE_NAME}" )
        set( compatiblity_headers_path "${CMAKE_CURRENT_BINARY_DIR}/Include" )
        file( MAKE_DIRECTORY "${compatibility_headers_path}" )
        # first generate all headers from header_map
        set( header_map ${ARGN} )
        list( LENGTH header_map header_map_length )
        if ( ${header_map_length} GREATER 0 )
            math( EXPR length_mod "${header_map_length} % 2" )
            if ( NOT ${length_mod} EQUAL 0 )
                message( FATAL_ERROR "Header map must have even number of elements!" )
            endif()
            math( EXPR num_mapped_headers "${header_map_length} / 2 - 1" )
            foreach( it RANGE ${num_mapped_headers} )
                math( EXPR compat_header_index "${it} * 2"     )
                math( EXPR new_header_index    "${it} * 2 + 1" )
                list( GET header_map ${compat_header_index} compat_header )
                list( GET header_map ${new_header_index}    new_header    )
                _create_compat_header( "${compatiblity_headers_path}" "${compat_header}" "${new_header}" )
            endforeach()
        endif()

        # obtain all public headers
        file( GLOB_RECURSE public_headers LIST_DIRECTORIES false RELATIVE "${new_public_headers_path}" "${new_public_headers_path}/*" )
        foreach( public_header ${public_headers} )
            # if not generated from header_map
            if ( NOT EXISTS "${compatiblity_headers_path}/${public_header}" )
                _create_compat_header( "${compatiblity_headers_path}" "${public_header}" "${MB_CONAN_PACKAGE_NAME}/${public_header}" )
            else()
                message( STATUS "${compatiblity_headers_path}/${public_header} already exists. Skipping." )
            endif()
        endforeach()

    endfunction()

    function( mb_filter_sources filtered_sources public_headers )
        # collect public headers from ${ARGN}
        set( public_headers_local )
        set( filtered_sources_local )
        set( is_public OFF )
        foreach( file ${ARGN} )
            if ( ${file} STREQUAL PUBLIC )
                message( DEPRECATION "PUBLIC keyword is deprecated and will be removed in CMakeBuild v8.0.0. Please port your code to use Include folder for public headers." )
                set( is_public ON )
            else()
                list( APPEND filtered_sources_local ${file} )
                if ( ${is_public} )
                    list( APPEND public_headers_local ${file} )
                    set( is_public OFF )
                endif()
            endif()
        endforeach()
        set( ${public_headers}   "${public_headers_local}"   PARENT_SCOPE )
        set( ${filtered_sources} "${filtered_sources_local}" PARENT_SCOPE )
    endfunction()

    macro( _build_exe exename current_source_dir is_mobile has_gtest )
        if("${CMAKE_CFG_INTDIR}" STREQUAL ".")
            set(multiconfig FALSE)
        else()
            set(multiconfig TRUE)
        endif()
        if(multiconfig)
            set(LDPATHS_WITH_CONFIG ${LDPATHS})
            foreach(ldpath ${LDPATHS})
                list(APPEND LDPATHS_WITH_CONFIG ${ldpath}/${CMAKE_CFG_INTDIR})
            endforeach()
            link_directories(${LDPATHS_WITH_CONFIG})
        else()
            link_directories(${LDPATHS})
        endif()
        mb_filter_sources( all_sources public_headers ${ARGN} )
        if( ANDROID AND ANDROID_STUDIO_WRAPPED_EXE )
            add_library( ${exename} SHARED ${all_sources} src/main/cpp/native-lib.cpp ) # relative path to JNI glue code in template project
            target_include_directories( ${exename} PRIVATE src/main/cpp )
            target_compile_definitions( ${exename} PRIVATE "ANDROID_STUDIO_WRAPPED_EXE" )
            if( ${has_gtest} )
                target_compile_definitions( ${exename} PRIVATE "MB_AS_CLEANUP_GTEST_STATE" )
            endif()
            # automatically add initialization and termination of global android context
            if ( TARGET CONAN_PKG::CoreUtils OR TARGET CoreUtils )
                if ( TARGET CONAN_PKG::CoreUtils )
                    target_link_libraries( ${exename} PRIVATE CONAN_PKG::CoreUtils )
                else()
                    target_link_libraries( ${exename} PRIVATE CoreUtils )
                endif()
                target_compile_definitions( ${exename} PRIVATE "MB_AS_CORE_UTILS_AVAILABLE" )
            endif()
        else()
            add_executable(${exename} ${all_sources})
        endif()
        if( EMSCRIPTEN )
            set( exe_prefix "$<TARGET_FILE_DIR:${exename}>/$<TARGET_FILE_BASE_NAME:${exename}>" )
            set( EMSCRIPTEN_EXE_OUTPUTS
                "${exe_prefix}.data"
                "${exe_prefix}.html.cd"
                "${exe_prefix}.js"
                "${exe_prefix}.wasm"
                "${exe_prefix}.wasm.map"
                "${exe_prefix}.wast"
                "${exe_prefix}.html.mem"
                "${exe_prefix}.worker.js"
            )
            set_target_properties( ${exename} PROPERTIES ADDITIONAL_CLEAN_FILES "${EMSCRIPTEN_EXE_OUTPUTS}" )
        endif()
        setup_target( ${exename} ${current_source_dir} FALSE PRIVATE TRUE )
        mb_mark_headers_as_public( ${current_source_dir} ${public_headers} )

        if ( iOS )
            set_target_properties( ${exename} PROPERTIES
                MACOS_BUNDLE_INFO_PLIST ${COMMON_UTILS}/ios/iOSBundleInfo.plist.in
                MACOSX_BUNDLE TRUE
                MACOSX_BUNDLE_BUNDLE_NAME ${exename}
                MACOSX_BUNDLE_GUI_IDENTIFIER "com.microblink.${exename}"
                XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.microblink.${exename}"
                XCODE_ATTRIBUTE_SUPPORTS_MACCATALYST "Yes"
                XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "CQTJWP89J7"
                "XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY[sdk=iphoneos*]" "iPhone Developer"
            )
        elseif( ANDROID AND ( NOT ANDROID_STUDIO_WRAPPED_EXE ) )
            # position independent executables are only allowed to be run on devices with Lollipop and newer
            target_link_libraries( ${exename} PRIVATE -pie )
        endif()

        if( ${is_mobile} AND ( NOT CMAKE_CROSSCOMPILING ) AND MB_GENERATE_ANDROID_STUDIO_EXE_WRAPPER )
            create_android_studio_runner( ${exename} ${has_gtest} )
        endif()
    endmacro()

    macro( mb_target_link_libraries target )
        if( TARGET ${target} )
            target_link_libraries( ${target} ${ARGN} )
        endif()
    endmacro()

    macro( embed_dll_into_app_bundle bundleTarget targetToEmbed )
        if ( iOS )
            # first assert that bundleTarget is executable and targetToEmbed is shared library
            get_property( bundleTargetType TARGET ${bundleTarget}  PROPERTY TYPE )
            get_property( targetToEmbed    TARGET ${targetToEmbed} PROPERTY TYPE )
            if ( NOT bundleTargetType STREQUAL EXECUTABLE )
                message( FATAL_ERROR "${bundleTarget} is not app bundle. Cannot embed into it!" )
            endif()
            if ( NOT targetToEmbed STREQUAL SHARED_LIBRARY )
                message( FATAL_ERROR "${targetToEmbed} is not shared library. Cannot embed it!" )
            endif()

            # workaround until https://gitlab.kitware.com/cmake/cmake/issues/18073 is resolved
            add_dependencies( ${bundleTarget} ${targetToEmbed} )

            set_target_properties( ${bundleTarget} PROPERTIES
                XCODE_ATTRIBUTE_LD_RUNPATH_SEARCH_PATHS "@executable_path/Frameworks"
            )
            set_target_properties( ${targetToEmbed} PROPERTIES
                XCODE_ATTRIBUTE_DYLIB_INSTALL_NAME_BASE "@rpath"
            )

            add_custom_command(
                TARGET ${bundleTarget} POST_BUILD
                COMMAND
                    ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:${bundleTarget}>/Frameworks"
                COMMAND
                    # must not be VERBATIM for $<TARGET_FILE> to resolve correctly (i.e. to not have $ escaped)
                    ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:${targetToEmbed}>" "$<TARGET_FILE_DIR:${bundleTarget}>/Frameworks/"
                COMMENT
                    "Embedding ${targetToEmbed} into ${bundleTarget}"
            )
        endif()
    endmacro()

    macro( build_tool_exe exename current_source_dir )
        if( NOT CMAKE_CROSSCOMPILING )
            # This cache variable must be defined before _build_exe invokes set_log_level_and_timer in order to have LOG_DEBUG as default log level for tools
            set( ${exename}_LOG_LEVEL "LOG_DEBUG" CACHE STRING "Log level for ${exename}" )
            _build_exe( ${exename} ${current_source_dir} FALSE FALSE ${ARGN} )
            target_add_tool_specific_flags( ${exename} )
            # Export executable so it can be used by cross-platform build directory
            export( TARGETS ${exename} APPEND FILE ${CMAKE_BINARY_DIR}/executables.cmake )
            if( NOT TARGET build_tools )
                add_custom_target( build_tools DEPENDS ${exename} )
            else()
                add_dependencies( build_tools ${exename} )
            endif()
        endif()
    endmacro()

    macro( build_other_exe exename current_source_dir )
        if( NOT CMAKE_CROSSCOMPILING )
            _build_exe( ${exename} ${current_source_dir} FALSE FALSE ${ARGN} )
            # Do not export it and don't add it to build_tools dependencies
        endif()
    endmacro()

    # Builds simple exe for both mobile and desktop platforms
    macro( build_mobile_exe exename current_source_dir )
        _build_exe( ${exename} ${current_source_dir} TRUE FALSE ${ARGN} )
    endmacro()

    macro( _build_static_library libname ban_unsafe current_source_dir )
        mb_filter_sources( all_sources public_headers ${ARGN} )
        mb_mark_headers_as_public( ${current_source_dir} ${public_headers} )
        add_library ( ${libname} STATIC ${all_sources} )
        setup_target( ${libname} ${current_source_dir} ${ban_unsafe} PUBLIC FALSE )
        mb_check_public_headers( ${libname} ${current_source_dir}/Include )
    endmacro()

    macro( build_static_library libname current_source_dir )
        _build_static_library( ${libname} TRUE ${current_source_dir} ${ARGN} )
    endmacro()

    macro( build_tool_static_library libname current_source_dir )
        # This cache variable must be defined before build_static_library invokes set_log_level_and_timer in order to have LOG_DEBUG as default log level for tools
        set( ${libname}_LOG_LEVEL "LOG_DEBUG" CACHE STRING "Log level for ${libname}" )
        _build_static_library( ${libname} FALSE ${current_source_dir} ${ARGN} )
        target_add_tool_specific_flags( ${libname} )
    endmacro()

    macro(build_dll dllname current_source_dir)
        if("${CMAKE_CFG_INTDIR}" STREQUAL ".")
                set(multiconfig FALSE)
        else()
                set(multiconfig TRUE)
        endif()
        if(multiconfig)
            set(LDPATHS_WITH_CONFIG ${LDPATHS})
            foreach(ldpath ${LDPATHS})
                list(APPEND LDPATHS_WITH_CONFIG ${ldpath}/${CMAKE_CFG_INTDIR})
            endforeach()
            link_directories(${LDPATHS_WITH_CONFIG})
        else()
            link_directories(${LDPATHS})
        endif()

        mb_filter_sources( all_sources public_headers ${ARGN} )
        mb_mark_headers_as_public( ${current_source_dir} ${public_headers} )

        add_library ( ${dllname} SHARED ${all_sources} )
        setup_target( ${dllname} ${current_source_dir} TRUE PRIVATE TRUE )
        mb_check_public_headers( ${dllname} ${current_source_dir}/Include )
        if( APPLE )
            set_target_properties( ${dllname} PROPERTIES MACOSX_RPATH ON )
            if ( iOS )
                set_target_properties( ${dllname} PROPERTIES
                    XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "CQTJWP89J7"
                    "XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY[sdk=iphoneos*]" "iPhone Developer"
                )
            endif()
        endif()
    endmacro()

    macro( get_static_lib_dependencies target all_dependencies visited )
        get_target_property( dependencies ${target} INTERFACE_LINK_LIBRARIES )
        foreach( dep ${dependencies} )
            # check if we already processed this dependency
            list( FIND ${visited} ${dep} pos )
            if( ${pos} EQUAL -1 )
                if( TARGET ${dep} )
                    get_target_property( target_type ${dep} TYPE )

                    if( ${target_type} STREQUAL STATIC_LIBRARY OR ${target_type} STREQUAL UNKNOWN_LIBRARY )
                        list( APPEND ${all_dependencies} $<TARGET_FILE:${dep}> )
                    endif()

                    list( APPEND ${visited} ${dep} )

                    get_static_lib_dependencies( ${dep} all_dependencies visited )
                elseif( IS_ABSOLUTE ${dep} )
                    list( APPEND ${all_dependencies} ${dep} )
                endif()
            endif()
        endforeach()
    endmacro()

    macro( build_fat_static_library libname TARGET_NAME )
        set( all_dependencies "" )
        set( visited "" )
        get_static_lib_dependencies( ${libname} all_dependencies visited )

#        message( STATUS "All dependencies of ${libname}: ${all_dependencies}" )

        # now generate target for merging static libraries
        file( MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/fat-libs )
        if( APPLE )
            set( TARGET_OUTPUT_NAME ${CMAKE_BINARY_DIR}/fat-libs/lib${libname}.a )
            set_property( GLOBAL PROPERTY XCODE_EMIT_EFFECTIVE_PLATFORM_NAME OFF )
            # Use OSX's libtool to merge archives
            add_custom_command( OUTPUT ${TARGET_OUTPUT_NAME}
                COMMAND /usr/bin/libtool -static -o ${TARGET_OUTPUT_NAME} $<TARGET_FILE:${libname}> ${all_dependencies}
                DEPENDS ${libname}
                COMMENT "Building merged static library"
                VERBATIM
            )
            add_custom_target( ${TARGET_NAME} DEPENDS ${TARGET_OUTPUT_NAME} )
        elseif( MSVC )
            message( FATAL_ERROR "Merging static libraries on Windows currently not supported" )
        else() # Linux and Android
            set( TARGET_OUTPUT_NAME ${CMAKE_BINARY_DIR}/fat-libs/lib${libname}.a )
#            string( REPLACE ";" "  " all_dependencies "${all_dependencies}" )
            # Invoke armerge_linux.sh shell script which does all the hard work
            add_custom_command( OUTPUT ${TARGET_OUTPUT_NAME}
                COMMAND ${CMAKE_COMMAND} -E env "AR=${CMAKE_AR}" ${COMMON_UTILS_DIR}/armerge_linux.sh ${TARGET_OUTPUT_NAME} $<TARGET_FILE:${libname}> ${all_dependencies}
                DEPENDS ${libname}
                COMMENT "Building merged static library"
                VERBATIM
            )
            add_custom_target( ${TARGET_NAME} DEPENDS ${TARGET_OUTPUT_NAME} )
        endif()

    endmacro()

    macro( mb_create_host_build_dir )
        if ( CMAKE_CROSSCOMPILING AND NOT TARGET build_host_tools )
            if ( NOT CMAKE_HOST_BINARY_DIR )
                set( HOST_BINARY_DIR ${CMAKE_BINARY_DIR}/host-build )

                set( variables_to_reuse )
                set( in_reuse_mode OFF )
                set( use_dev_release_for_host ON )
                foreach( arg ${ARGN} )
                    if ( ${arg} STREQUAL REUSE )
                        set( in_reuse_mode ON )
                    elseif( in_reuse_mode )
                        list( APPEND variables_to_reuse ${arg} )
                    elseif( ${arg} STREQUAL NO_DEV_RELEASE )
                        set( use_dev_release_for_host OFF )
                    endif()
                endforeach()

                # create host binary dir
                file( MAKE_DIRECTORY ${HOST_BINARY_DIR} )
                # infer host cmake generator (use VS on windows host and ninja otherwise)
                if ( CMAKE_HOST_WIN32 )
                    set( HOST_CMAKE_GENERATOR "Visual Studio 16" )
                else()
                    set( HOST_CMAKE_GENERATOR "Ninja" )
                endif()

                set( SAVED_ENV_CC  $ENV{CC}  )
                set( SAVED_ENV_CXX $ENV{CXX} )

                # clear CC and CXX variables for execute_process
                unset( ENV{CC} )
                unset( ENV{CXX} )

                # run cmake for host in host-build folder
                set( REUSE_CCACHE "" )
                if ( MB_CCACHE )
                    set( REUSE_CCACHE "-DMB_CCACHE=${MB_CCACHE}" )
                endif()
                set( REUSED_VARS "" )
                foreach( var ${variables_to_reuse} )
                    list( APPEND REUSED_VARS "-D${var}=${${var}}" )
                endforeach()
                set( HOST_CMAKE_COMMAND
                    "${CMAKE_COMMAND}"
                        -G "${HOST_CMAKE_GENERATOR}"
                        -DMB_DEV_RELEASE=${use_dev_release_for_host}
                        ${REUSE_CCACHE}
                        -DMB_TEST_DATA_PATH=${MB_TEST_DATA_PATH}
                        -DMB_SECURE_TEST_DATA_PATH=${MB_SECURE_TEST_DATA_PATH}
                        -DMB_USE_GCC_CXX11_ABI=ON
                        -DMB_ENABLE_BUILD_TIME_PROFILING=${MB_ENABLE_BUILD_TIME_PROFILING}
                        ${REUSED_VARS}
                        "${CMAKE_CURRENT_SOURCE_DIR}"
                )
                if ( CMAKE_HOST_UNIX )
                    # isolate host cmake invocation from current environment
                    # without this, dependent conan builds triggered by conan install in host cmake invocation get the
                    # cross-compilation environment, which causes build errors
                    set( host_path /usr/local/bin:/bin:/usr/bin )
                    if ( DEFINED ENV{VIRTUAL_ENV} )
                        set( host_path $ENV{VIRTUAL_ENV}/bin:${host_path} )
                    endif()
                    set( host_environment_variables PATH=${host_path} LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64 )
                    if ( DEFINED ENV{CMAKE_BUILD_PARALLEL_LEVEL} )
                        list( APPEND host_environment_variables CMAKE_BUILD_PARALLEL_LEVEL=$ENV{CMAKE_BUILD_PARALLEL_LEVEL} )
                    endif()
                    if ( DEFINED ENV{VIRTUAL_ENV} )
                        list( APPEND host_environment_variables VIRTUAL_ENV=$ENV{VIRTUAL_ENV} )
                    endif()
                    if ( DEFINED ENV{CONAN_USER_HOME} )
                        list( APPEND host_environment_variables CONAN_USER_HOME=$ENV{CONAN_USER_HOME} )
                    endif()
                    if ( DEFINED ENV{DEVELOPER_DIR} )
                        list( APPEND host_environment_variables DEVELOPER_DIR=$ENV{DEVELOPER_DIR} )
                    endif()
                    set( HOST_CMAKE_COMMAND env -i ${host_environment_variables} ${HOST_CMAKE_COMMAND} )
                endif()
                message( STATUS "Creating host build dir with command:\n${HOST_CMAKE_COMMAND}\n")
                execute_process(
                    COMMAND
                        ${HOST_CMAKE_COMMAND}
                    WORKING_DIRECTORY
                        "${HOST_BINARY_DIR}"
                )

                # restore CC and CXX environment variables
                set( ENV{CC}  ${SAVED_ENV_CC}  )
                set( ENV{CXX} ${SAVED_ENV_CXX} )
            else()
                set( HOST_BINARY_DIR ${CMAKE_HOST_BINARY_DIR} )
            endif()

            # now include executables, if not already included
            message( "Importing targets from ${HOST_BINARY_DIR}/executables.cmake" )
            include( ${HOST_BINARY_DIR}/executables.cmake )

            # Create target that will build host tools
            if( iOS )
                # Workaround for Xcode polluting the environment with iOS tools
                add_custom_target( build_host_tools COMMAND
                    env -i CMAKE_BUILD_PARALLEL_LEVEL=$ENV{CMAKE_BUILD_PARALLEL_LEVEL} bash -c "${CMAKE_COMMAND} --build ${HOST_BINARY_DIR} --config $<CONFIG> --target build_tools"
                )
            else()
                if( CMAKE_GENERATOR STREQUAL "Ninja" )
                    # calculate byproducts for build_host_tools to ensure ninja will call it
                    file(READ ${HOST_BINARY_DIR}/executables.cmake imported_executables )
                    # regex matchall will fail if executables.cmake is empty file
                    if( imported_executables )
                        string(REGEX MATCHALL "add_executable\\([a-zA-Z0-9]+ +IMPORTED\\)" imported_target_expressions ${imported_executables} )
                        # extract imported target names
                        set( imported_targets )
                        foreach( target_expression ${imported_target_expressions} )
                            string(REGEX REPLACE "add_executable\\((.*) +IMPORTED\\).*" "\\1" target_name "${target_expression}" )
                            list( APPEND imported_targets ${target_name} )
                        endforeach()
                        list(REMOVE_DUPLICATES imported_targets)
                        # generate byproducts expression only if imported_targets list is not empty
                        if( imported_targets )
                            set( byproducts_expression BYPRODUCTS )
                            foreach( target ${imported_targets} )
                                string(REGEX MATCH "set_target_properties\\([ \t\n]*${target}[ \t\n]+PROPERTIES[ \t\n]+IMPORTED_LOCATION_RELEASE[ \t\n]\"([^\"]+)\"[ \t\n]*\\)" match ${imported_executables} )
                                if ( CMAKE_MATCH_1 )
                                    list(APPEND byproducts_expression ${CMAKE_MATCH_1})
                                else()
                                    # try matching IMPORTED_LOCATION_DEBUG
                                    string(REGEX MATCH "set_target_properties\\([ \t\n]*${target}[ \t\n]+PROPERTIES[ \t\n]+IMPORTED_LOCATION_DEBUG[ \t\n]\"([^\"]+)\"[ \t\n]*\\)" match ${imported_executables} )
                                    list(APPEND byproducts_expression ${CMAKE_MATCH_1})
                                endif()
                            endforeach()
                        endif()
                    endif()
                endif()
                set( BUILD_HOST_TOOLS_CMD "${CMAKE_COMMAND}" --build "${HOST_BINARY_DIR}" --config $<CONFIG> --target build_tools )
                if ( CMAKE_HOST_UNIX )
                    # isolate host cmake invocation from current environment
                    set( BUILD_HOST_TOOLS_CMD env -i PATH=/usr/local/bin:/bin:/usr/bin LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64 CMAKE_BUILD_PARALLEL_LEVEL=$ENV{CMAKE_BUILD_PARALLEL_LEVEL} ${BUILD_HOST_TOOLS_CMD} )
                endif()
                add_custom_target( build_host_tools COMMAND
                    ${BUILD_HOST_TOOLS_CMD}
                    ${byproducts_expression}
                )
            endif()
        endif()
    endmacro()

    function( mb_generate_source_groups root_path )
        set( files )
        foreach( file ${ARGN} )
            if( NOT ${file} STREQUAL PUBLIC )
                list( APPEND files ${file} )
            endif()
        endforeach()
        source_group( TREE ${root_path} FILES ${files} )
    endfunction()

    function( mark_sources_as_hot )
        string( REPLACE ";" " " TNUN_compiler_optimize_for_speed "${TNUN_compiler_optimize_for_speed}" )
        set_source_files_properties( ${ARGN} PROPERTIES COMPILE_FLAGS "${TNUN_compiler_optimize_for_speed}" )
        disable_pch_for_sources( ${ARGN} )
    endfunction( mark_sources_as_hot )

    macro( mark_sources_as_objective_cpp )
        set_source_files_properties( ${ARGN} PROPERTIES COMPILE_FLAGS "-x objective-c++" )
        disable_pch_for_sources( ${ARGN} )
    endmacro()

    macro( disable_pch_for_sources )
        if ( ${CMAKE_GENERATOR} STREQUAL "Ninja" OR ${CMAKE_GENERATOR} MATCHES "Makefile" OR ${CMAKE_GENERATOR} MATCHES "Visual Studio" )
            set_source_files_properties( ${ARGN} PROPERTIES SKIP_PRECOMPILE_HEADERS "ON" )
        endif()
    endmacro()

endif()
