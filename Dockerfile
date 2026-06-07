FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    libopencv-dev \
    libpotrace-dev \
    liblcms2-dev \
    libjpeg-dev \
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
    libopencv-core4.5d \
    libopencv-imgproc4.5d \
    libopencv-imgcodecs4.5d \
    libpotrace0 \
    liblcms2-2 \
    libjpeg8 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY --from=builder /usr/local/bin/raster_to_svg /usr/local/bin/
COPY --from=builder /usr/local/bin/evaluate_svg /usr/local/bin/

ENTRYPOINT ["raster_to_svg"]
CMD ["--help"]