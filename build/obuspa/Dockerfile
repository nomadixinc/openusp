#
# file Dockerfile
#
# Base docker image with all required dependencies for OB-USP-A
#
# Based on Ubuntu 22.10 (Kinetic Kudu), which provides libmosquitto 2.0.11 and libwebsockets 4.1.6
# This image includes some basic compilation tools (automake, autoconf)
#
# One-liner execution line (straightforward build for OB-USP-A execution):
# > docker build -f Dockerfile -t obuspa:latest .
#
# Multi-stage builds execution lines (to tag build stages):
# 1) Create the build environment image:
# > docker build -f Dockerfile -t obuspa:build-env --target build-env .
# 2) Create the OB-USP-A image, then build the application
# > docker build -f Dockerfile -t obuspa:latest --target runner .
#
#FROM --platform=$BUILDPLATFORM ubuntu AS build-env
FROM ubuntu:22.04 AS build-env

# Pinned to match the obuspa git submodule in .gitmodules
ARG OBUSPA_COMMIT=e8350c6892af182a59c7e923c3f8c6d421973469
ARG LIBWEBSOCKETS_TAG=v4.3.3

# CA certs for git clone behind TLS-inspecting proxies (e.g. Cloudflare Gateway)
COPY build/certs/*.crt /usr/local/share/ca-certificates/

# Install dependencies
RUN apt update && apt -y install \
        ca-certificates \
        build-essential \
        libssl-dev \
        libcurl4-openssl-dev\
        libsqlite3-dev \
        libz-dev \
        autoconf \
        automake \
        libtool \
        libmosquitto-dev \
        pkg-config \
        git \
        cmake \
        make \
    && update-ca-certificates \
    && apt clean

RUN mkdir -p /usr/local/src
WORKDIR /usr/local/src/
RUN git clone --branch ${LIBWEBSOCKETS_TAG} --depth 1 https://github.com/warmcat/libwebsockets.git libwebsockets
WORKDIR /usr/local/src/libwebsockets
RUN cmake -B build -S .
RUN cd build && make && make install
# install libs in /usr/local/lib ; configured in /etc/ld.so.conf.d/libc.conf
# ENV LD_LIBRARY_PATH /usr/local/lib:${LD_LIBRARY_PATH}
RUN ldconfig -v

ENV MAKE_JOBS=8

RUN git clone https://github.com/BroadbandForum/obuspa.git /obuspa \
    && cd /obuspa && git checkout ${OBUSPA_COMMIT}
RUN cd /obuspa/ && \
    autoreconf -fi && \
    ./configure && \
    make -j${MAKE_JOBS} && \
    make install

FROM debian:bookworm-slim AS build-release-stage
RUN apt update && apt -y install \
    libssl-dev \
    libsqlite3-dev \
    libcurl4-openssl-dev\
    libmosquitto-dev

WORKDIR /
COPY --from=build-env /usr/local/lib/libwebsockets.* /usr/local/lib
COPY --from=build-env /obuspa/obuspa /bin
COPY ./configs/obuspa/factory_reset_example.txt /etc
RUN ldconfig -v

ENV OBUSPA_ARGS="-p -v 4 -r /etc/factory_reset_example.txt --dbfile /tmp/sqldb"

# Run obuspa with args expanded
CMD obuspa ${OBUSPA_ARGS}
