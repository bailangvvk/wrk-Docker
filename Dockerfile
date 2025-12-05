# 最小化wrk镜像
FROM alpine:3.12 AS builder

WORKDIR /tmp

# 安装构建依赖
RUN apk add --no-cache \
    build-base \
    openssl-dev \
    zlib-dev \
    git \
    libbsd-dev \
    perl

# 编译wrk
RUN git clone --depth 1 https://github.com/wg/wrk.git && \
    cd wrk && \
    make && \
    cp wrk /tmp/wrk-compiled && \
    strip /tmp/wrk-compiled

# 最终镜像 - 使用busybox:musl确保兼容性
FROM busybox:musl
# 选项B：scratch（最小体积，无shell，约+0MB）
# FROM scratch

# 复制二进制并确保可执行
COPY --from=builder /tmp/wrk-compiled /usr/local/bin/wrk
RUN chmod +x /usr/local/bin/wrk

# 设置工作目录和数据卷
VOLUME ["/data"]
WORKDIR /data

# 使用CMD而不是ENTRYPOINT，更灵活
CMD ["wrk"]
