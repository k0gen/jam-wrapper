FROM --platform=linux/arm64/v8 ghcr.io/joinmarket-webui/joinmarket-webui-standalone:latest
RUN apt-get update && apt-get upgrade -y && apt-get -y install wget sudo xsel
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash - && apt-get -y install nodejs && npm install -g serve
RUN wget https://github.com/mikefarah/yq/releases/download/v4.12.2/yq_linux_arm.tar.gz -O - |\
      tar xz && mv yq_linux_arm /usr/bin/yq

WORKDIR /

ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
ADD assets/utils/check-web.sh /usr/local/bin/check-web.sh
ADD assets/utils/check-web.sh /usr/local/bin/check-api.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh
RUN chmod +x /usr/local/bin/check-web.sh
RUN chmod +x /usr/local/bin/check-api.sh

EXPOSE 80 28183 27183 8080 3000

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]