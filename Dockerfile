# 构建阶段
FROM alpine:3.12 AS build

RUN apk add --no-cache \
    openssl-dev zlib-dev git make gcc musl-dev libbsd-dev perl

RUN git clone --depth 1 https://github.com/wg/wrk.git && \
    cd wrk && make

# 运行时阶段（最小化）
FROM alpine:3.12

# 只安装必要的运行时库
RUN apk add --no-cache libgcc libssl1.1 zlib

# 复制二进制文件
COPY --from=build /wrk/wrk /usr/local/bin/wrk

# 设置非root用户
RUN adduser -D -H wrk_user
USER wrk_user

ENTRYPOINT ["wrk"]
CMD ["--help"]