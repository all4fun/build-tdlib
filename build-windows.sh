#!/bin/bash
# author: wh
# date: 2025-05-16
# docs: https://tdlib.github.io/td/build.html?language=Java
# note: Run in Git Bash or PowerShell with bash

set -euo pipefail

# 设置 Java 环境变量 (GitHub Actions windows-latest)
export JAVA_HOME="${JAVA_HOME:-C:\\Program Files\\Eclipse Adoptium\\jdk-21.0.3.9-hotspot}"

# 克隆 TDLib
git clone --branch master --depth 1 https://github.com/tdlib/td.git
cd td

# 克隆并设置 vcpkg
git clone --depth 1 https://github.com/Microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.bat
./vcpkg.exe install gperf:x64-windows openssl:x64-windows zlib:x64-windows --clean-after-build
cd ..

# 第一阶段：构建 TDLib core
rm -rf build && mkdir build && cd build
cmake -A x64 \
      -DCMAKE_INSTALL_PREFIX:PATH=../example/java/td \
      -DTD_ENABLE_JNI=ON \
      -DCMAKE_TOOLCHAIN_FILE:FILEPATH=../vcpkg/scripts/buildsystems/vcpkg.cmake \
      ..
cmake --build . --target install --config Release
cd ..

# 第二阶段：构建 Java JNI 绑定
cd example/java
rm -rf build && mkdir build && cd build
cmake -A x64 \
      -DCMAKE_INSTALL_PREFIX:PATH=../../../tdlib \
      -DCMAKE_TOOLCHAIN_FILE:FILEPATH=../../../vcpkg/scripts/buildsystems/vcpkg.cmake \
      -DTd_DIR:PATH="$(cygpath -w "$(pwd)/../td/lib/cmake/Td")" \
      ..
cmake --build . --target install --config Release
cd ../../..

# 验证输出
echo "=== Build Output ==="
ls -la td/tdlib/
echo "=== Build Complete ==="
