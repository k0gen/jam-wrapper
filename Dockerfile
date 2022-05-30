FROM --platform=linux/arm64/v8 ghcr.io/joinmarket-webui/joinmarket-webui-ui-only:latest AS web-builder

FROM --platform=linux/arm64/v8 python:3.9.7-slim-bullseye
RUN apt-get update \
      && apt-get install -qq --no-install-recommends nginx wget sudo curl tini procps vim git iproute2 supervisor \
      curl build-essential automake pkg-config libtool python3-dev python3-pip python3-setuptools libltdl-dev \
      && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash - && apt-get -y install nodejs && npm install --global http-server
RUN wget https://github.com/mikefarah/yq/releases/download/v4.12.2/yq_linux_arm.tar.gz -O - |\
      tar xz && mv yq_linux_arm /usr/bin/yq
WORKDIR /src/
ADD joinmarket-clientserver/ .
RUN ./install.sh --docker-install --disable-secp-check --without-qt

ENV DATADIR /root/.joinmarket
ENV CONFIG ${DATADIR}/joinmarket.cfg
ENV DEFAULT_CONFIG /root/default.cfg
ENV DEFAULT_AUTO_START /root/autostart
ENV AUTO_START ${DATADIR}/autostart
ENV APP_USER "joinmarket"
ENV APP_PASSWORD "joinmarket"
ENV PATH /src/scripts:$PATH
ENV JMWEBUI_JMWALLETD_HOST "joinmarket-webui.embassy"
ENV JMWEBUI_JMWALLETD_API_PORT "28183"
ENV JMWEBUI_JMWALLETD_WEBSOCKET_PORT "28283"

WORKDIR /

COPY --from=web-builder "/app/" /app/
COPY --from=web-builder "/etc/nginx/" /etc/nginx/

ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
ADD assets/utils/check-web.sh /usr/local/bin/check-web.sh
ADD assets/utils/check-web.sh /usr/local/bin/check-api.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh
RUN chmod +x /usr/local/bin/check-web.sh
RUN chmod +x /usr/local/bin/check-api.sh

EXPOSE 80 28183 27183 8080 3000

COPY ./jmwebui-entrypoint.sh .
RUN chmod +x ./jmwebui-entrypoint.sh

ENTRYPOINT  [ "./jmwebui-entrypoint.sh" ]

# the default parameters to ENTRYPOINT (unless overruled on the command line)
CMD ["nginx", "-g", "daemon off;"]