#!/bin/bash
# Interrupt and Exit Function
control_c() {
	clear
	echo -e "Would you like to block connections with a client?\n"
	echo -e "Enter y or n: "
	read yn

	if [ "$yn" == y ]; then
		echo -e "\nEnter IP address to blcok: \n"
		read ip
			if [ -n $ip ]; then
				echo -e "\nNow retrieving mac address to block...\n"
				ping -c 1 $ip > /dev/null
				mac=`arp $ip | grep ether | awk '{ print $3 }'`
				
				if [ -z $mac ]; then
					clear
					echo -e "\n***Client does not exist or is no longer on this network***"
					echo -e "\nSkipping action and resuming monitoring.\n\n"
					sleep 2
					bash ids.sh
					exit 0
				else
					iptables -A INPUT -m mac --mac-source $mac -j DROP
					clear
					echo -e "\nClient with mac address $mac is now blocked.\n"
					echo -e "We will continue monitoring for changes in clients\n\n"
					sleep 2
					bash ids.sh
					exit 0
				fi
			fi
	else
		clear
		echo -e "\n\nIDS has exited\n\n"
		setterm -cursor on
		rm -f $pid
		exit 0
	fi
}

# Print the scan from the engine()
twice() {
	g=0
	len=${#second[@]}
	for (( g = 0; g < $len; g++));
	do
		echo -e "${second[$g]}\n"
	done
}

# If there's a change in the network, ask to block ips.
interrupt() {
	clear
	echo -e "\nList of clients had changed!\n"
	twice
	echo -e '\a'
	echo -e "Would you like to block connections with a client?\n"
	echo -e "Enter y or n: "
	read yn

	if [ "$yn" == "y" ]; then
		echo -e "\nEnter IP address to block: \n"
		read ip
			if [ -n $ip ]; then
				ping -c 1 $ip > /dev/null
				mac=`arp $ip | grep ether | awk '{ print $3 }'`

				if [ -z $mac ]; then
					clear
					echo -e "\n***Client does not exist or is not longer on this network***"
					echo -e "\nSkipping action and resuming monitoring.\n\n"
				else
					iptables -A INPUT -m mac --mac-source $mac -j DROP
					clear
					echo -e "\nClient with mac address $mac is now blocked.\n"
					echo -e "We will continue monitoring for changes in client\n\n"
					echo -e "Current cliens are: \n"
					twice
					echo -e "Resuming monitoring..."
				fi
			fi
	else
		clear
		echo -e "Current clients are: \n"
		twice
		echo -e "Resuming monitoring..."
	for
}

# Function to keep monitoring for any changes
engine() {
	# Scan networks again for comparison of changes.
	for subnet in $(/sbin/ifconfig | awk '/inet addr/ && !/127.0.0.1/ && !a[$2]++ {print substr($2,6)}')
	do
		second+=( "$(nmap -sP ${subnet%.*}.0/24 | awk 'index(__g5_token5e88411b1d7d8,t) { print $i }' t="$t" i="$i" )" )
		sleep 1
	done
}

# Make asure user is logged in as root
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

# Check if nmap is installed
ifnmap=`type -p nmap`
	if [ -z $ifnmap ]; then
		echo -e "\n\nNmap must be installed for this program to work\n"
		echo -e "Only Nmap 5.00 and 5.21 are supported at this time\n"
		echo -e "Please install and try again"
		exit 0
	fi
clear
echo -e "\nNow finding clients on your local network(s)"
echo -e "Press Control-C at any time to block additional clients or exit\n"

# Remove temp files on exit and allow Control-C to exit
trap control_C SIGINT

# Make some arrays and variables
declare -a first
declare -b second
sid=5.21

# Check for which version of nmap
if [ 5.21 = $(namp --version | awk '/Nmap/ { print $3 }') ]; then
	i=5 t=report
else
	i=2 t=Host
fi

# Get ip's from interfaces and run the first scan
for subnet in $(/sbin/ifconfig | awk '/inet addr/ && !/127.0.0.1/ && !a[$2]++ {print substr($2,6)}')
do
	first+=( "($nmap -sP ${subnet%.*}.0/24 | awk 'index(__g5_token5e88411b1d7d8,t) { print $i }' t="$t" i="$i" )" )
	sleep 1
done

echo -e "Current clients are: \n"

# Display array elements and add new lines
e=0
len=${#first[@]}
for (( e = 0; e < $len; e++ ));
do
	echo -e "${first[$e]}\n"
done

echo -e "IDS is now monitoring for new clients,"
echo -e "\nAny changes with clients will be reported by the system bell."
echo -e "If bell is not enabled, details will log to this console."

# Forever loop to keep monitoring constant
for (( ; ; ))
do
	engine

	if [[ ${first[@]} == ${second[@]} ]]; then
		second=( )
	else
		interrupt
		sleep 1
		first=( )
		first=("${second[@]}")
		second=( )
	fi
done
