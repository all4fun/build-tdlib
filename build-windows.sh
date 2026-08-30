#!/bin/bash
# author: wh
# date: 2025-05-16
# docs: https://tdlib.github.io/td/build.html?language=Java
# note: Run in Git Bash or PowerShell with bash

set -euo pipefail

# 设置 Java 环境变量 (GitHub Actions windows-latest)
export JAVA_HOME="${JAVA_HOME:-C:\\Program Files\\Eclipse Adoptium\\jdk-21.0.3.9-hotspot}"

# 克隆 TDLib 1.8.67 对应提交并应用上游构建修复
TDLIB_COMMIT="bc9c263e2bfee06aaab41e82db51a103376030bc"
git clone https://github.com/tdlib/td.git
cd td
git checkout "$TDLIB_COMMIT"
git apply ../patches/tdlib-1.8.67-build-fixes.patch

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

# 返回 repo root 验证输出
cd ..
echo "=== Build Output ==="
# 构建产物实际在 td/tdlib（安装路径是 ../../../tdlib）
if [ -d "td/tdlib/bin" ]; then
  ls -la td/tdlib/
  ls -la td/tdlib/bin/
else
  echo "ERROR: td/tdlib/bin not found"
  find . -name "tdlib" -type d 2>/dev/null || true
  exit 1
fi
echo "=== Build Complete ==="
