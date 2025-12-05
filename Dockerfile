# 超小体积wrk镜像 (目标: 3.66MB)
# 基于静态编译 + scratch基础镜像

FROM alpine:3.12 AS builder

WORKDIR /tmp

# 1. 安装静态编译所需依赖
RUN apk add --no-cache \
    openssl-dev \
    zlib-dev \
    git \
    make \
    musl-dev \
    libbsd-dev \
    perl

# 2. 静态编译wrk
RUN git clone --depth 1 https://github.com/wg/wrk.git && \
    cd wrk && \
    make clean || true && \
    # 使用标准gcc进行静态编译
    make LDFLAGS="-static" CFLAGS="-O3 -static" && \
    strip wrk && \
    cp wrk /tmp/wrk-static

# 3. 最终镜像 - 使用scratch空镜像（最小基础）
FROM scratch

# 4. 只复制静态编译的二进制（零运行时依赖）
COPY --from=builder /tmp/wrk-static /wrk

# 5. 设置数据卷（元数据，不占空间）
VOLUME ["/data"]

# 6. 入口点
ENTRYPOINT ["/wrk"]

# 镜像构成：
# 1. wrk静态二进制: ~3.5MB (strip后)
# 2. scratch基础: 0MB
# 总计: ~3.5MB (接近3.66MB目标)
