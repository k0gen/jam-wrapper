FROM --platform=linux/arm64/v8 ghcr.io/joinmarket-webui/joinmarket-webui-standalone:v0.0.10-clientserver-v0.9.6@sha256:12bba3c1761a277a7e642cd0e9c29c97cc73fb697dc8f652a4e57bd2f99d89f3
# RUN apt-get update \
#       && apt-get install -qq --no-install-recommends nginx wget sudo curl tini procps vim git iproute2 supervisor \
#       curl build-essential automake pkg-config libtool python3-dev python3-pip python3-setuptools libltdl-dev \
#       && rm -rf /var/lib/apt/lists/*
# RUN curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash - && apt-get -y install nodejs && npm install --global http-server
RUN wget https://github.com/mikefarah/yq/releases/download/v4.12.2/yq_linux_arm.tar.gz -O - |\
      tar xz && mv yq_linux_arm /usr/bin/yq

ENV DATADIR /root/.joinmarket
ENV CONFIG ${DATADIR}/joinmarket.cfg
ENV DEFAULT_CONFIG /root/default.cfg
ENV DEFAULT_AUTO_START /root/autostart
ENV AUTO_START ${DATADIR}/autostart
ENV APP_USER "joinmarket"
ENV APP_PASSWORD "joinmarket"
ENV PATH /src/scripts:$PATH
ENV JMWEBUI_JMWALLETD_HOST "jam.embassy"
ENV JMWEBUI_JMWALLETD_API_PORT "28183"
ENV JMWEBUI_JMWALLETD_WEBSOCKET_PORT "28283"

ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
ADD assets/utils/check-web.sh /usr/local/bin/check-web.sh
ADD assets/utils/check-api.sh /usr/local/bin/check-api.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh
RUN chmod +x /usr/local/bin/check-web.sh
RUN chmod +x /usr/local/bin/check-api.sh

EXPOSE 80 28183 27183 8080 3000

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]