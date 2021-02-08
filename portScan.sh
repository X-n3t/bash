#! /bin/bash

if [ $1 ]; then

	for port in $(seq 1 65535); do
	ip_address=$1
		timeout 1 bash -c "echo '' > /dev/tcp/$ip_address/$port" 2>/dev/null && echo "[*] Port OPEN: $port" &
	done
else
	echo -e "\n[+] Uso: ./portScan.sh <ip-address>"
	exit 1
fi
