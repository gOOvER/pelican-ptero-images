#!/bin/bash

clear
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Wait for the container to fully initialize
sleep 1

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

echo -e "${BLUE}----------------------------------------------------------------------------------${NC}"
    echo -e "${RED}SteamCMD Proton-GE Image by gOOvER - https://dsc.gg/goover${NC}"
	echo -e "${RED}THIS IMAGE IS LICENSED UNDER AGPLv3${NC}"
    echo -e "${BLUE}----------------------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Linux Distribution: ${RED} $(. /etc/os-release ; echo $PRETTY_NAME)${NC}"
    echo -e "${YELLOW}Kernel: ${RED} $(uname -r)${NC}"
    echo -e "${YELLOW}Current timezone: ${RED} $(cat /etc/timezone)${NC}"
    echo -e "${YELLOW}Proton Version: ${RED} $(cat /usr/local/bin/version)${NC}"
    echo -e "${BLUE}----------------------------------------------------------------------------------${NC}"

# Set environment for Steam Proton
if [ ! -z ${STEAM_APPID:-} ]; then
    mkdir -p /home/container/.steam/steam/steamapps/compatdata/${STEAM_APPID}
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="/home/container/.steam/steam"
    export STEAM_COMPAT_DATA_PATH="/home/container/.steam/steam/steamapps/compatdata/${STEAM_APPID}"
    export WINETRICKS="/usr/sbin/winetricks"
    export STEAM_DIR="/home/container/.steam/steam/"

else
    echo -e "${BLUE}----------------------------------------------------------------------------------${NC}"
    echo -e "${RED}WARNING!!! Proton needs variable STEAM_APPID, else it will not work. Please add it${NC}"
    echo -e "${RED}Server stops now${NC}"
    echo -e "${BLUE}----------------------------------------------------------------------------------${NC}"
    exit 0
fi

sleep 2

# Switch to the container's working directory
cd /home/container || exit 1

## just in case someone removed the defaults.
if [ "${STEAM_USER:-}" == "" ]; then
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Steam user is not set.\n ${NC}"
    echo -e "${YELLOW}Using anonymous user.\n ${NC}"
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}user set to ${STEAM_USER} ${NC}"
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
fi

## if auto_update is not set or to 1 update
if [ -z ${AUTO_UPDATE} ] || [ "${AUTO_UPDATE}" == "1" ]; then
	if [ -f /home/container/DepotDownloader ]; then
		./DepotDownloader -dir /home/container -username ${STEAM_USER} -password ${STEAM_PASS} -remember-password $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '-os windows' ) -app ${STEAM_APPID} $( [[ -z ${STEAM_BETAID} ]] || printf %s "-beta ${STEAM_BETAID}" ) $( [[ -z ${STEAM_BETAPASS} ]] || printf %s "-betapassword ${STEAM_BETAPASS}" )
		mkdir -p /home/container/.steam/sdk64
		./DepotDownloader -dir /home/container/.steam/sdk64 $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '-os windows' ) -app 1007
		chmod +x $HOME/*

	else
	   	./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) $( [[ "${STEAM_SDK}" == "1" ]] && printf %s '+app_update 1007' ) +app_update ${STEAM_APPID} $( [[ -z ${STEAM_BETAID} ]] || printf %s "-beta ${STEAM_BETAID}" ) $( [[ -z ${STEAM_BETAPASS} ]] || printf %s "-betapassword ${STEAM_BETAPASS}" ) ${INSTALL_FLAGS} $( [[ "${VALIDATE}" == "1" ]] && printf %s 'validate' ) +quit
	fi
else
    echo -e "${BLUE}---------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Not updating game server as auto update was set to 0. Starting Server${NC}"
    echo -e "${BLUE}---------------------------------------------------------------${NC}"
fi

echo -e "${BLUE}----------------------------------------------------------------------------------${NC}"
echo -e "${GREEN}Starting Server.... Please wait...${NC}"
echo -e "${BLUE}----------------------------------------------------------------------------------${NC}"

# List and install other packages
#for trick in $PROTONTRICKS_RUN; do
#        echo -e "${BLUE}---------------------------------------------------------------------${NC}"
#        echo -e "${YELLOW}Installing: ${NC} ${GREEN} $trick ${NC}"
#        echo -e "${BLUE}---------------------------------------------------------------------${NC}"
#        protontricks ${STEAM_APPID} $trick
#done

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}
