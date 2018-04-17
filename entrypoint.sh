#!/bin/sh

/bin/chmod 700 /data
/bin/chown -R litecoin /data

PARAMS="-printtoconsole \
	-datadir=/data \
	-server \
	-rpcbind=0.0.0.0 \
	-rpcuser=$RPCUSER \
	-rpcpassword=$RPCPASS \
	-rpcallowip=$RPCALLOWIP \
	$@"
echo "exec command: litecoind $PARAMS"

exec sudo -H -u litecoin /usr/local/bin/litecoind $PARAMS
