# 最小化wrk Docker镜像构建
# 基于多阶段构建和Alpine Linux，最终镜像约8MB

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
    perl \
    # 克隆并编译wrk
    && git clone https://github.com/wg/wrk.git --depth 1 && \
    cd wrk && \
    make clean && \
    make WITH_OPENSSL=0 \
    && du -sh / \
    && strip --strip-all /wrk/* 2>/dev/null || true \
    && du -sh /

# 阶段2: 运行层
FROM alpine:3.19

# 仅安装运行时依赖
RUN apk add --no-cache libgcc

# 从编译层复制wrk二进制文件
COPY --from=builder /wrk/wrk /usr/local/bin/wrk

# 验证wrk能否运行，如果失败则安装libgcc
# RUN /usr/local/bin/wrk --version 2>/dev/null || apk add --no-cache libgcc

# 可选：剥离调试符号减少大小
# RUN strip --strip-all /usr/local/bin/wrk 2>/dev/null || true

# 设置入口点
ENTRYPOINT ["/usr/local/bin/wrk"]
