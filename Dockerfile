# 第一阶段：构建静态的 wrk
FROM alpine:3.12 AS build

# 安装构建依赖
RUN apk add --no-cache \
    git make gcc musl-dev \
    libbsd-dev openssl-dev zlib-dev perl

# 克隆 wrk
RUN git clone --depth 1 https://github.com/wg/wrk.git

# 修改 Makefile 以支持静态编译
RUN cd wrk && \
    # 修改 Makefile 以支持静态链接
    sed -i 's/-lcrypto/-static -lcrypto/g' Makefile && \
    sed -i 's/-lssl/-static -lssl/g' Makefile && \
    sed -i 's/-lz/-static -lz/g' Makefile && \
    sed -i 's/-lbsd/-static -lbsd/g' Makefile

# 构建静态版本
RUN cd wrk && \
    make CC="musl-gcc" LDFLAGS="-static" CFLAGS="-O3 -static"

# 验证是否为静态文件
RUN file /wrk/wrk | grep -q "statically linked" || (echo "不是静态二进制文件" && file /wrk/wrk && exit 1)

# 第二阶段：使用 scratch 镜像
FROM scratch
COPY --from=build /wrk/wrk /wrk
ENTRYPOINT ["/wrk"]