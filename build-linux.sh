#!/bin/bash
# author: wh
# date: 2025-05-16
# docs: https://tdlib.github.io/td/build.html?language=Java

set -euo pipefail

# 安装依赖
sudo apt-get update
sudo apt-get install -y make git zlib1g-dev libssl-dev gperf php-cli cmake default-jdk g++

# 克隆 TDLib
git clone --branch master --depth 1 https://github.com/tdlib/td.git
cd td

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

# 恢复源码
php SplitSource.php --undo

# 验证输出
echo "=== Build Output ==="
ls -la td/tdlib/
echo "=== Build Complete ==="
