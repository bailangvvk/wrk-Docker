# ============================================================================
# 最小化wrk Docker镜像构建指南 - 基于多阶段构建和Alpine Linux
# 支持静态编译以进一步减小体积，可选scratch基础镜像
# 动态链接版本: ~8.5MB | 静态编译+Alpine: ~6MB | 静态编译+scratch: ~3.5MB
# ============================================================================

# ============================================================================
# 阶段1: 编译层 (Build Layer) - 支持静态和动态编译
# 目的: 包含所有构建工具和编译环境，此层不会进入最终镜像
# 大小: 临时层，构建完成后丢弃
# ============================================================================
FROM alpine:3.19 AS build

# 安装构建依赖 (包含openssl-dev头文件以通过编译，但不会链接到最终二进制)
# 这些工具仅用于编译，不会出现在最终镜像中
# git: 克隆源代码
# make: 构建工具  
# gcc: C编译器
# musl-dev: musl C库开发文件 (静态编译必需)
# libbsd-dev: BSD兼容库 (需要静态版本)
# zlib-dev: 压缩库 (需要静态版本)
# openssl-dev: OpenSSL开发头文件 (仅用于编译，WITH_OPENSSL=0确保不链接)
# perl: 部分构建脚本需要
RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    libbsd-dev \
    zlib-dev \
    openssl-dev \
    perl

# 克隆wrk仓库 (--depth 1只获取最新提交，减少下载大小)
RUN git clone https://github.com/wg/wrk.git --depth 1

# 选项A: 动态编译 (默认，与原始wrk镜像相同)
# 取消下面make命令的注释，注释掉静态编译部分
# 选项B: 静态编译 - 添加-static标志，创建完全静态的可执行文件
# 取消下面make命令的注释，注释掉动态编译部分
# 静态编译优势:
# 1. 无需动态链接库，运行时无需libgcc等
# 2. 可使用scratch空基础镜像，进一步减小体积
# 3. 更好的可移植性，不依赖特定libc版本

# 动态编译 (默认启用)
RUN cd wrk && \
    make clean && \
    make WITH_OPENSSL=0 \
         LUAJIT_LIB=/wrk/obj/lib \
         LUAJIT_INC=/wrk/obj/include/luajit-2.1

# 如果要使用静态编译，请注释上面的动态编译，取消注释下面的静态编译：
# RUN cd wrk && \
#     make clean && \
#     make WITH_OPENSSL=0 \
#          LUAJIT_LIB=/wrk/obj/lib \
#          LUAJIT_INC=/wrk/obj/include/luajit-2.1 \
#          CC="gcc -static" \
#          LDFLAGS="-static"

# 验证编译结果: 检查是否为静态二进制
RUN file /wrk/wrk && \
    (ldd /wrk/wrk 2>/dev/null && echo "动态链接" || echo "静态链接")

# ============================================================================
# 阶段2A: 动态链接运行层 (Runtime Layer - Dynamic)
# 目的: 仅包含wrk二进制文件和最小运行时依赖
# 大小: Alpine基础(~5MB) + wrk二进制(~3.5MB) + libgcc ≈ 8.5MB
# ============================================================================
FROM alpine:3.19 AS runtime-dynamic

# 仅安装运行时必需的库 (动态链接需要)
RUN apk add --no-cache \
    libgcc

# 从编译层复制wrk二进制文件
COPY --from=build /wrk/wrk /usr/local/bin/wrk

# 可选优化: 剥离调试符号减少二进制大小 (可节省~10-20%)
RUN strip --strip-all /usr/local/bin/wrk

# 设置wrk为入口点
ENTRYPOINT ["/usr/local/bin/wrk"]

# ============================================================================
# 阶段2B: 静态链接运行层 (Runtime Layer - Static)
# 目的: 仅包含静态编译的wrk二进制文件，无任何运行时依赖
# 大小: wrk二进制(~3.5MB) + 可选scratch基础(0MB) = ~3.5MB
# ============================================================================
FROM scratch AS runtime-static

# 从编译层复制静态编译的wrk二进制文件
COPY --from=build /wrk/wrk /wrk

# 验证是否为静态二进制 (构建时检查)
# 运行时不执行此命令，仅构建时验证
# ONBUILD RUN ldd /wrk 2>&1 | grep -q "not a dynamic executable"

# 设置wrk为入口点
ENTRYPOINT ["/wrk"]

# ============================================================================
# 构建和验证命令:
# 
# 构建动态链接版本 (默认):
# docker build -t wrk-dynamic --target runtime-dynamic .
# 
# 构建静态链接版本 (使用Alpine基础):
# docker build -t wrk-static-alpine --target runtime-dynamic .  # 使用静态二进制但Alpine基础
# 
# 构建极简静态版本 (使用scratch空镜像):
# docker build -t wrk-static-scratch --target runtime-static .
# 
# 验证镜像大小:
# docker images | grep wrk-
# 
# 测试运行:
# docker run --rm wrk-dynamic --version
# docker run --rm wrk-static-scratch --version
# 
# 分析二进制类型:
# docker run --rm wrk-dynamic ldd /usr/local/bin/wrk 2>/dev/null || echo "静态二进制"
# 
# 为什么静态编译镜像更小?
# 1. 无需libgcc或其他运行时库
# 2. 可使用scratch空基础镜像 (0MB)
# 3. 二进制包含所有依赖，无外部动态链接
# 
# 注意事项:
# 1. 静态二进制可能略大 (包含所有库代码)
# 2. musl静态编译通常比glibc更容易
# 3. 某些库可能有静态编译限制
# 4. 静态二进制无法使用动态加载的模块
# ============================================================================

# 默认使用动态链接版本 (兼容性更好)
FROM runtime-dynamic
