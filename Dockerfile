# 最小化wrk Docker镜像构建 - 激进优化版
# 支持多架构构建 (x86_64和ARM64)
# 基于静态链接和最小化基础镜像，最终镜像约2-3MB

# 阶段1: 编译层 (使用完整工具链)
FROM alpine:3.22 AS builder

# 安装构建依赖
RUN set -eux && apk add --no-cache \
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
    # 使用静态链接和激进优化
    # -static: 完全静态链接，消除运行时依赖
    # -O3: 最高级别优化
    # -flto: 链接时优化
    # -fomit-frame-pointer: 省略帧指针
    # -DNDEBUG: 禁用调试断言
    make WITH_OPENSSL=0 \
         CFLAGS="-O3 -flto -fomit-frame-pointer -DNDEBUG -static" \
         LDFLAGS="-flto -static" \
    && echo "编译后大小:" && ls -lh /wrk/wrk \
    && strip -v --strip-all --strip-unneeded /wrk/wrk \
    && echo "strip后大小:" && ls -lh /wrk/wrk \
    && echo "检查依赖:" && ldd /wrk/wrk 2>/dev/null || echo "静态链接，无动态依赖"

# 阶段2: 运行层 (使用scratch或最小化镜像)
FROM scratch

# 从编译层复制wrk二进制文件
COPY --from=builder /wrk/wrk /wrk

# 设置入口点
ENTRYPOINT ["/wrk"]
