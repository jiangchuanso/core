# 使用一个支持多架构的基础镜像
FROM buildpack-deps:oldstable-curl

ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装所有架构通用的构建依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    cmake \
    libpcre2-dev \
    liblapack-dev \
    libopenblas-dev

# 2. 根据目标架构安装特定的依赖
# ARG TARGETARCH 是 Docker Buildx 提供的内置变量，值为 "amd64" 或 "arm64"
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        # --- 仅在 x86_64 上执行 ---
        echo "---- Building for x86_64, installing Intel OneAPI MKL ----"; \
        wget -qO- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor -o /usr/share/keyrings/oneapi-archive-keyring.gpg && \
        echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" > /etc/apt/sources.list.d/oneAPI.list && \
        apt-get update && \
        apt-get install -y intel-oneapi-mkl-devel; \
    else \
        # --- 仅在 ARM64 上执行 ---
        echo "---- Building for ARM64, skipping Intel OneAPI MKL ----"; \
    fi

WORKDIR /app/linguaspark
COPY . /app

# --- 修改部分 ---

# 为后续的 RUN 指令显式使用 bash，因为 Intel 的 setvars.sh 脚本可能需要它
SHELL ["/bin/bash", "-c"]

ARG TARGETARCH
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        echo "---- Building for x86_64 ----" && \
        export BUILD_ARCH="x86-64" && \
        export MKLROOT="/opt/intel/oneapi/mkl/latest" && \
        # 使用 '.' 代替 'source' 以获得更好的兼容性，两者在 bash 中等价
        . /opt/intel/oneapi/setvars.sh && \
        cmake -B build -S . \
              -DCMAKE_BUILD_TYPE=Release \
              -DBUILD_ARCH=${BUILD_ARCH} \
              -DCMAKE_CXX_FLAGS_RELEASE="-Wno-deprecated-declarations" && \
        cmake --build build -j$(nproc); \
    else \
        echo "---- Building for aarch64 ----" && \
        export BUILD_ARCH="aarch64" && \
        cmake -B build -S . \
              -DCMAKE_BUILD_TYPE=Release \
              -DBUILD_ARCH=${BUILD_ARCH} \
              -DCMAKE_CXX_FLAGS_RELEASE="-Wno-deprecated-declarations" && \
        cmake --build build -j$(nproc); \
    fi

# --- 修改结束 ---

# 4. 复制构建产物和对应的运行时依赖
RUN mkdir -p /build && \
    cp build/liblinguaspark.so /build/ && \
    if [ "$TARGETARCH" = "amd64" ]; then \
        # x86_64: 复制 Intel OpenMP 库
        echo "---- Copying Intel OpenMP library (libiomp5.so) ----"; \
        cp /opt/intel/oneapi/compiler/latest/linux/compiler/lib/intel64_lin/libiomp5.so /build/; \
    else \
        # ARM64: 复制 GCC OpenMP 库 (libgomp)
        echo "---- Copying GCC OpenMP library (libgomp.so.1) ----"; \
        # 使用 gcc -print-multiarch 获取正确的库路径，如 aarch64-linux-gnu
        LIB_PATH=$(gcc -print-multiarch 2>/dev/null || echo "."); \
        cp /usr/lib/${LIB_PATH}/libgomp.so.1 /build/ || \
        echo "Warning: Could not find libgomp.so.1. The final image might be missing an OpenMP runtime."; \
    fi
