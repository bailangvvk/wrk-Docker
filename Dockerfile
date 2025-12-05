FROM alpine:3.12 AS build

# 安装依赖，包括 perl（构建 OpenSSL 所必需）
RUN apk add --no-cache \
    openssl-dev \
    zlib-dev \
    git make \
    gcc \
    musl-dev \
    libbsd-dev \
    perl \
    && \
    git clone https://github.com/wg/wrk.git && \
      cd wrk && make

# Stage 2: Runtime 环境极简
FROM alpine:3.12
RUN apk add --no-cache \
    libgcc
    
RUN adduser -D -H wrk_user

USER wrk_user
# COPY --from=build /wrk/wrk /usr/bin/wrk
# ENTRYPOINT ["/usr/bin/wrk"]

# FROM alpine:3.12 AS build

# # 安装构建 wrk 及静态链接所需依赖
# RUN apk add --no-cache \
#     git make gcc musl-dev musl-utils \
#     libbsd-dev openssl-dev zlib-dev perl

# # 克隆 wrk
# RUN git clone https://github.com/wg/wrk.git

# # 构建 wrk 为静态链接二进制
# RUN cd wrk && make clean && \
#     make CC="musl-gcc" LDFLAGS="-static" CFLAGS="-O3 -static"

# FROM scratch
COPY --from=build /wrk/wrk /wrk
ENTRYPOINT ["/wrk"]