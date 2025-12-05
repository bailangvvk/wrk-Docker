# 简单有效的多阶段构建
FROM alpine:3.12 AS builder

# 安装编译依赖
RUN apk add --no-cache \
    openssl-dev \
    zlib-dev \
    git \
    make \
    gcc \
    musl-dev \
    libbsd-dev \
    perl

# 克隆和编译wrk
RUN git clone https://github.com/wg/wrk.git && \
    cd wrk && \
    make && \
    cp wrk /tmp/wrk-compiled

# 最终镜像
FROM alpine:3.12

# 最小运行时
RUN apk add --no-cache libgcc

# 复制二进制
COPY --from=builder /tmp/wrk-compiled /usr/local/bin/wrk

# 设置数据卷
VOLUME ["/data"]
WORKDIR /data

# 入口点
ENTRYPOINT ["/usr/local/bin/wrk"]
