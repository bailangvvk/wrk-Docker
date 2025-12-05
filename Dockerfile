# Multi-stage build for minimal wrk Docker image without OpenSSL
# Stage 1: Build wrk without OpenSSL support
FROM alpine:3.19 AS build

# Install build dependencies (without openssl-dev)
RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    libbsd-dev \
    zlib-dev \
    perl

# Clone wrk repository
RUN git clone https://github.com/wg/wrk.git --depth 1

# Build wrk without OpenSSL support
RUN cd wrk && \
    make clean && \
    make WITH_OPENSSL=0 \
         LUAJIT_LIB=/wrk/obj/lib \
         LUAJIT_INC=/wrk/obj/include/luajit-2.1

# Stage 2: Create minimal runtime image
FROM alpine:3.19

# Install only minimal runtime dependencies (no openssl)
RUN apk add --no-cache \
    libgcc

# Copy only the wrk binary from build stage
COPY --from=build /wrk/wrk /usr/local/bin/wrk

# Set wrk as entrypoint
ENTRYPOINT ["/usr/local/bin/wrk"]
