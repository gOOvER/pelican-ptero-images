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

# Information output
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${RED}RustServerRedirect Image by gOOvER - https://dsc.gg/goover${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${YELLOW}Linux Distribution: ${RED} $(. /etc/os-release ; echo $PRETTY_NAME)${NC}"
echo -e "${YELLOW}Current timezone: ${RED} $(cat /etc/timezone)${NC}"
echo -e "${YELLOW}DotNet Version: ${RED} $(dotnet --version) ${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"

# Switch to the container's working directory
cd /home/container || exit 1

# writing dotnet infos to file
#dotnetinfo=$(dotnet --info)
#echo $dotnetinfo >| dotnet_info.txt

echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${GREEN}Starting Server.... Please wait...${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"

FILE=$HOME/RustServerRedirect

if [ -f "$FILE" ]; then
  echo -e "${BLUE}-------------------------------------------------${NC}"
  echo -e "${GREEN}RustServerRedirect found.${NC}"
  echo -e "${BLUE}-------------------------------------------------${NC}"
  chmod +x $FILE
else
  echo -e "${BLUE}-------------------------------------------------${NC}"
  echo -e "${RED}RustServerRedirect not found. exiting...${NC}"
  echo -e "${BLUE}-------------------------------------------------${NC}"
  exit 1
fi

# Setup NSS Wrapper for use ($NSS_WRAPPER_PASSWD and $NSS_WRAPPER_GROUP have been set by the Dockerfile)
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /passwd.template > ${NSS_WRAPPER_PASSWD}
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libnss_wrapper.so

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}

