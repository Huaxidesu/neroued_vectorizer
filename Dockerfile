FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential cmake git \
    libopencv-dev libpotrace-dev liblcms2-dev libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    cmake --build . -j$(nproc) && \
    cmake --install . --prefix /usr/local

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    libopencv-core4.5d libopencv-imgproc4.5d libopencv-imgcodecs4.5d \
    libpotrace0 liblcms2-2 libjpeg8 \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install fastapi uvicorn python-multipart

WORKDIR /workspace

# 拷贝 C++ 二进制核心
COPY --from=builder /usr/local/bin/raster_to_svg /usr/local/bin/

# 拷贝后端和前端代码
COPY app.py /workspace/
COPY index.html /workspace/

EXPOSE 8000

# 启动 Web 服务
ENTRYPOINT ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]