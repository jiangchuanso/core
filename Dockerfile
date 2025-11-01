# 1. 使用正确的基础镜像
FROM intel/oneapi-basekit:latest

WORKDIR /src

# 2. 安装所有必需的构建工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    # 在这里添加你的项目需要的其他依赖，比如 libboost-all-dev
    && rm -rf /var/lib/apt/lists/*

# 3. 复制源代码
COPY . .

# 4. 执行构建（现在应该能找到 cmake 和 setvars.sh 了）
RUN source /opt/intel/oneapi/setvars.sh && \
    cmake -B build -S . \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_ARCH=x86-64 \
    -DCMAKE_CXX_FLAGS_RELEASE="-Wno-deprecated-declarations" && \
    cmake --build build -j4
    
# 5. 准备输出目录并复制文件
#    使用更稳健的方式查找和复制依赖库
RUN mkdir -p /build && \
    cp build/liblinguaspark.so /build/ && \
    cp $(find /opt/intel/oneapi -name "libiomp5.so" | head -n 1) /build/

# 设置最终工作目录
WORKDIR /build

# (可选) 如果这是一个运行时镜像，可以在这里清理构建源码和工具
RUN apt-get purge -y build-essential cmake git && rm -rf /src
