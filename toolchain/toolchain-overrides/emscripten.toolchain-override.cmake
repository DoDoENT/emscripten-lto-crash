cmake_minimum_required( VERSION 3.12.0 )

include( ${CMAKE_CURRENT_LIST_DIR}/gcc_clang_overrides.cmake )

# In some cases conan will set the "-stdlib" flag. This flag is not used in Emscripten builds.
list( APPEND TNUN_disabled_warnings "-Wno-unused-command-line-argument" )

# determine if fastcomp or upstream backend
string( REPLACE "." ";" VERSION_LIST ${CMAKE_CXX_COMPILER_VERSION} )
list( GET VERSION_LIST 0 clang_major_version  )
set( MB_EMSCRIPTEN_BACKEND "upstream" )
if ( ${clang_major_version} EQUAL 6 )
    set( MB_EMSCRIPTEN_BACKEND "fastcomp" )
endif()

set( USE_NEW_LINKER_FLAG_CONVENTION FALSE )
if ( EMSCRIPTEN_VERSION VERSION_GREATER_EQUAL "1.39.9" )
    set( USE_NEW_LINKER_FLAG_CONVENTION TRUE )
endif()

option( MB_EMSCRIPTEN_COMPILE_TO_WEBASSEMBLY "Compile to WebAssembly, instead of asm.js" ON )
if ( MB_EMSCRIPTEN_COMPILE_TO_WEBASSEMBLY )
    set( MB_EMSCRIPTEN_WASM_OPTION "SHELL:-s WASM=1" )
else()
    set( MB_EMSCRIPTEN_WASM_OPTION "SHELL:-s WASM=0" )

    string( REPLACE "." ";" VERSION_LIST ${CMAKE_CXX_COMPILER_VERSION} )
    list( GET VERSION_LIST 0 clang_major_version )

    # if fastcomp backend and using asm.js, enable cyberdwarf debugger (it is not supported in wasm)
    if ( ${clang_major_version} EQUAL 6 )
        list( APPEND TNUN_compiler_debug_symbols "SHELL:-s CYBERDWARF=1" )
        list( APPEND TNUN_linker_debug_symbols   "SHELL:-s CYBERDWARF=1" )
    endif()

endif()

add_compile_options( ${MB_EMSCRIPTEN_WASM_OPTION} )
add_link_options( ${MB_EMSCRIPTEN_WASM_OPTION} )

option( MB_EMSCRIPTEN_ENABLE_PTHREADS "Allow using POSIX threads (currently unsupported in most browsers)" OFF )
if ( MB_EMSCRIPTEN_ENABLE_PTHREADS )
    set( MB_EMSCRIPTEN_THREAD_POOL_SIZE 0 CACHE STRING "Default number of web workers preallocated for emscripten threads at runtime startup. Set to 0 to dynamically spawn web workers and to -1 to use the number equal to number of cores reported by the web browser." )
    mark_as_advanced( MB_EMSCRIPTEN_THREAD_POOL_SIZE )
    add_link_options( "SHELL:-s PTHREAD_POOL_SIZE=${MB_EMSCRIPTEN_THREAD_POOL_SIZE}" "SHELL:-s PROXY_TO_PTHREAD" )
    set( MB_EMSCRIPTEN_PTHREAD_OPTIONS "SHELL:-s USE_PTHREADS=1" )
    # if demangling is enabled together with threads, this causes browser to hang instead of displaying crash trace
    list( REMOVE_ITEM TNUN_compiler_debug_symbols "SHELL:-s DEMANGLE_SUPPORT=1" )
    list( REMOVE_ITEM TNUN_linker_debug_symbols "SHELL:-s DEMANGLE_SUPPORT=1" )
else()
    set( MB_EMSCRIPTEN_PTHREAD_OPTIONS "SHELL:-s USE_PTHREADS=0" )
endif()

add_compile_options( ${MB_EMSCRIPTEN_PTHREAD_OPTIONS} )
add_link_options( ${MB_EMSCRIPTEN_PTHREAD_OPTIONS} )

option( MB_EMSCRIPTEN_USE_WEBGL2 "Use WebGL 2 instead of default WebGL 1" ON )
if ( MB_EMSCRIPTEN_USE_WEBGL2 )
    set( MB_EMSCRIPTEN_WEBGL_OPTIONS "SHELL:-s WEBGL2_BACKWARDS_COMPATIBILITY_EMULATION=1" "SHELL:-s USE_WEBGL2=1" )
    add_link_options( -lGL )
else()
    set( MB_EMSCRIPTEN_WEBGL_OPTIONS "SHELL:-s USE_WEBGL2=0" )
endif()

add_compile_options( ${MB_EMSCRIPTEN_WEBGL_OPTIONS} )
add_link_options( ${MB_EMSCRIPTEN_WEBGL_OPTIONS} )

