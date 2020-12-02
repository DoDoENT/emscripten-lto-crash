import os

from conans import ConanFile
from conans.errors import ConanException
from open_cv_helpers import OpenCVVersionInfo


class OpencvConan(ConanFile):
    name = "OpenCV"
    version = OpenCVVersionInfo.version
    license = "MIT"
    url = 'https://bitbucket.org/microblink/opencvfork/src'
    description = "Microblink's fork of OpenCV"
    settings = "os", "compiler", "build_type", "arch"

    python_requires = 'MicroblinkConanFile/7.0.0@microblink/stable'
    requires = 'CMakeBuild/12.0.3@microblink/stable'

    generators = "cmake"
    scm = {
        "type": "git",
        "url": "auto",
        "revision": "auto",
        "submodule": "recursive"
    }
    no_copy_source = True
    exports = 'open_cv_helpers.py'

    def package_id(self):
        # Apple has fat libraries, so no need for having separate packages
        if self.settings.os == 'iOS':
            self.info.settings.arch = "ios_fat"

    def build(self):
        CMake = self.python_requires['MicroblinkConanFile'].module.CMake
        build_type = 'Development' if self.settings.build_type == 'Debug' else 'Release'
        cmake = CMake(self, build_type=build_type)

        args = []
        common_options = f'{self.source_folder}/platforms/scripts/mb/common_options.cmake'
        if self.settings.os == 'Macos':
            args.extend(
                [
                    "-DMB_DESKTOP_BUILD=1",
                    "-DHAVE_COCOA=1"
                ]
            )
        elif self.settings.os == 'Linux':
            if self.settings.compiler == 'gcc':
                use_cxx11_abi = 'ON' if self.settings.compiler.libcxx == 'libstdc++11' else 'OFF'
                args.append(f'-DOPENCV_GCC_USE_CXX11_ABI={use_cxx11_abi}')
            optim = 'haswell' if self.settings.arch == 'x86_64_haswell' else 'generic'
            args.extend(
                [
                    f'-DMB_INTEL_OPTIMIZATION=${optim}',
                    '-DENABLE_PRECOMPILED_HEADERS=OFF',
                    "-DMB_DESKTOP_BUILD=1",
                    "-DBUILD_ZLIB=1"
                ]
            )
        elif self.settings.os == 'Windows':
            args.extend(
                [
                    "-DMB_DESKTOP_BUILD=1",
                    "-DBUILD_ZLIB=1"
                ]
            )
        elif self.settings.os == 'Android':
            common_options = f'{self.source_folder}/platforms/scripts/mb/android/common_options.cmake'
        elif self.settings.os == 'iOS':
            if self.settings.os.sdk != None:  # noqa: E711
                args.append(f'-DMB_IOS_SDK={self.settings.os.sdk}')
        elif self.settings.os == 'Emscripten':
            common_options = f'{self.source_folder}/platforms/scripts/mb/emscripten/common_options.cmake'

            compile_to_webassembly = "ON" if self.settings.arch == 'wasm' else 'OFF'
            enable_pthreads = "ON" if self.settings.os.threads == 'true' else 'OFF'
            use_webgl2 = "ON" if self.settings.os.webGLVersion == '2' else 'OFF'
            use_simd = "ON" if self.settings.os.simd == 'true' else 'OFF'
            args.extend(
                [
                    "-DBUILD_ZLIB=1",
                    f"-DMB_EMSCRIPTEN_COMPILE_TO_WEBASSEMBLY={compile_to_webassembly}",
                    f"-DMB_EMSCRIPTEN_ENABLE_PTHREADS={enable_pthreads}",
                    f"-DMB_EMSCRIPTEN_USE_WEBGL2={use_webgl2}",
                    f"-DMB_EMSCRIPTEN_TARGET_ENVIRONMENT={str(self.settings.os.environment)}",
                    f"-DMB_EMSCRIPTEN_SIMD={use_simd}",
                    "-DENABLE_PRECOMPILED_HEADERS=OFF"
                ]
            )

        args.extend(
            [
                '-DMB_TREAT_WARNINGS_AS_ERRORS=OFF',
                f'-C{common_options}',
                f'-DCMAKE_INSTALL_PREFIX={self.build_folder}/install/{cmake.build_type}'
            ]
        )
        cmake.configure(args=args)
        if self.settings.os == 'iOS':
            if self.settings.os.sdk != None:  # noqa: E711
                if self.settings.os.sdk == 'device':
                    cmake.build(args=['--', '-sdk', 'iphoneos', 'ONLY_ACTIVE_ARCH=NO'])
                    cmake.install(args=['--', '-sdk', 'iphoneos', 'ONLY_ACTIVE_ARCH=NO'])
                elif self.settings.os.sdk == 'simulator':
                    cmake.build(args=['--', '-sdk', 'iphonesimulator', 'ONLY_ACTIVE_ARCH=NO'])
                    cmake.install(args=['--', '-sdk', 'iphonesimulator', 'ONLY_ACTIVE_ARCH=NO'])
                elif self.settings.os.sdk == 'maccatalyst':
                    # CMake currently does not support invoking Mac Catalyst builds
                    self.run(
                        f"xcodebuild build -configuration {build_type} -scheme ALL_BUILD " +
                        "-destination 'platform=macOS,variant=Mac Catalyst' ONLY_ACTIVE_ARCH=NO"
                    )
                    self.run(
                        f"xcodebuild build -configuration {build_type} -scheme install " +
                        "-destination 'platform=macOS,variant=Mac Catalyst' ONLY_ACTIVE_ARCH=NO"
                    )
            else:
                # backward compatibility with old iOS toolchain and CMakeBuild < 12.0.0
                cmake.build()
                cmake.install()
        else:
            cmake.build()
            cmake.install()

    def package(self):
        # on Linux and Windows, also copy zlib.h
        if self.settings.os == 'Linux' or self.settings.os == 'Windows' or self.settings.os == 'Emscripten':
            self.copy('3rdparty/zlib/zlib.h', dst='include', keep_path=False)

        if self.settings.os == 'iOS':
            prefix = "Development"
            if self.settings.build_type in ("Release", "ReleaseNoLTO"):
                prefix = "Release"
            self.copy('*.h*', src=f'install/{prefix}/include', dst='include')
            self.copy('*.a', src='install', dst='lib', keep_path=False)
        elif self.settings.os == 'Android':
            prefix = "Development"
            if self.settings.build_type in ("Release", "ReleaseNoLTO"):
                prefix = "Release"
            self.copy('*.h*', src=f'install/{prefix}/include', dst='include')
            self.copy(f"install/{prefix}/sdk/native/*.a", dst="lib", keep_path=False)
        elif self.settings.os == 'Windows':
            build_prefix = 'Development'
            if self.settings.build_type in ("Release", "ReleaseNoLTO"):
                build_prefix = "Release"

            self.copy('*.h*', src=f'install/{build_prefix}/include', dst='include')
            self.copy('*.lib', src=f'install/{build_prefix}/staticlib/{build_prefix}', dst="lib")

            self.copy('lib/*.pdb', dst="lib", keep_path=False)

            self.copy('3rdparty/zlib/zconf.h', dst='include', keep_path=False)
        elif self.settings.os in ('Macos', 'Linux', 'Emscripten'):
            prefix = "Development"
            if self.settings.build_type in ("Release", "ReleaseNoLTO"):
                prefix = "Release"
            self.copy('*.h*', src="install/%s/include/" % prefix, dst='include')
            self.copy("install/%s/share/OpenCV/3rdparty/lib/*.a" % prefix, dst="lib", keep_path=False)
            self.copy("install/%s/lib/*.a" % prefix, dst="lib", keep_path=False)
            if self.settings.os == 'Linux' or self.settings.os == 'Emscripten':
                self.copy('3rdparty/zlib/zconf.h', dst='include', keep_path=False)
        else:
            raise ConanException("Still don't know how to package for " + self.settings.os)
