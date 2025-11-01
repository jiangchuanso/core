# 1. 使用一个包含 oneAPI 的基础镜像
FROM intel/oneapi-basekit:latest

WORKDIR /src

# 2. 【关键】将默认 shell 更改为 bash，以支持 'source' 命令
SHELL ["/bin/bash", "-c"]

# 3. 安装 cmake, make, g++ 等必要的构建工具
#    注意：这个 RUN 指令现在也由 bash 执行，但对于 apt-get 来说没有区别
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    # 在这里添加你的项目需要的其他依赖
    && rm -rf /var/lib/apt/lists/*

# 4. 复制源代码
COPY . .

# 5. 【核心】执行构建
#    现在 'source' 命令可以被正确识别和执行了
RUN source /opt/intel/oneapi/setvars.sh && \
    cmake -B build -S . \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_ARCH=x86-64 \
    -DCMAKE_CXX_FLAGS_RELEASE="-Wno-deprecated-declarations" && \
    cmake --build build -j4

# 6. 准备输出
RUN mkdir -p /build && \
    cp build/liblinguaspark.so /build/ && \
    cp $(find /opt/intel/oneapi -name "libiomp5.so" | head -n 1) /build/

WORKDIR /build
