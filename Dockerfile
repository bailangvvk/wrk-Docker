# 基于Alpine 3.12的多阶段构建（与原始镜像一致）
FROM alpine:3.12 AS builder

# 安装编译依赖（与原始镜像的依赖匹配）
RUN apk add --no-cache \
    openssl-dev \
    zlib-dev \
    git \
    make \
    gcc \
    musl-dev \
    libbsd-dev \
    perl

# 克隆和编译wrk（这是产生3.62MB层的关键步骤）
RUN git clone https://github.com/wg/wrk.git && \
    cd wrk && \
    make && \
    cp wrk /tmp/wrk-compiled

# 最终镜像阶段
FROM alpine:3.12

# 只安装运行时必需的库（libgcc）
RUN apk add --no-cache libgcc

# 从构建阶段复制编译好的二进制
COPY --from=builder /tmp/wrk-compiled /usr/local/bin/wrk

# 设置数据卷和工作目录（与原始镜像一致）
VOLUME ["/data"]
WORKDIR /data

# 设置入口点
ENTRYPOINT ["/usr/local/bin/wrk"]

# 维护者信息（可选）
# MAINTAINER Your Name <your@email.com>
