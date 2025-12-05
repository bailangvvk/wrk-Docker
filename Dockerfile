# 最小化wrk Docker镜像构建
# 基于多阶段构建和Alpine Linux，最终镜像约8MB

# 阶段1: 编译层
FROM alpine:3.19 AS builder

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
# 克隆并编译wrk (添加编译优化选项)
    && git clone https://github.com/wg/wrk.git --depth 1 && \
    cd wrk && \
    make clean && \
    # CFLAGS优化选项说明:
    # -O2: 平衡优化级别 (速度vs体积)
    # -flto: 链接时优化 (需配合LDFLAGS)
    # -march=x86-64: 针对x86-64架构优化 (兼容性好)
    # -mtune=generic: 通用CPU调优
    # -fomit-frame-pointer: 省略帧指针 (节省寄存器)
    make WITH_OPENSSL=0 \
         CFLAGS="-O2 -flto -march=x86-64 -mtune=generic -fomit-frame-pointer" \
         LDFLAGS="-flto" \
    && echo "编译后大小:" && ls -lh /wrk/wrk \
    && strip -v --strip-all /wrk/wrk \
    && echo "strip后大小:" && ls -lh /wrk/wrk

# 阶段2: 运行层
FROM alpine:3.19

# 安装运行时依赖 - libgcc提供libgcc_s.so.1共享库
RUN apk add --no-cache libgcc

# 从编译层复制wrk二进制文件
COPY --from=builder /wrk/wrk /usr/local/bin/wrk

# 设置入口点
ENTRYPOINT ["/usr/local/bin/wrk"]
