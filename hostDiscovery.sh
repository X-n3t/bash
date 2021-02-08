#!/bin/bash

if [ $1 ]; then
	for i in $(seq 1 254); do
		host=$(echo $1 | awk '{print $1"."$2"."$3"."}' FS=".")
		timeout 1 bash -c "ping -c 1 $host$i" > /dev/null && echo "HOST $host$i ACTIVE" &
	done
else
	echo -e "\n[*] Uso ./hostDiscovery.sh x.x.x.x"
	exit 1
fi
