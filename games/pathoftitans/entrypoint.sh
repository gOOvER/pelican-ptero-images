#!/bin/bash
#System variables
clear
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Switch to the container's working directory
cd /home/container || exit 1

# Wait for the container to fully initialize
sleep 1

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# system informations
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${RED}Path of Titans Image by gOOvER - https://dsc.gg/goover${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${YELLOW}Running on Ubuntu ${RED} $(cat /etc/debian_version)${NC}"
echo -e "${YELLOW}Current timezone: ${RED} $(cat /etc/timezone)${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"

chmod +x /PathOfTitans/Binaries/Linux/PathOfTitansServer-Linux-Shipping

## check for serverupdates
if [ -z "${AUTO_UPDATE:-}" ] || [ "${AUTO_UPDATE:-}" = "1" ]; then
    cd /home/container
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}checkig for Server update. please wait...${NC}"
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    export DOTNET_BUNDLE_EXTRACT_BASE_DIR=./temp/
    ./AlderonGamesCmd --game path-of-titans --server true --beta-branch $BETA_BRANCH --install-dir ./ --username $AG_SERVER_EMAIL --password $AG_SERVER_PASS
    chmod +x /PathOfTitans/Binaries/Linux/PathOfTitansServer-Linux-Shipping
 else
    echo -e "${BLUE}---------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Not updating game server as auto update was set to 0. Starting Server${NC}"
    echo -e "${BLUE}---------------------------------------------------------------${NC}"
fi

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}

