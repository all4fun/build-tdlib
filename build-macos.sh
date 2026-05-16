#!/bin/bash
# author: wh
# date: 2025-05-16
# docs: https://tdlib.github.io/td/build.html?language=Java

set -euo pipefail

# 安装依赖
brew install gperf cmake openssl coreutils openjdk

# 克隆 TDLib
git clone --branch master --depth 1 https://github.com/tdlib/td.git
cd td

# 第一阶段：构建 TDLib core
rm -rf build && mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DJAVA_HOME=/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home/ \
      -DOPENSSL_ROOT_DIR=/opt/homebrew/opt/openssl/ \
      -DCMAKE_INSTALL_PREFIX:PATH=../example/java/td \
      -DTD_ENABLE_JNI=ON \
      ..
cmake --build . --target install -- -j"$(sysctl -n hw.ncpu)"
cd ..

# 第二阶段：构建 Java JNI 绑定
cd example/java
rm -rf build && mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DJAVA_HOME=/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home/ \
      -DCMAKE_INSTALL_PREFIX:PATH=../../../tdlib \
      -DTd_DIR:PATH=$(greadlink -e ../td/lib/cmake/Td) \
      ..
cmake --build . --target install -- -j"$(sysctl -n hw.ncpu)"
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
