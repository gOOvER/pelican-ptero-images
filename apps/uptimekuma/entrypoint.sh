#!/bin/ash
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
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "127.0.0.1")
export INTERNAL_IP

# system informations
printf "%b\n" "${BLUE}---------------------------------------------------------------------${NC}"
printf "%b\n" "${RED}Uptime Kuma Image by gOOvER - https://dsc.gg/goover${NC}"
printf "%b\n" "${BLUE}---------------------------------------------------------------------${NC}"
printf "%b\n" "${YELLOW}Running on Alpine: ${RED} $(cat /etc/alpine-release)${NC}"
printf "%b\n" "${YELLOW}Current timezone: ${RED} ${TZ} ${NC}"
printf "%b\n" "${YELLOW}NodeJS Version: ${RED} $(node -v) ${NC}"
printf "%b\n" "${YELLOW}Cloudflared Version: ${RED} $(/usr/bin/cloudflared --version) ${NC}"
printf "%b\n" "${BLUE}---------------------------------------------------------------------${NC}"

export PATH=$PATH:/root/.local/bin

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
if command -v bash >/dev/null 2>&1; then
    exec bash -c "${MODIFIED_STARTUP}"
else
    exec sh -c "${MODIFIED_STARTUP}"
fi

