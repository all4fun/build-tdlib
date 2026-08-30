#!/bin/bash
# author: wh
# date: 2025-05-16
# docs: https://tdlib.github.io/td/build.html?language=Java

set -euo pipefail

# 安装依赖
sudo apt-get update
sudo apt-get install -y make git zlib1g-dev libssl-dev gperf php-cli cmake default-jdk g++

# 克隆 TDLib 1.8.67 对应提交并应用上游构建修复
TDLIB_COMMIT="bc9c263e2bfee06aaab41e82db51a103376030bc"
git clone https://github.com/tdlib/td.git
cd td
git checkout "$TDLIB_COMMIT"
git apply ../patches/tdlib-1.8.67-build-fixes.patch

# 使用 SplitSource 优化编译（减少内存占用）
php SplitSource.php

# 第一阶段：构建 TDLib core
rm -rf build && mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX:PATH=../example/java/td \
      -DTD_ENABLE_JNI=ON \
      ..
cmake --build . --target install -- -j"$(nproc)"
cd ..

# 第二阶段：构建 Java JNI 绑定
cd example/java
rm -rf build && mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX:PATH=../../../tdlib \
      -DTd_DIR:PATH=$(readlink -e ../td/lib/cmake/Td) \
      ..
cmake --build . --target install -- -j"$(nproc)"
cd ../../..

# 恢复源码（在 td 目录下）
php SplitSource.php --undo

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
