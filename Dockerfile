# 超小体积wrk镜像 (目标: 3.66MB)
# 基于静态编译 + scratch基础镜像

FROM alpine:3.12 AS builder

WORKDIR /tmp

# 1. 安装完整的构建工具链（包含gcc、make等）
RUN apk add --no-cache \
    build-base \
    openssl-dev \
    zlib-dev \
    git \
    libbsd-dev \
    perl

# 2. 编译带LuaJIT支持的wrk（先正常编译，再尝试静态链接）
RUN git clone --depth 1 https://github.com/wg/wrk.git && \
    cd wrk && \
    # 正常编译（带LuaJIT支持）
    make && \
    # # 备份正常编译的二进制
    # cp wrk /tmp/wrk-normal && \
    # # 尝试静态编译（如果失败，使用正常编译版本）
    # (make clean && make LDFLAGS="-static" CFLAGS="-O3 -static" 2>/dev/null || true) && \
    # # 如果静态编译成功，使用静态版本；否则使用正常版本
    # [ -f wrk ] && cp wrk /tmp/wrk-static || cp /tmp/wrk-normal /tmp/wrk-static && \
    # # 剥离调试符号减小体积
    # strip /tmp/wrk-static
    strip /wrk/wrk

# 3. 最终镜像 - 使用scratch空镜像（最小基础）
# FROM scratch
FROM busybox:musl

# 4. 只复制编译好的二进制
COPY --from=builder /wrk/wrk /wrk

# 5. 设置数据卷（元数据，不占空间）
VOLUME ["/data"]

# 6. 入口点
ENTRYPOINT ["/wrk"]

# 镜像构成：
# 1. wrk二进制（带LuaJIT支持）: ~3.5-4.0MB
# 2. scratch基础: 0MB
# 总计: ~3.5-4.0MB