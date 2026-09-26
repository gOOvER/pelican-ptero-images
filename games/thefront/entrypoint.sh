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
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "127.0.0.1")
export INTERNAL_IP

# Information output
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${RED}The Front Image by gOOvER - https://dsc.gg/goover${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${YELLOW}Linux Distribution: ${RED} $(. /etc/os-release ; echo $PRETTY_NAME)${NC}"
echo -e "${YELLOW}Current timezone: ${RED} $([ -f /etc/timezone ] && cat /etc/timezone || echo "${TZ:-UTC}")${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"

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
if [ -z "${AUTO_UPDATE:-}" ] || [ "${AUTO_UPDATE:-}" = "1" ]; then
    # Update Source Server
    if [ -n "${STEAM_APPID:-}" ]; then
        if [ "${STEAM_USER:-}" = "anonymous" ]; then
            ./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${STEAM_USER:-} ${STEAM_PASS:-} ${STEAM_AUTH:-} $( [[ "${WINDOWS_INSTALL:-}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) +app_update ${STEAM_APPID:-} $( [[ -z ${STEAM_BETAID:-} ]] || printf "%s" "-beta ${STEAM_BETAID}" ) $( [[ -z ${STEAM_BETAPASS:-} ]] || printf "%s" "-betapassword ${STEAM_BETAPASS}" ) $( [[ -z ${HLDS_GAME:-} ]] || printf "%s" "+app_set_config 90 mod ${HLDS_GAME}" ) $( [[ -z ${VALIDATE:-} ]] || printf "%s" "validate" ) +quit
        else
            numactl --physcpubind=+0 ./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${STEAM_USER:-} ${STEAM_PASS:-} ${STEAM_AUTH:-} $( [[ "${WINDOWS_INSTALL:-}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) +app_update ${STEAM_APPID:-} $( [[ -z ${STEAM_BETAID:-} ]] || printf "%s" "-beta ${STEAM_BETAID}" ) $( [[ -z ${STEAM_BETAPASS:-} ]] || printf "%s" "-betapassword ${STEAM_BETAPASS}" ) $( [[ -z ${HLDS_GAME:-} ]] || printf "%s" "+app_set_config 90 mod ${HLDS_GAME}" ) $( [[ -z ${VALIDATE:-} ]] || printf "%s" "validate" ) +quit
        fi
    else
        echo -e "${BLUE}---------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}No appid set. Starting Server${NC}"
        echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    fi

else
    echo -e "${BLUE}---------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Not updating game server as auto update was set to 0. Starting Server${NC}"
    echo -e "${BLUE}---------------------------------------------------------------${NC}"
fi

# Replace Startup Variables
MODIFIED_STARTUP=$(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
if command -v bash >/dev/null 2>&1; then
    exec bash -c "${MODIFIED_STARTUP}"
else
    exec sh -c "${MODIFIED_STARTUP}"
fi

