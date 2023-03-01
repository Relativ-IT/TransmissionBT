FROM docker.io/alpine:latest AS base

FROM base AS builder

ARG BTAG=4.0.1

RUN set -ex && \
    apk add --no-cache --upgrade \
      git \
      python3 \
      build-base \
      cmake \
      curl-dev \
      gettext-dev \
      openssl-dev \
      linux-headers \
      samurai

WORKDIR /usr/src
RUN git config --global advice.detachedHead false; \
    git clone https://github.com/transmission/transmission transmission --branch ${BTAG} --single-branch

WORKDIR /usr/src/transmission
RUN git submodule update --init --recursive; \
    cmake \
      -S . \
      -B obj \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_CLI=OFF \
      -DENABLE_DAEMON=ON \
      -DENABLE_GTK=OFF \
      -DENABLE_MAC=OFF \
      -DENABLE_QT=OFF \
      -DENABLE_TESTS=OFF \
      -DENABLE_UTILS=OFF \
      -DRUN_CLANG_TIDY=OFF \
      -DWITH_CRYPTO="openssl" \
      -DWITH_SYSTEMD=OFF && \
    cmake --build obj --config Release; \
    cmake --build obj --config Release --target install/strip

FROM base AS runtime

RUN set -ex && \
    apk update && \
    # apk add --no-cache --upgrade libcurl libintl libgcc libssl3 libstdc++ tzdata
    apk add --no-cache --upgrade libcurl libintl libgcc libstdc++

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/share /usr/local/share

EXPOSE 9091/tcp 51413/tcp 51413/udp
VOLUME /config /watch /download

ENTRYPOINT [ "transmission-daemon" ]
CMD [ "--config-dir", "/config", "--watch-dir", "/watch", "--download-dir", "/download", "--foreground" ]