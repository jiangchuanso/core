FROM buildpack-deps:oldstable-curl

ENV DEBIAN_FRONTEND=noninteractive

RUN wget -qO- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor -o /usr/share/keyrings/oneapi-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" > /etc/apt/sources.list.d/oneAPI.list

RUN apt-get update && \
    apt-get install -y build-essential git cmake libpcre2-dev \
    liblapack-dev libblas-dev libopenblas-dev intel-oneapi-mkl-devel

ENV MKLROOT=/opt/intel/oneapi/mkl/latest

WORKDIR /app/linguaspark
COPY . /app

RUN cmake -B build -S . \
          -DCMAKE_BUILD_TYPE=Release \
          -DBUILD_ARCH=x86-64 \
          -DCMAKE_CXX_FLAGS_RELEASE="-Wno-deprecated-declarations" && \
    cmake --build build -j4 && \
    mkdir -p /build && \
    cp build/liblinguaspark.so /build/ && \
    cp /opt/intel/oneapi/compiler/latest/lib/libiomp5.so /build/
