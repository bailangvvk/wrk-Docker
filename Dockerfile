# Multi-stage build for minimal wrk Docker image
# Stage 1: Build wrk as static binary
FROM alpine:3.19 AS build

# Install build dependencies
RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    musl-utils \
    libbsd-dev \
    openssl-dev \
    zlib-dev \
    perl

# Clone wrk repository
RUN git clone https://github.com/wg/wrk.git --depth 1

# Build wrk as static binary for minimal size
RUN cd wrk && \
    make clean && \
    make WITH_OPENSSL=1 \
         LUAJIT_LIB=/wrk/obj/lib \
         LUAJIT_INC=/wrk/obj/include/luajit-2.1 \
         LDFLAGS="-static -L/wrk/obj/lib" \
         CFLAGS="-O3 -static -D_GNU_SOURCE -I/wrk/obj/include/luajit-2.1"

# Stage 2: Create minimal runtime image
FROM scratch

# Copy only the wrk binary from build stage
COPY --from=build /wrk/wrk /wrk

# Set wrk as entrypoint
ENTRYPOINT ["/wrk"]
