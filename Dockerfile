FROM alpine:3.12 AS build

# 安装构建依赖
RUN apk add --no-cache \
    git make gcc musl-dev \
    libbsd-dev openssl-dev zlib-dev perl

# 克隆 wrk
RUN git clone https://github.com/wg/wrk.git

# 构建静态版本
RUN cd wrk && make clean && \
    make CC="musl-gcc" LDFLAGS="-static" CFLAGS="-O3 -static"

# 验证是否为静态文件
RUN ldd /wrk/wrk 2>&1 | grep -q "not a dynamic executable" || (echo "不是静态二进制文件" && exit 1)

# 最终使用 scratch 镜像
FROM scratch
COPY --from=build /wrk/wrk /wrk
ENTRYPOINT ["/wrk"]