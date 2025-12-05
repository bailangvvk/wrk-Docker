FROM alpine:3.12 AS build

# 安装构建依赖
RUN apk add --no-cache \
    git make gcc musl-dev \
    libbsd-dev openssl-static zlib-static

# 克隆 wrk
RUN git clone --depth 1 https://github.com/wg/wrk.git

# 构建静态版本
RUN cd wrk && \
    make WITH_LIBS=1 LDFLAGS="-static -L/usr/lib -lssl -lcrypto -lz -lbsd"

FROM scratch
COPY --from=build /wrk/wrk /wrk
ENTRYPOINT ["/wrk"]