set( MB_EMSCRIPTEN_TARGET_ENVIRONMENT "web" CACHE STRING "JS environment to target" )
set_property( CACHE MB_EMSCRIPTEN_TARGET_ENVIRONMENT PROPERTY STRINGS "any" "web" "worker" "node" "shell" )
if ( NOT MB_EMSCRIPTEN_TARGET_ENVIRONMENT STREQUAL "any" )
    set( emscripten_environment ${MB_EMSCRIPTEN_TARGET_ENVIRONMENT} )
    # when pthreads are enabled, worker environment must be present
    if ( MB_EMSCRIPTEN_ENABLE_PTHREADS AND NOT MB_EMSCRIPTEN_TARGET_ENVIRONMENT STREQUAL "worker" )
        set( emscripten_environment "${emscripten_environment},worker" )
    endif()
    set( MB_EMSCRIPTEN_ENVIRONMENT_OPTION "SHELL:-s ENVIRONMENT=${emscripten_environment}" )

    add_compile_options( ${MB_EMSCRIPTEN_ENVIRONMENT_OPTION} )
    add_link_options( ${MB_EMSCRIPTEN_ENVIRONMENT_OPTION} )
endif()

option( MB_EMSCRIPTEN_SIMD "Enable SIMD autovectorization (for webassembly, requires upstream LLVM backend; for asmjs, uses deprecated SIMD.js)" OFF )
if ( MB_EMSCRIPTEN_SIMD )
    if ( MB_EMSCRIPTEN_COMPILE_TO_WEBASSEMBLY )
        set( MB_EMSCRIPTEN_SIMD_OPTION -msimd128 )
    else()
        set( MB_EMSCRIPTEN_SIMD_OPTION "SHELL:-s SIMD=1" )
    endif()

    TNUN_add_compile_options( Release ${MB_EMSCRIPTEN_SIMD_OPTION} )
    TNUN_add_link_options   ( Release ${MB_EMSCRIPTEN_SIMD_OPTION} )
endif()

option( MB_EMSCRIPTEN_ALLOW_MEMORY_GROWTH "Allow growing memory arrays at runtime" ON )

if ( MB_EMSCRIPTEN_ALLOW_MEMORY_GROWTH )
    # https://github.com/emscripten-core/emscripten/blob/1.38.43/src/settings.js#L113
    # https://github.com/emscripten-core/emscripten/blob/1.38.43/tools/file_packager.py#L44
    # https://github.com/emscripten-core/emscripten/issues/5179
    add_link_options( "SHELL:-s ALLOW_MEMORY_GROWTH=1" --no-heap-copy )
endif()

# If MB_EMSCRIPTEN_ALLOW_MEMORY_GROWTH is OFF, this indicates the total memory to be used at runtime.
# If MB_EMSCRIPTEN_ALLOW_MEMORY_GROWTH is ON, this indicates the initial amount of memory before first memory growth will take place.
set( MB_EMSCRIPTEN_TOTAL_MEMORY_MB 200 CACHE STRING "The total/initial amount of memory to use in MB. For more info see https://github.com/emscripten-core/emscripten/blob/1.39.0/src/settings.js#L84" )

math( EXPR MB_TOTAL_MEMORY_BYTES "${MB_EMSCRIPTEN_TOTAL_MEMORY_MB} * 1024 * 1024" )

if ( USE_NEW_LINKER_FLAG_CONVENTION )
    add_link_options( "SHELL:-s INITIAL_MEMORY=${MB_TOTAL_MEMORY_BYTES}" )
else()
    add_link_options( "SHELL:-s TOTAL_MEMORY=${MB_TOTAL_MEMORY_BYTES}" )
endif()

if ( MB_EMSCRIPTEN_ENABLE_PTHREADS )
    math( EXPR MAX_WASM_BYTES "${MB_TOTAL_MEMORY_BYTES} * 4" )
    if ( USE_NEW_LINKER_FLAG_CONVENTION )
        add_link_options( "SHELL:-s MAXIMUM_MEMORY=${MAX_WASM_BYTES}" )
    else()
        add_link_options( "SHELL:-s WASM_MEM_MAX=${MAX_WASM_BYTES}" )
    endif()
endif()

# strip does not exist in cmake toolchain and system's strip command does not work with wasm binaries
set( MB_DISABLE_STRIP ON )
# so, in order to make smallest possible wasm binaries, disable generating debug symbols
if ( NOT MB_DEV_RELEASE )
    option( MB_DEBUG_SYMBOLS_IN_RELEASE "Generate debug symbols for easier debugging of release builds" OFF )
endif()

# we do not want to use sanitizers with emscripten
unset( TNUN_compiler_runtime_sanity_checks  )
unset( TNUN_linker_runtime_sanity_checks    )
unset( TNUN_compiler_runtime_integer_checks )
unset( TNUN_linker_runtime_integer_checks   )

# also, coverage will not work with emscripten
unset( TNUN_code_coverage_compiler_flags )
unset( TNUN_code_coverage_linker_flags   )

if ( MB_EMSCRIPTEN_BACKEND STREQUAL "upstream" )
    # https://github.com/emscripten-core/emscripten/issues/8731#issuecomment-719145588
    # This makes LTO warnings treated as warnings, at risk that the resulting program may not work.
    add_link_options( "SHELL:-s STRICT=0" )
endif()
