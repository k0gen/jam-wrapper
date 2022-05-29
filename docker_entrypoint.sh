#!/bin/bash

set -ea 

_term() { 
  echo "Caught SIGTERM signal!" 
  kill -TERM "$jm_process" 2>/dev/null
}

# Setting env-vars
echo "Setting environment variables..."
export APP_USER="joinmarket"
export APP_PASSWORD="joinmarket"
export TOR_HOST=$(yq e '.tor-address' /root/start9/config.yaml)
export LAN_HOST=$(yq e '.lan-address' /root/start9/config.yaml)
export RPC_TYPE=$(yq e '.bitcoind.type' /root/start9/config.yaml)
export RPC_USER=$(yq e '.bitcoind.user' /root/start9/config.yaml)
export RPC_PASS=$(yq e '.bitcoind.password' /root/start9/config.yaml)
export RPC_PORT=8332
export JM_WALLET=$(yq e '.jm-wallet' /root/start9/config.yaml)
export JM_HOST="joinmarket-webui.embassy"
if [ "$RPC_TYPE" = "internal-proxy" ]; then
	export RPC_HOST="btc-rpc-proxy.embassy"
	echo "Running on Bitcoin Proxy..."
else
	export RPC_HOST="bitcoind.embassy"
	echo "Running on Bitcoin Core..."
fi

# Configuring JoinMarket
echo "Configuring JoinMarket..."
if ! [ -f "/root/.joinmarket/joinmarket.cfg" ]; then
	echo "Creating JM configuration file..."
	cd /src/scripts/
	python jmwalletd.py
fi
mkdir -p ~/.joinmarket/ssl/
printf "JM\nYaad\nBabylon\nStart9\nServices\nDread\nNunya\n\n" | openssl req -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out ~/.joinmarket/ssl/cert.pem -keyout ~/.joinmarket/ssl/key.pem
sed -i "s/rpc_host =.*/rpc_host = $RPC_HOST/" /root/.joinmarket/joinmarket.cfg
sed -i "s/rpc_password =.*/rpc_password = $RPC_PASS/" /root/.joinmarket/joinmarket.cfg
sed -i "s/rpc_port =.*/rpc_port = $RPC_PORT/" /root/.joinmarket/joinmarket.cfg
sed -i "s/rpc_wallet_file =.*/rpc_wallet_file = $JM_WALLET/" /root/.joinmarket/joinmarket.cfg
sed -i "s/localhost/$JM_HOST/" /root/.joinmarket/joinmarket.cfg

# Create Core Wallet
curl -sS --user $RPC_USER:$RPC_PASS --data-binary '{"jsonrpc": "1.0", "id": "wallet-gen", "method": "createwallet", "params": {"wallet_name":"'$JM_WALLET'","descriptors":false}}' -H 'content-type: text/plain;' http://$RPC_HOST:8332/

# Starting JoinMarket API
echo "Starting JoinMarket API..."
cd /src/scripts/
printf "\n" | python jmwalletd.py &

# Creating JAM wallet
echo "Creating JAM Wallet..."
#printf "n\npassword123\npassword123\n\nn\n" | python wallet-tool.py generate

# Starting JAM
echo "Starting JAM..."
# serve --cors --symlinks 

# Starting command line
while true;
do
sleep 2000;
done

trap _term SIGTERM
wait -n $jm_process