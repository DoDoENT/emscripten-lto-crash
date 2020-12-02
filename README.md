Reproduce Emscripten 2.0.9 linker crash
================

# Reproduce with LTO enabled

```
git clone https://github.com/DoDoENT/emscripten-lto-crash.git
mkdir build
cd build
emcmake cmake -GNinja -DCMAKE_BUILD_TYPE=Release ../emscripten-lto-crash
ninja GTestTest
```

# Reproduce with LTO disabled

```
git clone https://github.com/DoDoENT/emscripten-lto-crash.git
mkdir build
cd build
emcmake cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DMB_ENABLE_LTO=OFF ../emscripten-lto-crash
ninja GTestTest
```
