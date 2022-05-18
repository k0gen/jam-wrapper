FROM --platform=linux/arm64/v8 ghcr.io/joinmarket-webui/joinmarket-webui-standalone:latest
RUN apt-get update && apt-get upgrade -y && apt-get -y install curl bash wget sudo
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
RUN apt-get -y install nodejs
RUN wget https://github.com/mikefarah/yq/releases/download/v4.12.2/yq_linux_arm.tar.gz -O - |\
      tar xz && mv yq_linux_arm /usr/bin/yq

COPY joinmarket-webui/ /joinmarket-webui

# WORKDIR /joinmarket-clientserver/
# RUN ./install.sh --docker-install --without-qt
# WORKDIR /joinmarket-clientserver/scripts/
WORKDIR /src/scripts/
RUN mkdir -p ~/.joinmarket/ssl/
RUN printf "JM\nYaad\nBabylon\nStart9\nServices\nDread\nNunya\n" | openssl req -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out ~/.joinmarket/ssl/cert.pem -keyout ~/.joinmarket/ssl/key.pem
RUN printf "\n" | python jmwalletd.py & 

WORKDIR /joinmarket-webui/
RUN npm install --no-fund --no-audit && npm install -g serve && npm run build

ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh
ADD assets/utils/check-web.sh /usr/local/bin/check-web.sh
RUN chmod +x /usr/local/bin/check-web.sh

EXPOSE 80 28183 27183 8080

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]