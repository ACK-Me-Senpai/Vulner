#!/bin/bash

# //////
# Colors
# //////

BLD='\033[1m' # Bold
GRN='\033[92m' # Green
RED='\033[91m' # Red
YLW='\033[1;93m' # Yellow
NEU='\033[0m' # Neutral

GS="${GRN}[*]${NEU}"
RS="${RED}[*]${NEU}"
YS="${YLW}[*]${NEU}"
GP="${GRN}[+]${NEU}"
RM="${RED}[-]${NEU}"
GE="${GRN}[!]${NEU}" # Green Exclamation mark | extra info on success
YE="${YLW}[!]${NEU}" # Yellow Exclamation mark | Instruction
GH="${GRN}[#]${NEU}" # Green Hash | extra info
YH="${YLW}[#]${NEU}" # Yellow Hash | extra info
RH="${RED}[#]${NEU}" # Red Hash | extra info
DONE="\033[102;30mDONE\033[0m" # DONE message

# ///////////
# Global Vars
# ///////////

lan_list=()
target_interface=()
target_ips=()
nmap_res=""

# /////////
# Functions
# /////////

sudo_check() {
	if [ $(id -u) -ne 0 ]; then
		echo -e "This program requires root permissions to run.\n Aborting!"
		exit
	fi
}

# Check whether or not the tools needed are installed.
tool_check() {
	echo "placeholder"
	req_tools=(nmap arp-scan hydra medusa metasploit-framework) # msfconsole) # msfconsole is part of the metasploit-framework
	missing_tools=()
	missing=false
	for tool in ${req_tools[@]}; do
		if ! [ -z "$(dpkg --list | grep $tool)" ]; then
			echo -e "	${GS} ${BLD}$tool${NEU} is installed!"
		else
			missing_tools+=($tool)
			missing=true
		fi
	done
	if $missing; then
		echo -e "\n${YS} The following tools are not installed:"
		for i in ${missing_tools[@]}; do
			echo -e "	${RM} $tool"
		done
		echo -e "\n${YS} Proceeding to install them now.\n"
		tool_install
	else
		echo -e "\n${GS} All tools are installed!"
	fi
}

# In case some of the tools are not installed, install them now.
tool_install() {
	echo "placeholder"
	# TO-DO: On the test kali machine, uninstall metasploit-framework and see how to reinstall it...
}

# Now we get to the creative stuff!

# This function goes through all the interfaces from the ifconfig command and saves their name, their network addresses and their subnet mask inside the global $lan_list array for future uses.
LAN_id() {
	D2B=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1})
	for interface in $(ifconfig | cut -d " " -f1 | grep : | sed 's/://g'); do
		subnet=()
		msk=0
		for octet in {1..4}; do
			subnet+=($(echo $(ifconfig | grep -A1 "^$interface" | grep -i "inet" | awk '{print $4}') | cut -d "." -f$octet))
		done
		for i in ${subnet[@]}; do
			val=$(echo ${D2B[$i]} | sed 's/0//g' | tr -d " \t\n\r" | wc -m)
			msk=$(( $msk + $val ))
		done
		#lan_list+=("$(echo -e "$interface : $(ifconfig | grep -A1 "^$interface" | grep -i "inet" | awk '{print $2}')/$msk")") # Not equally spaces. Harder to divide to components.
		#lan_list+=("$(echo -e "$interface $(ifconfig | grep -A1 "^$interface" | grep -i "inet" | awk '{print $2}') $msk")") # Equal spaces. easier to divide to components.
		lan_list+=("$(echo -e "$interface $(netmask -r $(ifconfig | grep -A1 "^$interface" | grep -i "inet" | awk '{print $2}')/$msk | cut -d "-" -f1 | tr -d " \\t\\r\\n") $msk")") # Equal spaces. easier to divide to components.
	done
	#echo -e "Available Networks:\n"
	#for network in "${lan_list[@]}"; do # Make sure to double-quote ${lan_list[@]} !!!
	#	echo -e "$network" | awk '{print $1" : "$2"/"$3}'
	#done
	#echo -e "${lan_list[0]}"
	#echo -e "${lan_list[@]}"
}

