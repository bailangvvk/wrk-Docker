# 构建阶段 - 最大优化
FROM alpine:3.12 AS build

RUN apk add --no-cache \
    git make gcc musl-dev gcc-gnat \
    libbsd-dev openssl-dev zlib-dev perl

# 克隆 wrk
RUN git clone --depth 1 https://github.com/wg/wrk.git

# 构建静态优化版本
RUN cd wrk && \
    # 设置编译参数
    export CFLAGS="-std=c99 -static -O3 -flto -march=native -mtune=native \
        -fipa-pta -fipa-cp -finline-functions -finline-small-functions \
        -findirect-inlining -fmerge-all-constants -fwhole-program \
        -fomit-frame-pointer -funroll-loops -ffast-math" && \
    export LDFLAGS="-static -O3 -flto -Wl,--gc-sections -Wl,--strip-all" && \
    # 编译
    make clean && \
    make CC="musl-gcc" WITH_OPENSSL=1 && \
    # 进一步 strip 减少大小
    strip -s wrk

# 验证阶段
RUN cd wrk && \
    echo "=== 文件信息 ===" && \
    file wrk && \
    echo "=== 大小信息 ===" && \
    ls -lh wrk && \
    echo "=== 动态链接检查 ===" && \
    ldd wrk 2>&1 || true && \
    echo "=== 架构信息 ===" && \
    readelf -h wrk | grep "Machine\|Type"

# 最终镜像 - scratch
FROM scratch
COPY --from=build /wrk/wrk /wrk
ENTRYPOINT ["/wrk"]
