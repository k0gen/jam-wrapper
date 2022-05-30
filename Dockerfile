FROM --platform=linux/arm64/v8 ghcr.io/joinmarket-webui/joinmarket-webui-standalone:latest AS jm-builder
RUN apt-get update && apt-get upgrade -y && apt-get -y install wget sudo xsel
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash - && apt-get -y install nodejs && npm install --global http-server
RUN wget https://github.com/mikefarah/yq/releases/download/v4.12.2/yq_linux_arm.tar.gz -O - |\
      tar xz && mv yq_linux_arm /usr/bin/yq
WORKDIR /root/.joinmarket/
COPY . /dot_joinmarket


FROM --platform=linux/arm64/v8 ghcr.io/joinmarket-webui/joinmarket-webui-ui-only:latest AS web-builder


FROM --platform=linux/arm64/v8 python:3.9.10-slim-bullseye
RUN apt update && apt install -y nginx curl libxkbcommon-x11-0

COPY --from=jm-builder "/src/" /src/
COPY --from=jm-builder "/usr/bin/yq" /usr/bin/yq
COPY --from=jm-builder "/usr/bin/http-server" /usr/bin/http-server
COPY --from=jm-builder "/dot_joinmarket/" /root/.joinmarket/
COPY --from=jm-builder "/usr/local/lib/python3.9/site-packages" /usr/local/lib/python3.9/site-packages
COPY --from=web-builder "/app/" /app/
COPY --from=web-builder "/etc/nginx/snippets/proxy-params.conf" /etc/nginx/snippets/proxy-params.conf
COPY --from=web-builder "/etc/nginx/templates/default.conf.template" /etc/nginx/templates/default.conf.template

ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
ADD assets/utils/check-web.sh /usr/local/bin/check-web.sh
ADD assets/utils/check-web.sh /usr/local/bin/check-api.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh
RUN chmod +x /usr/local/bin/check-web.sh
RUN chmod +x /usr/local/bin/check-api.sh
RUN chmod +x /usr/bin/yq
RUN chmod +x /usr/bin/http-server

EXPOSE 80 28183 27183 8080 3000

COPY ./jmwebui-entrypoint.sh .
RUN chmod +x ./jmwebui-entrypoint.sh

ENTRYPOINT  [ "./jmwebui-entrypoint.sh" ]

# the default parameters to ENTRYPOINT (unless overruled on the command line)
CMD ["nginx", "-g", "daemon off;"]