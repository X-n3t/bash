#!/bin/bash


#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n\n${yellowColour}[*]${endColour}${grayColour} Saliendo...\n${endColour}"

	rm ut.t* money* total_entrada_salida.tmp entradas.tmp salidas.tmp 2>/dev/null
	tput cnorm; exit 1
}

function helpPanel(){
	echo -e "\n${redColour}[!] Uso: ./btcAnalyzer2${endColour}  (Author: S4vitar - Forked: X)${yellowColour}   *** Arch-Manjaro Version ***${endColour}"
	for i in $(seq 1 160); do echo -ne "${redColour}-"; done; echo -ne "${endColour}"
	echo -e "\n\n\t${grayColour}[-e]${endColour}${yellowColour} Modo exploración:${endColour}\n"
	echo -e "\t\t${purpleColour}unconfirmed_transactions:${endColour}${greenColour}\n\t\tListar transacciones no confirmadas${endColour}"
	echo -e "\t\t${redColour}[-n]${endColour}${yellowColour} Limitar el número de resultados${endColour}${blueColour} \n\t\t(Ejemplo: ./btcAnalyzer2 -e unconfirmed_transactions -n 10) ${turquoiseColour} *** -n 100 por defecto ***${endColour}${endColour}"
	echo -e "\n\t\t${purpleColour}inspect:${endColour}${greenColour}\n\t\tInspeccionar un hash de transacción${endColour}"
	echo -e "\t\t${redColour}[-i]${endColour}${yellowColour} Proporcionar el identificador de la transacción${blueColour} \n\t\t(Ejemplo: ./btcAnalyzer2 -e inspect -i ac03c17c75686e51db5967a65b2c2b2813b128c8fd826d56b93dc0c2bc4fdfe3)${endColour}"
	echo -e "\n\t\t${purpleColour}address:${endColour}${greenColour}\n\t\t Inspeccionar una transacción de dirección${endColour}"
	echo -e "\t\t${redColour}[-a]${endColour}${yellowColour} Proporcionar una dirección de transacción${endColour}${blueColour} \n\t\t(Ejemplo: ./btcAnalyzer2 -e address -a 37jNb7LEpk7g33GHjWvBZg9xrPh6pofMyX)${endColour}"
	echo -e "\n\t${grayColour}[-h]${endColour}${yellowColour} Mostrar este panel de ayuda${endColour}\n"

tput cnorm; exit 1
}

# Variables globales
unconfirmed_transactions="https://www.blockchain.com/es/btc/unconfirmed-transactions"
inspect_transaction_url="https://www.blockchain.com/es/btc/tx/"
inspect_address_url="https://www.blockchain.com/es/btc/address/"

function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

function unconfirmedTransactions(){

	number_output=$1
	echo '' > ut.tmp

	while [ "$(cat ut.tmp | wc -l)" == "1" ]; do
		curl -s "$unconfirmed_transactions" | html2text -nobs > ut.tmp
	done

	hashes=$(cat ut.tmp | grep "Hash" -A 1 | grep -v -E "Hash|\--|Tiempo" | head -n $number_output)

	echo "Hash_Cantidad_Bitcoin_Tiempo" > ut.table

	for hash in $hashes; do
		echo "${hash}_$(cat ut.tmp | grep -A 6 "$hash" | tail -n 1)_$(cat ut.tmp | grep -A 4 "$hash" | tail -n 1)_$(cat ut.tmp | grep -A 2 "$hash" | tail -n 1)" >> ut.table
	done

	cat ut.table | tr '_' ' ' | awk '{print $2}' | grep -v -E "Cantidad|\--" | tr -d '$' | sed 's/\..*//g' | tr -d ',' > money

	money=0; cat money | while read money_in_line; do
		let money+=$money_in_line
		echo $money > money.tmp
	done;

	echo -n "Cantidad total_" > amount.table
	echo "\$$(printf "%'.d\n" $(cat money.tmp) | tr '.' ',')" >> amount.table

	if [ "$(cat ut.table | wc -l)" != "1" ]; then
		echo -ne "${yellowColour}"
		printTable '_' "$(cat ut.table)"
		echo -ne "${endColour}"
		echo -ne "${blueColour}"
		printTable '_' "$(cat amount.table)"
		echo -ne "${endColour}"
		rm ut.* money* amount.table 2>/dev/null
		tput cnorm; exit 0
	else
		rm ut.t* 2>/dev/null
	fi

	rm ut.* money* amount.table
	tput cnorm
}

