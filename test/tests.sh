#!/bin/sh

RPCTESTUSER="user"
RPCTESTPASS="pass"

set -ex
sudo docker build -t litecoind:testing .
sudo GOSS_SLEEP=10 dgoss run -p 9332:9332 -p 9333:9333 -e RPCALLOWIP="0.0.0.0/0" -e RPCUSER="$RPCTESTUSER" -e RPCPASS="$RPCTESTPASS" litecoind:testing

sed -i "s/RPCUSER:.*/RPCUSER: \"$RPCTESTUSER\"/" docker-compose.yml
sed -i "s/RPCPASS:.*/RPCPASS: \"$RPCTESTPASS\"/" docker-compose.yml
sed -i 's/RPCALLOWIP:.*/RPCALLOWIP: "0.0.0.0\/0"/' docker-compose.yml
sudo docker-compose build
sudo docker-compose up -d
sleep 60
curl --user user:pass --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockchaininfo", "params": [] }' -H 'content-type: text/plain;' http://127.0.0.1:8332

