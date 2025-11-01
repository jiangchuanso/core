# 使用一个已经安装了 oneAPI 的基础镜像
# 例如: intel/oneapi-basekit:latest
FROM intel/oneapi-basekit:latest

WORKDIR /src

# 1. 安装系统依赖 (假设是 Debian/Ubuntu)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    # 在这里添加你的项目需要的其他 -dev 包
    # e.g., libboost-all-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. 复制源代码
COPY . .

# 3. 设置 oneAPI 环境并运行 CMake 配置
#    将其拆分为单独的 RUN 指令，便于调试和缓存
RUN source /opt/intel/oneapi/setvars.sh && \
    cmake -B build -S . \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_ARCH=x86-64 \
    -DCMAKE_CXX_FLAGS_RELEASE="-Wno-deprecated-declarations"

# 4. 执行编译
RUN source /opt/intel/oneapi/setvars.sh && \
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