# This function (as the name implies) is used to discover hosts.
host_dis() {
	if [ "$1" == arp ]; then
		#netmask -r $(echo -e "${lan_list[0]}" | awk '{print $2}')/$(echo -e "${lan_list[0]}" | awk '{print $3}') | cut -d "-" -f1 | tr -d " \\t\\r\\n"
		echo -e "${YS} Attempting to discover all hosts in the LAN via ${BLD}arp-scan${NEU}"
		# Don't ask how I wrote the part below. The way I write code is that I overdose on adderal, I lose my consciousness, and when I wake up the code has been written...
		# I run arp-scan, and in order to avoid an error message that cannot be removed with grep, I used netmask to get the network address...
		#
		# arp-scan will NOT work on tun interfaces, since tunneling is not forwarded over layer 3. Need to think of a possible work-around...
		while read -r line; do
			target_ips+=($line)
		done <<< $(arp-scan -I ${target_interface[0]} --srcaddr=DE:AD:BE:EF:CA:FE ${target_interface[1]}/${target_interface[2]} | grep -E '[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}' | grep -vw "MAC" | awk '{print $1}')
	elif [ "$1" == nmap ]; then
		echo -e "${YS} Attempting to discover all hosts in the \"LAN\" via ${BLD}nmap${NEU}"
		des=""
		echo -e "${YH} Attention: by default Windows machines cannot be discovered via ping scan. Attempting to find them will take longer."
		until ! [ -z "$des" ]; do
			read -p $'\e[1;40;93mINPUT\e[0m Do you wish to attempt to scan for Windows machines as well? [y/N] ' opt
			if [[ $opt == y ]] || [[ $opt == Y ]]; then
				des=true
			elif [[ $opt == "" ]] || [ $opt == n ] || [ $opt == N ]; then
				des=false
			else
				printf "\n\e[1A$(tput el)"
			fi
		done
		if $des; then
			echo -e "running nmap with -Pn"
			#sleep 5
			nmap_res="$(nmap -sS -sV -sC ${target_interface[1]}/${target_interface[2]} -Pn)" # No ping scan, super slow
		else
			echo -e "running nmap without -Pn"
			#sleep 5
			nmap_res="$(nmap -sS  ${target_interface[1]}/${target_interface[2]} -sn)" # Only ping scan (only find targets
		fi
	else
		echo -e "${YH} To the person who wrote this code: You're an idiot. You either forgot to set an arg to this func, or used / misstyped the arg. KYS, ${BLD}NOW!${NEU}"
	fi
	echo -e "${GS} Nmap Results ${BLD}[DEBUG]${NEU}"
	echo -e "$nmap_res"

}

