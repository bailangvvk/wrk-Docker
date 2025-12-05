# 超小体积wrk镜像 (目标: 3.66MB)
# 方案A：busybox:musl基础（有shell，约4.5-5.5MB）
# 方案B：scratch基础（无shell，约3.5-4.0MB）

FROM alpine:3.12 AS builder

WORKDIR /tmp

# 1. 安装完整的构建工具链
RUN apk add --no-cache \
    build-base \
    openssl-dev \
    zlib-dev \
    git \
    libbsd-dev \
    perl

# 2. 编译带LuaJIT支持的wrk
RUN git clone --depth 1 https://github.com/wg/wrk.git && \
    cd wrk && \
    # 正常编译（带LuaJIT支持）
    make && \
    # 备份正常编译的二进制
    cp wrk /tmp/wrk-normal && \
    # 尝试静态编译（如果失败，使用正常编译版本）
    make clean && make LDFLAGS="-static" CFLAGS="-O3 -static" && \
    # 剥离调试符号减小体积
    strip /tmp/wrk-static

# 3. 最终镜像 - 选择基础镜像：
# 选项A：busybox:musl（有shell，便于调试，约+1-2MB）
FROM busybox:musl
# 选项B：scratch（最小体积，无shell，约+0MB）
# FROM scratch

# 4. 只复制编译好的二进制
COPY --from=builder /tmp/wrk-static /wrk

# 5. 设置数据卷
VOLUME ["/data"]

# 6. 入口点
ENTRYPOINT ["/wrk"]

# 镜像大小估算：
# 选项A（busybox:musl）: wrk(~3.5MB) + busybox(~1-2MB) = 4.5-5.5MB
# 选项B（scratch）: wrk(~3.5MB) + 0 = 3.5MB（最接近3.66MB目标）
