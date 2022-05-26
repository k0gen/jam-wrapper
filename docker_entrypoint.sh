#!/bin/bash

_term() { 
  echo "Caught SIGTERM signal!" 
  kill -TERM "$jm_process" 2>/dev/null
}

# Setting env-vars
echo "Setting environment variables..."
TOR_HOST=$(yq e '.tor-address' /root/start9/config.yaml)
LAN_HOST=$(yq e '.lan-address' /root/start9/config.yaml)
RPC_TYPE=$(yq e '.bitcoind.type' /root/start9/config.yaml)
RPC_USER=$(yq e '.bitcoind.user' /root/start9/config.yaml)
RPC_PASS=$(yq e '.bitcoind.password' /root/start9/config.yaml)
RPC_PORT=8332
if [ "$RPC_TYPE" = "internal-proxy" ]; then
	RPC_HOST="btc-rpc-proxy.embassy"
	echo "Running on Bitcoin Proxy..."
else
	RPC_HOST="bitcoind.embassy"
	echo "Running on Bitcoin Core..."
fi

# Configuring JoinMarket
echo "Configuring JoinMarket..."
sed -i "s/rpc_host = localhost.*/rpc_host = $RPC_HOST/" /root/.joinmarket/joinmarket.cfg
sed -i "s/rpc_password = password.*/rpc_password = $RPC_PASS/" /root/.joinmarket/joinmarket.cfg
sed -i "s/rpc_port =.*/rpc_port = $RPC_PORT/" /root/.joinmarket/joinmarket.cfg
sed -i "s/tor_control_host = localhost/tor_control_host = $TOR_HOST/" /root/.joinmarket/joinmarket.cfg
sed -i "/type = onion.*/a host = $TOR_HOST" /root/.joinmarket/joinmarket.cfg
sed -i "/type = onion.*/a channel = joinmarket-pit" /root/.joinmarket/joinmarket.cfg
sed -i "/type = onion.*/a port = 9051" /root/.joinmarket/joinmarket.cfg

# Starting JoinMarket API
echo "Starting JoinMarket API..."
mkdir -p ~/.joinmarket/ssl/
cd /src/scripts/
printf "JM\nYaad\nBabylon\nStart9\nServices\nDread\nNunya\n" | openssl req -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out ~/.joinmarket/ssl/cert.pem -keyout ~/.joinmarket/ssl/key.pem
printf "\n" | python jmwalletd.py & 

# Starting JAM
echo "Starting JAM..."
cd /app
serve --cors

# Starting command line
while true;
do
sleep 2000;
done

trap _term SIGTERM
wait -n $jm_process