port_dis() {
	echo -e "osu!"
	#nmap_res3=()
	echo -e "${YS} Scanning all discovered host in network ($(echo -e "${#target_ips[@]}" hosts)) for 1000 most common ports..."
	nmap_res1="$(nmap -sS -v $(echo -e "${target_ips[@]}") 2> /dev/null | grep -i "Discovered open port" | awk '{print $NF","$4}' | sed 's/\/tcp//g')"
	#echo -e "$nmap_res1"
	for i in $(echo -e "$nmap_res1" | awk -F , '{print $1}' | sort | uniq); do
		echo -e "\nLooping through $i"
		port_lst=""
		for p in $(echo -e "$nmap_res1" | grep -w "$i" | awk -F , '{print $2}'); do
			port_lst="$(echo -e "${port_lst}${p},")"
		done
		port_lst="$(echo -e "$port_lst" | sed 's/\(.*\),/\1 /')"
		#echo -e "$port_lst"
		nmap_res2="$(nmap -sS -sV $i -p $port_lst | grep -iE '[0-9]{1,5}/tcp')"
		while read -r line; do
			#nmap_res3+="$(echo -e "$i,$(echo -e "$line" | awk '{print $1","$2","$3}'),$(echo -e "$line" | tr -s ' ' |  cut -d ' ' -f4-)\n")"
			echo -e "$i,$(echo -e "$line" | awk '{print $1","$2","$3}'),\"$(echo -e "$line" | tr -s ' ' |  cut -d ' ' -f4-)\"" >> temp.txt
		done <<< $nmap_res2
		#echo -e "\n\n"
	done
	nmap_res3=$(cat temp.txt)
	rm temp.txt
	#echo -e "\nTEST1:\n$nmap_res3\n\nTEST2:\n"
	#for killme in ${nmap_res3[@]}; do # Has issues... let's avoid it...
	#	echo -e "$killme"
	#done
	echo -e "${GS} Completed nmap scans!\n"
	for ip in $(echo -e "$nmap_res3" | awk -F , '{print $1}' | sort | uniq); do
		echo -e "${GP} The host $ip has $(echo -e "$nmap_res3" | grep -iw "$ip" | wc -l) ports open."
	#	for port in $(echo -e "$nmap_res3" | grep -iw "$ip"); do # because it's a for-loop, it doesn't go through every line, it goes through every WORD!
		while read -r line; do
			#echo -e "$line"
			echo -e "	$(echo -e "$line" | awk -F , '{print $2" "$3" "$4" "$5}')"
		done <<< $(echo -e "$nmap_res3" | grep -iw "$ip")
	done
	nmap_res=$nmap_res3
}

# All-encompusing function for enumerating hosts on the network, including attack surface selection, host discovery and port scanning.
Enum_phase() {
	echo -e "\n${YS} Beginning enumeration phase.\n"
	LAN_id
	echo -e "${YH} The following network interfaces has been identified:"
	fmt="	${GRN}%s.${NEU} ${BLD}%-5s${NEU} : %14s/%s\n"
	for network in "${!lan_list[@]}"; do
		printf "$fmt" "$(echo -e "$network")" "$(echo -e "${lan_list[$network]}" | awk '{print $1}')" "$(echo -e "${lan_list[$network]}" | awk '{print $2}')" "$(echo -e "${lan_list[$network]}" | awk '{print $3}')"
	done
	numeral='^[0-9]+$'
	err_msg=""
	echo -e ""
	# using an until-loop because break refused to break my while-loop.
	# Don't fuck with me bash! If I can replace "while", I can replace all of you!
	until ! [ -z "$target_interface" ]; do
		echo -e "$err_msg"
		read -p $'\e[1;40;93mINPUT\e[0m Please select an interface to us (input number, name or IP (no mask)): ' opt
		if [[ "$opt" =~ ^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}0*(1?[0-9]{1,2}|2([‌​0-4][0-9]|5[0-5]))$ ]]; then
			err_msg="IP detected"
			for i in "${lan_list[@]}"; do
				if ! [ -z "$(echo -e "$i" | grep -w "$opt")" ]; then
					err_msg="Valid IP address"
					target_interface+=($i)
					break
				else
					err_msg="Invalid IP address"
				fi
			done
			printf "\e[2A$(tput ed)"
			#echo -e "IP detected"
		elif [[ "$opt" =~ ^[0-9]+$ ]]; then
			err_msg="Number detected"
			if ! [ -z "${lan_list[$opt]}" ]; then
				err_msg="Valid option number"
				target_interface+=(${lan_list[$opt]})
				#break # Will exit out of the main loop, made for checking if target_interface is actually changed (fix later)
			else
				err_msg="Invalid option number"
			fi
			printf "\e[2A$(tput ed)"
		else
			err_msg="Other detected"
			for i in "${lan_list[@]}"; do
				if ! [ -z "$(echo -e "$i" | grep -iw "$opt")" ]; then
					err_msg="Valid other"
					target_interface+=($i)
					break
				else
					err_msg="Invalid other"
				fi
			done
			printf "\e[2A$(tput ed)"
		fi
	done
	echo -e "${target_interface[@]}"
	# Using an if-statement with regex to determine whether the interface that was chosen can use arp-scan (interface must be connected on the 2nd layer of the OSI model)
	if [[ "${target_interface[0]}" =~ ^(eth[0-9]*)|(wlan[0-9]*)$ ]]; then
		host_dis arp
	else
		#echo -e "${YS} Cannot discover hosts via arp-scan. Host discovery will be done via nmap / masscan."
		#host_dis nmap
		echo -e "${RS} Cannot run on non-local networks.\n${RS} Aborting!"
		exit
	fi
	#echo -e "${target_ips[@]}" | sed 's/ /,/g'
	port_dis
	#echo -e "$nmap_res"
	#for version in "$(echo -e "$nmap_res" | cut -d , -f5-)"; do
	while read -r version; do
		if [[ $version == "\"\"" ]]; then
			continue
		fi
		echo -e "${BLD}$version${NEU}"
		#sleep 0.5
		searchsploit $(echo -e "$version" | sed 's/"//g') | grep -v "No Results"
		sleep 0.5
	done <<< $(echo -e "$nmap_res" | cut -d , -f5-)
}

# In this phase, we let the user choose which host does he want to attack
Pre_Exploitation_phase() {
	echo -e "Fuck you"
	u_list=""
	p_list=""
}

# ////
# Main
# ////

main() {
	sudo_check
	tool_check
	#LAN_id
	#host_dis
	Enum_phase
}

main