function inspectTransaction(){
	inspect_transaction_hash=$1

	echo "Entrada Total_Salida Total" > total_entrada_salida.tmp

	while [ "$(cat total_entrada_salida.tmp | wc -l)" == "1" ]; do
		curl -s "${inspect_transaction_url}${inspect_transaction_hash}" | html2text -nobs | grep -E -A 1 "Entrada total|Salida total" | grep -v -E "Entrada total|Salida total|\--" | xargs | tr ' ' '_' | sed 's/_BTC/ BTC/g' >> total_entrada_salida.tmp
	done

	echo -ne "${grayColour}"
	printTable '_' "$(cat total_entrada_salida.tmp)"
	echo -ne "${endColour}"
	rm total_entrada_salida.tmp 2>/dev/null

	echo "Dirección (Entradas)_Valor" > entradas.tmp

	while [ "$(cat entradas.tmp | wc -l)" == "1" ]; do
		curl -s "${inspect_transaction_url}${inspect_transaction_hash}"| html2text -nobs | grep -A 500 "Entradas" | grep -B 500 "Salidas" | grep "Direcci" -A 3 | grep -v -E "Direcci|Valor|\--" | awk 'NR%2{printf "%s ",$0;next;}1' | awk '{print $1 "_" $2 " " $3}' >> entradas.tmp
	done

	echo -ne "${greenColour}"
	printTable '_' "$(cat entradas.tmp)"
	echo -ne "${endColour}"
	rm entradas.tmp 2>/dev/null

	echo "Dirección (Salidas)_Valor" > salidas.tmp

	while [ "$(cat salidas.tmp | wc -l)" == "1" ]; do
		curl -s "${inspect_transaction_url}${inspect_transaction_hash}"| html2text -nobs | grep -A 500 "Salidas" | grep -B 500 "Lo has pensado" | grep "Direcci" -A 3 | grep -v -E "Direcci|Valor|\--" | awk 'NR%2{printf "%s ",$0;next;}1' | awk '{print $1 "_" $2 " " $3}' >> salidas.tmp
	done

	echo -ne "${greenColour}"
	printTable '_' "$(cat salidas.tmp)"
	echo -ne "${endColour}"
	rm salidas.tmp 2>/dev/null
	tput cnorm
}

function inspectAddress(){
	address_hash=$1
	echo "Transacciones realizadas_Cantidad total recibida (BTC)_Cantidad total enviada (BTC)_Saldo total en la cuenta (BTC)" > address.tmp
	curl -s "${inspect_address_url}${address_hash}" | html2text -nobs | grep -A 1 -E "Transacciones|Total Recibidas|Cantidad total enviada|Saldo final" | head -n -2 | grep -v -E "Transacciones|Total Recibidas|Cantidad total enviada|Saldo final" | xargs | tr ' ' '_' | sed 's/_BTC/ BTC/g' >> address.tmp

	echo -ne "${greenColour}"
	printTable '_' "$(cat address.tmp)"
	echo -ne "$endColour"
	rm address* 2>/dev/null

	bitcoin_value=$(curl -s "https://es.cointelegraph.com/bitcoin-price-index" | html2text -nobs | grep -A 1 "Last Price" | head -n 1 | awk 'NF {print $NF}' | tr -d ',' )

	curl -s "${inspect_address_url}${address_hash}" | html2text -nobs | grep "Transacciones" -A 1 | head -n -2 | grep -v -E "Transacciones|\--" > address2.tmp
	curl -s "${inspect_address_url}${address_hash}" | html2text -nobs | grep -E "Total Recibidas|Cantidad total enviada|Saldo final" -A 1 | grep -v -E "Total Recibidas|Cantidad total enviada|Saldo final|\--" > bitcoin_to_dollars

	cat bitcoin_to_dollars | while read value; do
		echo "\$$(printf "%'.d\n" $(echo "$(echo $value | awk '{print $1}')*$bitcoin_value" | bc) 2>/dev/null)" >> address2.tmp
	done

	line_null=$(cat address2.tmp | grep -n "^\$$" | awk '{print $1}' FS=":")

	if [ $line_null ]; then
		sed "${line_null}s/\$/0.00/" -i address2.tmp
	fi

	cat address2.tmp | xargs | tr ' ' '_' >> address3.tmp
	rm address2.tmp 2>/dev/null && mv address3.tmp address2.tmp
	sed '1iTransacciones realizadas_Cantidad total recibidas (USD)_Cantidad total enviada(USD)_Saldo actual en la cuenta (USD)' -i address2.tmp

	echo -ne "${grayColour}"
	printTable '_' "$(cat address2.tmp)"
	echo -ne "$endColour"
	
    rm address* bitcoin* 2>/dev/null
	tput cnorm
}

parameter_counter=0; while getopts "e:n:i:a:h:" arg; do
	case $arg in
		e) exploration_mode=$OPTARG; let parameter_counter+=1;;
		n) number_output=$OPTARG; let parameter_counter+=1;;
		i) inspect_transaction=$OPTARG; let parameter_counter+=1;;
		a) inspect_address=$OPTARG; let parameter_counter+=1;;
		h) helpPanel;;
	esac
done

tput civis

if [ $parameter_counter -eq 0 ]; then
	helpPanel

else
	if [ "$(echo $exploration_mode)" == "unconfirmed_transactions" ]; then
		if [ ! "$number_output" ]; then
			number_output=100
			unconfirmedTransactions $number_output
		else
			unconfirmedTransactions $number_output
		fi
	elif [ "$(echo $exploration_mode)" == "inspect" ]; then
		inspectTransaction $inspect_transaction
	elif [ "$(echo $exploration_mode)" == "address" ]; then
		inspectAddress $inspect_address
	fi
fi
