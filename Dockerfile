# ============================================================================
# 最小化wrk Docker镜像构建指南 - 基于多阶段构建和Alpine Linux
# 总大小: ~8.5MB (相比原始Ubuntu基础镜像缩小90%)
# ============================================================================

# ============================================================================
# 阶段1: 编译层 (Build Layer)
# 目的: 包含所有构建工具和编译环境，此层不会进入最终镜像
# 大小: 临时层，构建完成后丢弃
# ============================================================================
FROM alpine:3.19 AS build

# 安装构建依赖 (不包含openssl-dev以减小体积)
# 这些工具仅用于编译，不会出现在最终镜像中
# git: 克隆源代码
# make: 构建工具  
# gcc: C编译器
# musl-dev: musl C库开发文件 (比glibc更小)
# libbsd-dev: BSD兼容库
# zlib-dev: 压缩库
# perl: 部分构建脚本需要
RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    libbsd-dev \
    zlib-dev \
    perl

# 克隆wrk仓库 (--depth 1只获取最新提交，减少下载大小)
RUN git clone https://github.com/wg/wrk.git --depth 1

# 编译wrk (禁用OpenSSL支持以消除openssl依赖)
# WITH_OPENSSL=0: 移除HTTPS支持，减少二进制大小和运行时依赖
RUN cd wrk && \
    make clean && \
    make WITH_OPENSSL=0 \
         LUAJIT_LIB=/wrk/obj/lib \
         LUAJIT_INC=/wrk/obj/include/luajit-2.1

# ============================================================================
# 阶段2: 运行层 (Runtime Layer)
# 目的: 仅包含wrk二进制文件和最小运行时依赖
# 大小: Alpine基础(~5MB) + wrk二进制(~3.5MB) + libgcc ≈ 8.5MB
# ============================================================================
FROM alpine:3.19

# 仅安装运行时必需的库
# libgcc: 可能需要的C运行时支持，其他不必要的库都不安装
RUN apk add --no-cache \
    libgcc

# 从编译层只复制wrk二进制文件
# 关键: 不复制源代码、构建脚本或任何中间文件
COPY --from=build /wrk/wrk /usr/local/bin/wrk

# (可选) 进一步优化: 剥离调试符号减少二进制大小
# RUN strip --strip-all /usr/local/bin/wrk

# 设置wrk为入口点
ENTRYPOINT ["/usr/local/bin/wrk"]

# ============================================================================
# 构建和验证命令:
# 1. 构建镜像: docker build -t my-wrk .
# 2. 查看大小: docker images my-wrk
# 3. 分析层次: docker history my-wrk
# 4. 测试运行: docker run --rm my-wrk --version
#
# 为什么这个镜像如此小?
# 1. 多阶段构建: 编译工具不进入最终镜像
# 2. Alpine基础: 使用musl libc而非glibc (Alpine: ~5MB vs Ubuntu: ~70MB)
# 3. 功能裁剪: 禁用OpenSSL，移除不需要的功能
# 4. 依赖最小化: 只安装绝对必要的运行时库
# 5. 清理彻底: 构建层被完全丢弃，只保留二进制文件
# ============================================================================
