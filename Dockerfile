# 先集成 xcaddy 的编译环境
FROM caddy:2.6.4-builder AS builder

# 使用 xcaddy 编译 caddy 并携带想要的第三方模块
RUN xcaddy build \
    --with github.com/caddyserver/nginx-adapter \
    --with github.com/caddyserver/replace-response \
    --with github.com/WingLim/caddy-webhook

# 完成编译后再继承 alpine 来构建生产镜像
FROM alpine:3.16

# 安装一些必要的依赖包
RUN apk add --no-cache ca-certificates libcap mailcap

# 准备 caddy 所需的目录和一些默认配置文件等
RUN set -eux; \
	mkdir -p \
		/config/caddy \
		/data/caddy \
		/etc/caddy \
		/usr/share/caddy \
	; \
	wget -O /etc/caddy/Caddyfile "https://github.com/caddyserver/dist/raw/a8ef04588bf34a9523b76794d601c6e9cb8e31d3/config/Caddyfile"; \
	wget -O /usr/share/caddy/index.html "https://github.com/caddyserver/dist/raw/a8ef04588bf34a9523b76794d601c6e9cb8e31d3/welcome/index.html"

# 将自定义编译的 caddy 复制到 alpine 镜像中
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# 设置 caddy 的执行权限
RUN set -eux; \
	setcap cap_net_bind_service=+ep /usr/bin/caddy; \
	chmod +x /usr/bin/caddy; \
	caddy version

# 安装需要的 caddy 包
# RUN caddy add-package github.com/caddyserver/transform-encoder

# -----------------------------------------------------------------------------------------
# 以下的一些初始化设置参考自
# https://github.com/caddyserver/caddy-docker/blob/master/2.4/alpine/Dockerfile#L36-L62
# -----------------------------------------------------------------------------------------

# See https://caddyserver.com/docs/conventions#file-locations for details
ENV XDG_CONFIG_HOME /config
ENV XDG_DATA_HOME /data

VOLUME /config
VOLUME /data

EXPOSE 80
EXPOSE 443
EXPOSE 443/udp
EXPOSE 2019

WORKDIR /srv

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
