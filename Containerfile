FROM docker.io/debian:stable-slim AS base

RUN set -ex; \
    apt-get update; \
    apt-get dist-upgrade -y; \
    apt-get install -y --no-install-recommends \
      tzdata \
      iproute2 \
      net-tools \
      nano \
      ca-certificates \
      curl \
      libcurl4-openssl-dev \
      libdeflate-dev \
      libevent-dev \
      libfmt-dev \
      libminiupnpc-dev \
      libnatpmp-dev \
      libpsl-dev \
      libssl-dev

FROM base AS builder

ARG TransmissionTAG=4.0.0

RUN set -ex; \
    apt-get install -y --no-install-recommends \
      git \
      cmake \
      g++ \
      gettext \
      ninja-build \
      pkg-config \
      xz-utils; \
    mkdir -p /usr/src; \
    cd /usr/src; \
    git config --global advice.detachedHead false; \
    git clone https://github.com/transmission/transmission Transmission --branch ${TransmissionTAG} --single-branch; \
    cd Transmission;   \
    git submodule update --init --recursive; \
    cmake \
      -S . \
      -B obj \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DENABLE_CLI=ON \
      -DENABLE_DAEMON=ON \
      -DENABLE_GTK=OFF \
      -DENABLE_MAC=OFF \
      -DENABLE_QT=OFF \
      -DENABLE_TESTS=OFF \
      -DENABLE_UTILS=ON \
      -DENABLE_WEB=OFF \
      -DRUN_CLANG_TIDY=OFF; \
      cmake --build obj --config RelWithDebInfo; \
      cmake --build obj --config RelWithDebInfo --target install/strip

FROM base AS runtime

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/share /usr/local/share

ENV TZ=Europe/Paris

EXPOSE 9091 51413/tcp 51413/udp
VOLUME /config /watch

ENTRYPOINT [ "transmission-daemon" ]
CMD [ "--config-dir", "/config", "--watch-dir", "/watch", "--foreground" ]