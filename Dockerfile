# 阶段1：基础镜像（与原始一致）
FROM alpine:3.12

# 阶段2：安装编译依赖（原始镜像的构建层）
RUN apk add --no-cache \
    openssl-dev \
    zlib-dev \
    git \
    make \
    gcc \
    musl-dev \
    libbsd-dev \
    perl

# 阶段3：克隆和编译wrk（这是3.62MB的层）
RUN git clone https://github.com/wg/wrk.git && \
    cd wrk && \
    make

# 阶段4：清理和准备最终镜像
RUN cd wrk && \
    cp wrk /tmp/ && \
    cd / && \
    rm -rf /wrk

# 阶段5：复制到最终位置
RUN cp /tmp/wrk /usr/local/bin/wrk && \
    rm -f /tmp/wrk

# 阶段6：创建数据卷和工作目录
VOLUME ["/data"]
WORKDIR /data

# 阶段7：设置入口点
ENTRYPOINT ["/usr/local/bin/wrk"]

# 阶段8：维护者信息（出现在历史中）
MAINTAINER William Yeh <william.pjyeh@gmail.com>
