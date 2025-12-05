# 简洁版 wrk Docker镜像构建
# 多阶段构建，最终镜像约8MB

# 阶段1: 编译层
FROM alpine:3.19 AS builder

# 安装构建依赖
RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    libbsd-dev \
    zlib-dev \
    openssl-dev \
    perl

# 克隆并编译wrk
RUN git clone https://github.com/wg/wrk.git --depth 1 && \
    cd wrk && \
    make clean && \
    # make WITH_OPENSSL=0
    make WITH_OPENSSL=0 CC="gcc -static" LDFLAGS="-static"

# 阶段2: 运行层
FROM alpine:3.19

# 仅安装运行时依赖
RUN apk add --no-cache libgcc

# 复制wrk二进制文件
COPY --from=builder /wrk/wrk /usr/local/bin/wrk

# 设置入口点
ENTRYPOINT ["/usr/local/bin/wrk"]
