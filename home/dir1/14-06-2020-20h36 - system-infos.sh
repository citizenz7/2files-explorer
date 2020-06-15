#!/usr/bin/env bash
#
###############################################################################
# Some infos about system...
# Citizenz - 27/12/2019
# GITHUB: https://github.com/citizenz7
# BLOG: https://www.citizenz.info
###############################################################################
#
#Bash Colour
red='\e[0;31m'
green='\e[0;32m'
yellow='\e[0;33m'
bold='\e[1m'
underlined='\e[4m'
NC='\e[0m' #No Color
COLUMNS=$(tput cols)

#Global variables
TOTAL_PHYSICAL_MEM=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
TOTAL_SWAP=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
CFG_HOSTNAME_FQDN=$(hostname -f); # hostname -A
IP_ADDRESS=( $(hostname -I) );
RE='^2([0-4][0-9]|5[0-5])|1?[0-9][0-9]{1,2}(\.(2([0-4][0-9]|5[0-5])|1?[0-9]{1,2})){3}$'
IPv4_ADDRESS=( $(for i in ${IP_ADDRESS[*]}; do [[ "$i" =~ $RE ]] && echo "$i"; done) )
RE='^[[:xdigit:]]{1,4}(:[[:xdigit:]]{1,4}){7}$'
IPv6_ADDRESS=( $(for i in ${IP_ADDRESS[*]}; do [[ "$i" =~ $RE ]] && echo "$i"; done) )
WT_BACKTITLE="ISPConfig 3 System Installer from Temporini Matteo"

#Saving current directory
APWD=$(pwd);

# CPU
CPU=( $(sed -n 's/^model name[[:space:]]*: *//p' /proc/cpuinfo | uniq) )
if [ -n "$CPU" ]; then
	echo -e "Processor (CPU):\t\t\t${CPU[*]}"
fi
CPU_CORES=$(nproc --all)
echo -e "CPU Cores:\t\t\t\t$CPU_CORES"

ARCHITECTURE=$(getconf LONG_BIT)
echo -e "Architecture:\t\t\t\t$HOSTTYPE ($ARCHITECTURE-bit)"
echo -e "Total memory (RAM):\t\t\t$(printf "%'d" $((TOTAL_PHYSICAL_MEM / 1024))) MiB ($(printf "%'d" $((((TOTAL_PHYSICAL_MEM * 1024) / 1000) / 1000))) MB)"
echo -e "Total swap space:\t\t\t$(printf "%'d" $((TOTAL_SWAP / 1024))) MiB ($(printf "%'d" $((((TOTAL_SWAP * 1024) / 1000) / 1000))) MB)"
if command -v lspci >/dev/null; then
	GPU=( $(lspci 2>/dev/null | grep -i 'vga\|3d\|2d' | sed -n 's/^.*: //p') )
fi
if [ -n "$GPU" ]; then
	echo -e "Graphics Processor (GPU):\t\t${GPU[*]}"
fi
echo -e "Computer name:\t\t\t\t$HOSTNAME"
echo -e "Hostname:\t\t\t\t$CFG_HOSTNAME_FQDN"
if [ -n "$IPv4_ADDRESS" ]; then
	echo -e "IPv4 address$([[ ${#IPv4_ADDRESS[*]} -gt 1 ]] && echo "es"):\t\t\t\t${IPv4_ADDRESS[*]}"
fi
if [ -n "$IPv6_ADDRESS" ]; then
	echo -e "IPv6 address$([[ ${#IPv6_ADDRESS[*]} -gt 1 ]] && echo "es"):\t\t\t\t${IPv6_ADDRESS[*]}"
fi
TIME_ZONE=$(timedatectl 2>/dev/null | grep -i 'time zone\|timezone' | sed -n 's/^.*: //p')
echo -e "Time zone:\t\t\t\t$TIME_ZONE\n"
